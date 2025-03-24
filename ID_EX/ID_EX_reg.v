module ID_EX(in_ALU_in1, in_ALU_in2, out_ALU_in1, out_ALU_in2, in_en_Z, out_en_Z, in_en_V, out_en_V, in_en_N, out_en_N, in_ALUOp, out_ALUOp, in_MemRead, out_MemRead, in_MemWrite, out_MemWrite, in_MemToReg, out_MemToReg, in_BranchTaken, out_BranchTaken, in_BranchAddr, out_BranchAddr, in_HLT, out_HLT, in_SW_data, out_SW_data);
/*
    All signals that are directly for EX block:
    ALU_in1, ALLU_in2, en_Z, en_V, en_N, ALUOp, BranchAddr, BranchTaken
*/

/*
    All signals that are directly for MEM block:
    MemRead, MemWrite, MemToReg, SW_data
*/
input[15:0] in_ALU_in1, in_ALU_in2, in_BranchAddr, in_SW_data;
input in_en_Z, in_en_V, in_en_N, in_MemToReg, in_MemRead, in_BranchTaken, in_HLT, in_MemWrite;
input[3:0] in_ALUOp;
output[15:0] out_ALU_in1, out_ALU_in2, out_BranchAddr, out_SW_data;
output out_en_Z, out_en_V, out_en_N, out_MemToReg, out_MemRead, out_BranchTaken, out_HLT, out_MemWrite;
output[3:0] out_ALUOp;

dff ALU_in1_reg [15:0] (.q(out_ALU_in1), .d(in_ALU_in1), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff ALU_in2_reg [15:0] (.q(out_ALU_in2), .d(in_ALU_in2), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff BranchAddr_reg [15:0] (.q(out_BranchAddr), .d(in_BranchAddr), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff SW_data_reg  [15:0] (.q(out_SW_data), .d(in_SW_data), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff en_Z_reg(.q(out_en_Z), .d(in_en_Z), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff en_V_reg(.q(out_en_V), .d(in_en_V), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff en_N_reg(.q(out_en_N), .d(in_en_N), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff ALUOp_reg [3:0] (.q(out_ALUOp), .d(in_ALUOp), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff MemRead_reg(.q(out_MemRead), .d(in_MemRead), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff MemWrite_reg(.q(out_MemWrite), .d(in_MemWrite), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff MemToReg_reg(.q(out_MemToReg), .d(in_MemToReg), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff BranchTaken_reg(.q(out_BranchTaken), .d(in_BranchTaken), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff HLT_reg(.q(out_HLT), .d(in_HLT), .wen(1'b1), .clk(clk), .rst(~rst_n));
endmodule