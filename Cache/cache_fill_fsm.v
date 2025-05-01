module cache_fill_FSM (
    input           clk,
    input           rst_n,
    input           miss_detected,
    input   [15:0]  miss_address,
    input           memory_data_valid,
    output reg      fsm_busy,
    output reg      write_data_array,
    output reg      write_tag_array,
    output wire [15:0] memory_address,
	output wire [15:0] cache_address
    output [7:0] wrd_en;
    output stall
);
wire state, next_state;// State Idle: state = 0 Wait: 1
wire [3:0] count, next_count, inc_count, addr, next_addr, inc_addr, cnt4, nxt_cnt4, inc_cnt4;


dff state_flop(.q(state), .d(next_state), .wen(1'b1), .clk(clk), .rst(~rst_n));    

// Set next state
//go to wait when miss detected
//stay in wait until block returned 
assign next_state = ((~state & miss_detected) | (state & (count != 4'h8))) ? 1'b1 : 1'b0; 

// load chunks
adder_4bit chunk_adder(.Sum(inc_count), .A(count), .B(4'h1), .Cin(1'b0), .Cout());
assign next_count = (state) ? inc_count : 4'h0;     // we should only be counting if the we are in the WAIT state
dff count_ff[3:0](.q(count), .d(next_count), .wen(memory_data_valid & (cnt4 == 4'h3)), .clk(clk), .rst(~rst_n | (next_count == 4'h9)));

// wait for 4 cycles before loading from memory
//TODO: ensure that this is needed to load memory, inserted as a protective measure - andrew
adder_4bit cnt4_adder(.Sum(inc_cnt4), .A(cnt4), .B(4'h1), .Cin(1'b0), .Cout());
assign nxt_cnt4 = (state) ? ((cnt4 == 4'h3) ? cnt4 : inc_cnt4) : 4'h0;
dff count_4[3:0](.q(cnt4), .d(nxt_cnt4), .wen(miss_detected & ~(nxt_cnt4 == 4'h4)), .clk(clk), .rst(~rst_n | ~miss_detected));


// load from memory
adder_4bit inc_mem_adder(.Sum(inc_addr), .A(addr), .B(4'h2), .Cin(1'b0), .Cout());
assign next_addr = (state) ? inc_addr : 4'h0;
dff addr_ff[3:0](.q(addr), .d(next_addr), .wen(state), .clk(clk), .rst(~rst_n | (~state & next_state)));
addsub_16bit out_mem_adder(.Sum(memory_address), .A({{12{1'b0}},addr}), .B({miss_address[15:4],4'h0}), .sub(1'b0), .sat());

//Inc word enable used in the cache module 
wordEnable instWordEn(.b_offset(count[2:0]), .wordEn(wrd_en));
// outputs
assign fsm_busy = state;
assign stall = state | (~state & next_state);
assign write_data_array = (memory_data_valid & next_state & (cnt4 == 4'h3));
assign write_tag_array = ((count == 4'h8) & state);

endmodule