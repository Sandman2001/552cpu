module full_adder(
  input 	A,B,Cin,	// three input bits to be added
  output	sum,Cout		// Sum and carry out
);

	/////////////////////////////////////////////////
	// Declare any internal signals as type logic //
	///////////////////////////////////////////////
	wire A_xor_B, A_and_B, AB_and_Cin;
	//new code here	
	
	/////////////////////////////////////////////////
	// Implement Full Adder as structural verilog //
	///////////////////////////////////////////////
	xor sum_b4_carry(A_xor_B, A, B);
	and carry_AB(A_and_B, A, B);
	xor s(sum, A_xor_B, Cin);
	and andABCin(AB_and_Cin, A_xor_B, Cin);
	or carryout(Cout, AB_and_Cin, A_and_B);
	
endmodule
