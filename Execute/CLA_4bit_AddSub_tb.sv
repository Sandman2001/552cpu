module CLA_4bit_tb();
logic signed[3:0] S;
logic sub;
logic Cin;
reg signed[3:0] A,B;
logic [1:0] i;
reg [8:0] j;
logic P, G;

CLA_4bit_AddSub iDUT(.A(A), .B(B), .sub(sub), .Cin(Cin), .S(S), .P(P), .G(G));
initial begin
for (sub = 0; sub <=1; sub = sub + 1) begin
	for (i = 0; i < 2'b11; i = i + 1) begin
	//finished thorough testbench is able to checn for both values of Cin and every comb. of possible inputs
		//make more both vals of Cin work when using 4 4bit CLAs
		Cin = i[0];
		for (j= 9'h000; j<9'h100; j = j+9'h001) begin
			A = j[3:0];
			B = j[7:4];
			#5;
			//check is addition is correct(need to add Cin to A and B for the carry chain)
			if((sub == 0) && (S != (A+B + Cin))) begin
				$display("Addition incorrect");
				$stop();
			end
			//Make sure the propigate logic is working correctly
			else if (P != (iDUT.P3 & iDUT.P2 & iDUT.P1 & iDUT.P0)) begin
				$display("Icorrect propigate");
				$stop();
			end
			//Make sure the generate logic is working correctly
			else if (G != (iDUT.G3 | (iDUT.P3 & iDUT.G2) | (iDUT.P3 & iDUT.P2 & iDUT.G1) | (iDUT.P3 & iDUT.P2 & iDUT.P1 & iDUT.G0) | (iDUT.P3 & iDUT.P2 & iDUT.P1 & iDUT.P0 & iDUT.Cin))) begin
				$display("Incorrect Generate");
				$stop();
			end
			else if ((sub == 1) && (S != (A-B + Cin))) begin
				$display("Subtraction incorrect");
				$stop();
			end
		end
	end
	if(sub == 1) begin
		$display("YAHOO ALL TESTS PASSED!!");
		$stop();
	end
end
end
endmodule
