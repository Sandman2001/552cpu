module CLA_16bit_tb();
logic signed[15:0] A, B, Sum;
logic sub;
logic Error;
logic [9:0] i; //itterator

CLA_16bit_AddSub iDUT(.A(A), .B(B), .sub(sub), .Sum(Sum), .Error(Error));
initial begin
for (sub = 0; sub <= 1; sub = sub + 1) begin
	for (i='0; i<=10'h200; i=i+10'h001) begin
		A = $random;
		B = $random;
		#1;
		//make sure the overflow flag is being detected correctly 
		if((A[15] == B[15]) && (Sum[15] != A[15]) && Error != 1)begin
			$display("overflow is not being detected");
			$stop();
		end
		//making sure the saturating at correct portions
		else if ((Error == 1) && (A[15] & B[15] & (~Sum[15])) && (Sum != 16'h7FFF)) begin
			$display("Incorrect Pos Saturatioin");
			$stop();
		end
		else if ((Error == 1) && (~A[15] & ~B[15] & (Sum[15])) && (Sum != 16'h8000)) begin
			$display("Incorrect Neg Saturatioin");
			$stop();
		end
		//Tests if saturation doesn't happen so making sure normal cases work
		else if((Error == 0) && (sub == 0) && (Sum != A+B)) begin
			$display("Addition incorrect");
			$stop();
		end
		else if((Error == 0) && (sub == 1) && (Sum != A-B)) begin
			$display("Subtraction incorrect");
			$stop();
		end
	end
		if (sub == 1) begin
			$display("YAHOO ALL TESTS PASSED !!!!!");
			$stop();
		end
end
end
//if able to make it through 1024 different random cases that adder works correctly

endmodule
