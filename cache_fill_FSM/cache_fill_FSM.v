module cache_fill_FSM (
    input           clk,
    input           rst_n,
    input           miss_detected,
    input   [15:0]  miss_address,
    input           memory_data_valid,
    output reg      fsm_busy,
    output reg      write_data_array,
    output reg      write_tag_array,
    output reg [15:0] memory_address
);

    wire  [3:0] req_state;
    reg   [3:0] req_nxt_state;
    wire  [3:0] res_state;
    reg   [3:0] res_nxt_state;
    wire        req_fsm_busy;
    wire        res_fsm_busy;

    //INcrementer for mem addr 
    CLA_16bit mem_add_cntr (.A(miss_address), .B(inc), .Sum(memory_address), .Error());

    //FF for holding states for tracking number of requests to memory on chache miss
    dff req_state_ff[3:0] (
        .q   (req_state),
        .d   (req_nxt_state),
        .wen (1'b1),
        .clk (clk),
        .rst_n (rst_n)
    );
    //FF for holding states for tracking the responses from memory
    dff dff res_state_ff[3:0] (
        .q   (res_state),
        .d   (res_nxt_state),
        .wen (1'b1),
        .clk (clk),
        .rst_n (rst_n)
    );
    
    /*
        FSM for handling the read requests to memory. (Request counter)
        Incrementing mem add by 2 in each state to make sure that next request addr is correct
    */
    always @(*) case (req_state)
    4'h0: begin
        req_nxt_state        = miss_detected ? 4'h1 : 4'h0;
        req_fsm_busy         = miss_detected;
    end
    4'h1: begin
        req_nxt_state        = 4'h2;
        req_fsm_busy         = 1'b1;
        inc                  = 16'h0002;
    end
    4'h2: begin
        req_nxt_state        =  4'h3;
        req_fsm_busy         = 1'b1;
        inc                  = 16'h0004;
    end
    4'h3: begin
        req_nxt_state        = 4'h4;
        req_fsm_busy         = 1'b1;
        inc                  = 16'h0006;
    end
    4'h4: begin
        req_nxt_state        = 4'h5;
        req_fsm_busy         = 1'b1;
        inc                  = 16'h0008;
    end
    4'h5: begin
        req_nxt_state        = 4'h6;
        req_fsm_busy         = 1'b1;
        inc                  = 16'h000A;
    end
    4'h6: begin
        req_nxt_state        = 4'h7;
        req_fsm_busy         = 1'b1;
        inc                  = 16'h000C;
    end
    4'h7: begin
        req_nxt_state        = 4'h8;
        req_fsm_busy         = 1'b1;
        inc                  = 16'h000E;
    end
    4'h8: begin
        req_nxt_state        = 4'h0;
        req_fsm_busy         = 1'b1;
        inc                  = 16'h0010;
    end
    default: begin
        req_nxt_state        = 4'h0;
        req_fsm_busy         = 1'b0;
        inc                  = 16'h0000;
    end
    endcase

    /*
        FSM for tracking the responses from memory sor all requests
    */

    always @(*) case (res_state)
    4'h0: begin
        res_nxt_state = memory_data_valid? 4'h1 : 4'h0;
        res_fsm_busy = memory_data_valid;
        write_data_array = memory_data_valid;
        
    end
    4'h1: begin
        res_nxt_state = memory_data_valid? 4'h2 : 4'h1;
        res_fsm_busy = 1'b1;
        write_data_array = memory_data_valid;

    end
    4'h2: begin
        res_nxt_state = memory_data_valid? 4'h3 : 4'h2;
        res_fsm_busy = 1'b1;
        write_data_array = memory_data_valid;
    end
    4'h3: begin
        res_nxt_state = memory_data_valid? 4'h4 : 4'h3;
        res_fsm_busy = 1'b1;
        write_data_array = memory_data_valid;
    end
    4'h4: begin
        res_nxt_state = memory_data_valid? 4'h5 : 4'h4;
        res_fsm_busy = 1'b1;
        write_data_array = memory_data_valid;
    end
    4'h5: begin
        res_nxt_state = memory_data_valid? 4'h6 : 4'h5;
        res_fsm_busy = 1'b1;
        write_data_array = memory_data_valid;
    end
    4'h6: begin
        res_nxt_state = memory_data_valid? 4'h7 : 4'h6;
        res_fsm_busy = 1'b1;
        write_data_array = memory_data_valid;
    end
    4'h7: begin
        res_nxt_state = memory_data_valid? 4'h8 : 4'h7;
        res_fsm_busy = 1'b1;
        write_data_array = memory_data_valid;
    end
    4'h8: begin
        res_nxt_state = memory_data_valid? 4'h0 : 4'h8;
        res_fsm_busy = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = memory_data_valid;
    end
    default: begin
        res_nxt_state = 4'h0;
        res_fsm_busy = 1'b0;
        write_data_array = 1'b0;
        write_tag_array  = 1'b0;
    end
    endcase

    assign fsm_busy = req_fsm_busy | res_fsm_busy; //fsm is busy if either of the requesting or waiting for last response

endmodule
