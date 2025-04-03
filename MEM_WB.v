module MEM_WB (clk, rst_n, in_ALU_result, in_memData, in_MemToReg, in_RegWrite, in_HLT, in_DstReg, in_PCToReg, out_ALU_result, out_DstReg, out_HLT, out_MemToReg, out_RegWrite,	out_memData);

input clk;
input rst_n;

// Inputs from MEM stage
input[15:0] in_ALU_result;		// ALU result 
input[15:0] in_memData;			// data read from mem for load
input in_MemToReg;				// mem data and alu result mux
input in_RegWrite;				// write enable for WB
input in_HLT;					// halt
input[3:0] in_DstReg;			// dest register for WB
input in_PCToReg;
// Outputs to WB stage
output[15:0] out_ALU_result;	// alu output
output[15:0] out_memData;		// mem data for load instr
output out_MemToReg;			// WB source
output out_RegWrite;			// write enable for reg file
output out_HLT;					// halt out
output[3:0] out_DstReg;			// output for dest reg WB
output out_PCToReg;
// dffs for each signal
dff ALU_out_reg[15:0](.q(out_ALU_result), .d(in_ALU_result), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff memData_reg[15:0](.q(out_memData), .d(in_memData), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff memToReg_reg(.q(out_MemToReg), .d(in_MemToReg), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff regWrite_reg(.q(out_RegWrite), .d)(in_RegWrite), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff regWrite_reg(.q(out_RegWrite), .d(in_RegWrite), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff hlt_reg(.q(out_HLT), .d(in_HLT), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff dstReg_reg[3:0](.q(out_DstReg), .d(in_DstReg), .wen(1'b1), .clk(clk), .rst(~rst_n));

endmodule
