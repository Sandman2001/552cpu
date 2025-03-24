module IF_ID_reg_tb();
logic [15:0] inc_PC_in, instr_in, PC_out, instr_out;
logic flush, nop, clk, rst_n;
logic [7:0] i;
IF_ID_reg iDUT(.inc_PC_in(inc_PC_in), .PC_out(PC_out), .instr_in(instr_in), .instr_out(instr_out), .flush(flush), .nop(nop), .clk(clk), .rst_n(rst_n));
initial begin
clk = 0;
@(negedge clk);
rst_n = 0;
@(negedge clk);
rst_n = 1;

for ( i=8'h02; i< 8'hFF; i = i + 8'h01) begin
	inc_PC_in = {i,i};
	instr_in = {i,i};
	flush = 1'b0;
	nop = 1'b0;
	#2;
	if( (PC_out != inc_PC_in) || (instr_in!=instr_out)) begin
		$display("not outputting instr and PC correctly with no flush and no nop");
		$stop();
	end
	nop = 1'b1;
	#2;
	if( (PC_out != (inc_PC_in - 16'h0002)) || (instr_out!=16'h0000)) begin
		$display("not outputting instr or PC correctly with no flush and YES nop");
		$stop();
	end
	nop = 1'b0;
	flush = 1'b1;
	#2;
	if( (PC_out != (inc_PC_in)) || (instr_out!=16'h0000)) begin
		$display("not outputting instr or PC correctly with YES flush and no nop");
		$stop();
	end
end
$display("YAHOO ALL TESTS PASSED!!!");
$stop();
end
always
#1 clk = ~clk;
endmodule
