module CLA_16bit(A, B, Sum, Error);
input[15:0] A, B;
output[15:0] Sum;
output Error;
//wires for the Propigate of each 4bit group, Generate of each 4bit group and Carry of each 4bit group
wire PG0, GG0, CG1, PG1, GG1, CG2, PG2, GG2, CG3, PG3, GG3;
//instaniate 4 4bit CLA block to all for adding 4 4-bit values in parrellel
//Cin0 is 0 so you know that Cin1 will be GG0 bc Cin1 = GG0 OR Cin0 and PG0 which means Cin1 = GG0
CLA_4bit CLA_block0(.A(A[3:0]), .B(B[3:0]), .Cin(0), .P(PG0), .G(GG0), .S(Sum[3:0]));
CLA_4bit CLA_block1(.A(A[7:4]), .B(B[7:4]), .Cin(GG0), .P(PG1), .G(GG1), .S(Sum[7:4]));
CLA_4bit CLA_block2(.A(A[11:8]), .B(B[11:8]), .Cin(CG2), .P(PG2), .G(GG2), .S(Sum[11:8]));
CLA_4bit CLA_block3(.A(A[15:12]), .B(B[15:12]), .Cin(CG3), .P(PG3), .G(GG3), .S(Sum[15:12]));

//logic for the carry in for all 4 4-BIT CLA blocks
assign CG2 = GG1 | (PG1 & GG0);
assign C3 = GG2 | (PG2 & GG1) | (PG2 & PG1 & GG0) ;
//Logic to detect overflow
assign Error = (A[15] & B[15] & (~Sum[15])) | ((~A[15]) & (~B[15]) & Sum[15]);

endmodule

