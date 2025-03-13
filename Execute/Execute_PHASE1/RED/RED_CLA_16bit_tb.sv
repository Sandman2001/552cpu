module RED_CLA_16bit_tb();
logic signed[15:0] A,B,S;
logic signed[3:0] A3, A2, A1, A0, B3, B2, B1, B0;
logic [11:0] i; //itterator to loop

RED_CLA_16bit iDUT(.A(A), .B(B), .S(S));
logic signed[4:0] ae, bf, cg, dh; 
logic signed[5:0] ae_bf, cg_dh;
logic signed[15:0] sum;
initial begin

for (i = 0; i< 12'hFFF; i = i + 12'h001) begin
	A3 = $random;
	A2 = $random;
	A1 = $random;
	A0 = $random;
	B3 = $random;
	B2 = $random;
	B1 = $random;
	B0 = $random;
	A = {A3, A2, A1, A0};
	B = {B3, B2, B1, B0};
	ae = A3 + B3;
	bf = A2 + B2;
	cg = A1 + B1;
	dh = A0 + B0;
	ae_bf = ae + bf;
	cg_dh = cg + dh;
	sum = ae_bf + cg_dh;
	#1;
	if(S != sum) begin
		$display("iccorect reduction");
		$display((A[15:12] + B[15:12]) + (A[11:8] + B[11:8]) + (A[7:4] + B[7:4]) + (A[3:0] + B[3:0]));
		$stop();
	end
end

//some extra edge cases to make sure it works fully
A = 16'h8888;
B = 16'h8888;
#1;
if (S != 16'hFFC0) begin
	$display("incorrect max sub sign");
	$stop();
end
A = 16'h9999;
B = 16'h7777;
#1
if (S != 16'h0000) begin
	$display("incorrect sub equal and opp");
	$stop();
end
A = 16'h7777;
B = 16'h7777;
#1;
if (S != 16'h0038) begin
	$display("incorrect max sub sign");
 	$stop();
end

$display("YAHOO ALL TESTS PASSED!!!");
$stop();
end
endmodule

