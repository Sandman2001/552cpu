module PSA_16bit (Sum, Error, A, B);
    input [15:0] A, B; 	// Input data values
    output [15:0] Sum; 	// Sum output
    output Error; 	// To indicate overflows

    wire [3:0] oflow; 	// Overflow output for any of the parallel adders 
    addsub_4bit paralleladders[3:0] (.A(A), .B(B), .Sum(Sum), .Ovfl(oflow), .sub(1'b0)); 	// 4-bit parallel adder/subtractor

    assign Error = oflow[0] | oflow[1] | oflow[2] | oflow[3]; 	// If any of the parallel adders overflow, then the 16-bit adder overflows
endmodule
