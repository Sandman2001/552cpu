module CLA_16bit(A, B, S);
input [15:0] A, B;
output [15:0] S;
wire PG0, GG0, Cin1, PG1, GG1, Cin2, PG2, GG2, Cin3, PG3, GG3;
wire [8:0] sumLevel1_1,sumLevel1_2;
CLA_8bt level1_1(.A(A[7:0]), .B(B[7:0]), .S(sumLevel1_1));
CLA_8bt level1_1(.A(A[15:8]), .B(B[15:8]), .S(sumLevel1_2));
//3 4bit CLA blocks to allow for the final addition of the 2 fisrt level of 2 bit sums of the 16bit input
CLA_4bit Level2_G0(.A(sumLevel1_1[3:0]), .B(sumLevel1_2[3:0]) , .Cin(0) , .S(S[3:0]), .P(PG0), .G(GG0));

CLA_4bit Level2_G0(.A(sumLevel1_1[7:4]), .B(sumLevel1_2[7:4]) , .Cin(GG0) , .S(S[7:4]), .P(PG1), .G(GG1));

CLA_4bit Level2_G0(.A({4{sumLevel1_1[8]}}), .B({4{sumLevel1_2[8]}}) , .Cin(Cin2) , .S(S[11:8]), .P(PG2), .G(GG2));

assign Cin2 = GG1 | (PG1 & GG0)
assign C3 = G2 | (P2 & G1) | (P2 & P1 & G0) | (P2 & P1 & P0 & Cin);
//sign extending the MSB of sum to make sum 16 bits
assign S[15:12] = {4{S[11]}};

endmodule