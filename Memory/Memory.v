module Memory(mem_addr, data_in, writeEn, readEn, memToReg, clk, rst_n regWriteData);
input [15:0] mem_addr;
input [15:0] data_in;
input writeEn, readEn, memToReg;
input clk, rst_n;
output [15:0] regWriteData;

wire [15:0] mem_out; //output from memory module

//enstantiate memory module to function for read and write data mem
memory1c (.data_out(mem_out), .data_in(data_in), .addr(mem_addr), .enable(1'b1), .wr(writeEn & (~readEn)), .clk(clk), .rst(rst_n));

assign regWriteData = (memToReg)? mem_out : mem_addr;  //Muxing in wirte back to choose between value read from mem or the actual reg operation to write back to reg file
endmodule