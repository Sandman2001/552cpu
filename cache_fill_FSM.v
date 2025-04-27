module cache_fill_FSM (
    input           clk,
    input           rst_n,
    input           miss_detected,
    input   [15:0]  miss_address,
    input   [15:0]  memory_data,
    input           memory_data_valid,
    output reg      fsm_busy,
    output reg      write_data_array,
    output reg      write_tag_array,
    output reg [15:0] memory_address
);

    wire  [3:0] state;
    reg   [3:0] nxt_state;

    dff state_ff[3:0] (
        .q   (state),
        .d   (nxt_state),
        .wen (1'b1),
        .clk (clk),
        .rst_n (rst_n)
    );

    always @(*) case (state)
    4'h0: begin
        nxt_state        = miss_detected ? 4'h1 : 4'h0;
        fsm_busy         = miss_detected;
        write_data_array = 1'b0;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    4'h1: begin
        nxt_state        = memory_data_valid ? 4'h2 : 4'h1;
        fsm_busy         = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    4'h2: begin
        nxt_state        = memory_data_valid ? 4'h3 : 4'h2;
        fsm_busy         = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    4'h3: begin
        nxt_state        = memory_data_valid ? 4'h4 : 4'h3;
        fsm_busy         = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    4'h4: begin
        nxt_state        = memory_data_valid ? 4'h5 : 4'h4;
        fsm_busy         = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    4'h5: begin
        nxt_state        = memory_data_valid ? 4'h6 : 4'h5;
        fsm_busy         = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    4'h6: begin
        nxt_state        = memory_data_valid ? 4'h7 : 4'h6;
        fsm_busy         = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    4'h7: begin
        nxt_state        = memory_data_valid ? 4'h8 : 4'h7;
        fsm_busy         = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    4'h8: begin
        nxt_state        = memory_data_valid ? 4'h0 : 4'h8;
        fsm_busy         = 1'b1;
        write_data_array = memory_data_valid;
        write_tag_array  = memory_data_valid;
        memory_address   = miss_address;
    end
    default: begin
        nxt_state        = 4'h0;
        fsm_busy         = 1'b0;
        write_data_array = 1'b0;
        write_tag_array  = 1'b0;
        memory_address   = miss_address;
    end
    endcase

endmodule
