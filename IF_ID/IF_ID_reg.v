module IF_ID_reg(inc_PC_in, pc_in PC_out, instr_in, instr_out, flush_in, stall_in, stall_out clk, rst_n);
    input [15:0] inc_PC_in, pc_in instr_in; //input values for pre-incremented PC and instruction
    input flush_in, stall_in; //nop asserted for one clock cycle when data hazard detected (set all control signals to 0) stay and same PC and instr
    //flush asserted --> set all control signals to 0 and percelatr down the pipeline(increment PC by 2)
    input clk, rst_n;
    output stall_out, flush_out; //output signals for stall and flush
    output [15:0] PC_out, instr_out;

    wire [15:0] pc_inc_reg, pc_curr_reg, instr_stored;  //stored values of instr and PC from previous clock decide whether sending out stored values or all 0's depending on flush and nop
    dff PC_reg_inc [15:0](.q(pc_inc_reg), .d(inc_PC_in), .wen(1'b1), .clk(clk), .rst(~rst_n));  //dff for PC
    dff PC_reg [15:0](.q(pc_curr_reg), .d(PC_in), .wen(1'b1), .clk(clk), .rst(~rst_n));  //dff for PC
    dff instr_reg [15:0](.q(instr_stored), .d(instr_in), .wen(1'b1), .clk(clk), .rst(~rst_n));  //dff for instruction
    dff PC_stall (.q(stall_out), .d(stall_in), .wen(1'b1), .clk(clk), .rst(~rst_n));  //dff for stall
    dff flush_reg (.q(flush_out), .d(flush_in), .wen(1'b1), .clk(clk), .rst(~rst_n));  //dff for flush

    assign PC_out = (stall == 1'b1) ? pc_curr_reg : pc_inc_reg;  //if stall asserted, keep PC same, else increment by 2

endmodule