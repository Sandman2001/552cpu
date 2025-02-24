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
		#5;
		//make sure the overflow flag is being detected correctly 
		if((A[15] == B[15]) && (Sum[15] != A[15]) && Error != 1)begin
			$display("overflow is not being detected");
			$stop();
		end
		//make sure that even with everflow sum is always bewing computed correctly
		else if((sub == 0) && (Sum != A+B)) begin
			$display("Addition incorrect");
			$stop();
		end
		else if((sub == 1) && (Sum != A-B)) begin
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
