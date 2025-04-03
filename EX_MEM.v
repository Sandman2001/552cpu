module EX_MEM (clk, rst_n, in_ALU_result, in_SW_data, in_MemWrite, in_MemRead, in_MemToReg, in_RegWrite, in_HLT, in_DstReg, out_ALU_result, out_DstReg, out_HLT, out_MemRead, out_MemToReg, out_MemWrite, out_RegWrite, out_SW_data); 

input clk;
input rst_n;

// Inputs to EX stage
input[15:0] in_ALU_result; 	  // ALU Output from EX
input[15:0] in_SW_data;		  // data for store words forwarded to mem
input in_MemWrite;		      // mem write
input in_MemRead;		      // mem read
input in_MemToReg;			  // write back mux
input in_RegWrite;  		  // wb write enable
input in_HLT;			      // halt instr
input[3:0] in_DstReg;		  // reg num for writeback

// Outputs to MEM stage
output[15:0] out_ALU_result;  // ALU input to MEM
output[15:0] out_SW_data;	  // data for SW in MEM
output out_MemWrite;	      // mem write op 
output out_MemRead;			  // mem read
output out_MemToReg;		  // mem data and alu mux
output out_RegWrite;		  // writeback enable
output out_HLT;				  // halt
output disable_bypass;
output[3:0] out_DstReg;		  // destination reg 

dff ALU_out_reg[15:0](.q(out_ALU_result),.d(in_ALU_result),.wen(1'b1),.clk(clk),.rst(~rst_n));
dff SW_data_reg[15:0](.q(out_SW_data),.d(in_SW_data),.wen(1'b1),.clk(clk),.rst(~rst_n));
dff MemWrite_reg(.q(out_MemWrite),.d(in_MemWrite),.wen(1'b1),.clk(clk),.rst(~rst_n));
dff MemRead_reg(.q(out_MemRead),.d(in_MemRead),.wen(1'b1),.clk(clk),.rst(~rst_n));
dff MemToReg_reg(.q(out_MemToReg),.d(in_MemToReg),.wen(1'b1),.clk(clk),.rst(~rst_n));
dff RegWrite_reg(.q(out_RegWrite),.d(in_RegWrite),.wen(1'b1),.clk(clk),.rst(~rst_n));
dff HLT_reg(.q(out_HLT),.d(in_HLT),.wen(1'b1),.clk(clk),.rst(~rst_n));
dff DstReg_reg[3:0](.q(out_DstReg),.d(in_DstReg),.wen(1'b1),.clk(clk),.rst(~rst_n));

endmodule
