module Addr_Shifter_tb();
logic [15:0] A, B, S, i;

Addr_Shifter iDUT(.A(A), .B(B), .S(S));
initial begin
for (i = 0; i < 16'hFFFF; i = i + 16'h0001) begin
	A = $random;
	B = $random;
	#1;
	if (S != ((A << 1) + B)) begin
		$display("Inncorrect add");
		$stop();
	end
end
$display("YAHOO ALL TESTS PASSED!!!");
$stop();
end
endmodule

