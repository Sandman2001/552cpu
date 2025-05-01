//Tag Array of 128  blocks
//Each block will have 1 byte
//BlockEnable is one-hot
//WriteEnable is one on writes and zero on reads

module MetaDataArray(input clk, input rst, input [7:0] DataIn1, input [7:0] DataIn2, input Write1, input Write2, input [63:0] BlockEnable, output [7:0] DataOut1, output [7:0] DataOut2);
	MBlock Mway1[63:0](.clk(clk), .rst(rst), .Din(DataIn1), .WriteEnable(Write1), .Enable(BlockEnable), .Dout(DataOut1));
	MBlock Mway2[63:0](.clk(clk), .rst(rst), .Din(DataIn2), .WriteEnable(Write2), .Enable(BlockEnable), .Dout(DataOut2));
endmodule

module MBlock( input clk,  input rst, input [7:0] Din, input WriteEnable, input Enable, output [7:0] Dout);
	MCell mc[7:0]( .clk(clk), .rst(rst), .Din(Din[7:0]), .WriteEnable(WriteEnable), .Enable(Enable), .Dout(Dout[7:0]));
endmodule

module MCell( input clk,  input rst, input Din, input WriteEnable, input Enable, output Dout);
	wire q;
	assign Dout = (Enable & ~WriteEnable) ? q:'bz;
	dff dffm(.q(q), .d(Din), .wen(Enable & WriteEnable), .clk(clk), .rst(rst));
endmodule

