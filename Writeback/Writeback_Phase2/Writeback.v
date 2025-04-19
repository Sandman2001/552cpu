module Writeback(memData, ALU_out, memToReg, regWriteData);
input [15:0] memData, ALU_out;
input memToReg;
output [15:0] regWriteData;

assign regWriteData = (memToReg)? memData : ALU_out;  //Muxing in write back to choose between value read from mem or the actual reg operation to write back to reg file
endmodule