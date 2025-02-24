module CLA_8bt(A, B, S); //level 1 of the reduction unit for 1 of the 2 8bit sums performeed
input [7:0] A, B;
input [8:0] S; //9 bit output for the 8 bit addition

wire PG0, GG0, Cin1, PG1, GG1;
//output the 9bit val of 8bit summation (final bit is the carryout of the sum)
CLA_4bit G0(.A(A[3:0]), .B(B[3:0]) , .Cin(0) , .S(S[3:0]), .P(PG0), .G(GG0));
CLA_4bit G1(.A(A[7:4]), .B(B[7:4]) , .Cin(GG0) , .S(S[7:4]), .P(PG1), .G(GG1));

assign S[8] = GG1 | (GP1 & GG0);

endmodule