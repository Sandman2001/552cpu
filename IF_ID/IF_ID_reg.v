module IF_ID_reg(inc_PC_in, PC_out, instr_in, instr_out, flush, nop, clk, rst_n);
    input [15:0] inc_PC_in, instr_in; //input values for pre-incremented PC and instruction
    input flush, nop; //nop asserted for one clock cycle when data hazard detected (set all control signals to 0) stay and same PC and instr
    //flush asserted --> set all control signals to 0 and percelatr down the pipeline(increment PC by 2)
    input clk, rst_n;
    output [15:0] PC_out, instr_out;

    wire [15:0] pc_stored, pc_dec, instr_stored;  //stored values of instr and PC from previous clock decide whether sending out stored values or all 0's depending on flush and nop
    dff PC_reg [15:0](.q(pc_stored), .d(inc_PC_in), .wen(1'b1), .clk(clk), .rst(~rst_n));  //dff for PC
    dff instr_reg [15:0](.q(instr_stored), .d(instr_in), .wen(1'b1), .clk(clk), .rst(~rst_n));  //dff for instruction
    CLA_16bit_AddSub PC_dec(.A(pc_stored), .B(16'h0002), .sub(1'b1), .Sum(pc_dec), .Error());  //decremented pc by 2 to get previous PC

    assign PC_out = (nop == 1'b1) ?(pc_dec):pc_stored;  //if nop asserted, keep PC same, else increment by 2
    assign instr_out = (nop == 1'b1 | flush == 1'b1) ? 16'h0000:instr_stored;  //if nop asserted, keep instr same, else set to 0
endmodule