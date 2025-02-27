//andrew Sanders
module addsub_4bit (Sum, Ovfl, A, B, sub);
	input [3:0] A, B; //Input values
	input sub; // add-sub indicator
	output [3:0] Sum; //sum output
	output Ovfl; //To indicate overflow

	wire [2:0] carry;
	wire Cin;
	wire [3:0] Bin;
	wire Cout;
	//intermittent wires for FA operations
	assign Cin = sub ? 1:0; //+1 for 2's complement
	assign Bin = sub ? ~B:B; //these two assign statements create -B = (~B) + 1

	full_adder FA0(.A(A[0]), .B(Bin[0]), .Cin(Cin), .sum(Sum[0]), .Cout(carry[0]));
	full_adder FA1(.A(A[1]), .B(Bin[1]), .Cin(carry[0]), .sum(Sum[1]), .Cout(carry[1]));
	full_adder FA2(.A(A[2]), .B(Bin[2]), .Cin(carry[1]), .sum(Sum[2]), .Cout(carry[2]));
	full_adder FA3(.A(A[3]), .B(Bin[3]), .Cin(carry[2]), .sum(Sum[3]), .Cout(Cout)); //if carry out on last FA, we know overflow
	
	assign Ovfl = carry[2] ^ Cout; //if carry out of last FA and Cout are different, then overflow
endmodule