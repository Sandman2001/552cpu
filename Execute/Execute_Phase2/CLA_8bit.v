module CLA_8bit(A, B, S);
input[7:0] A, B;
output[8:0] S;
//wires for the Propigate of each 4bit group, Generate of each 4bit group and Carry of each 4bit group
wire PG0, GG0, PG1, GG1;
//instaniate 4 4bit CLA block to all for adding 4 4-bit values in parrellel
//Cin0 is 0 so you know that Cin1 will be GG0 bc Cin1 = GG0 OR Cin0 and PG0 which means Cin1 = GG0
CLA_4bit CLA_block0(.A(A[3:0]), .B(B[3:0]), .Cin(0), .P(PG0), .G(GG0), .S(S[3:0]));
CLA_4bit CLA_block1(.A(A[7:4]), .B(B[7:4]), .Cin(GG0), .P(PG1), .G(GG1), .S(S[7:4]));

//logic for the carry in for all 4 4-BIT CLA blocks
assign S[8] = GG1 | (PG1 & GG0);

endmodule