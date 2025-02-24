module CLA_4bit(A, B , Cin , S, P, G);
input [3:0] A, B;
input Cin;
output [3:0] S;
output P,G;

wire P0, G0, P1, C1, G1, C2, P2, G2, C3, P3, G3;

//4 bit CLA block that allows only for addition NO sub ability
PFA PFA0(.A(A[0]), .B(B[0]), .Cin(Cin), .P(P0), .G(G0), .S(S[0]));
PFA PFA1(.A(A[1]), .B(B[1]), .Cin(C1), .P(P1), .G(G1), .S(S[1]));
PFA PFA2(.A(A[2]), .B(B[2]), .Cin(C2), .P(P2), .G(G2), .S(S[2]));
PFA PFA3(.A(A[3]), .B(B[3]), .Cin(C3), .P(P3), .G(G3), .S(S[3]));

assign C1 = G0 | (P0 & Cin);
assign C2 = G1 | (P1 & G0) | (P1 & P0 & Cin);
assign C3 = G2 | (P2 & G1) | (P2 & P1 & G0) | (P2 & P1 & P0 & Cin);
assign P = P3 & P2 & P1 & P0;
assign G = G3 | (P3 & G2) | (P3 & P2 & G1) | (P3 & P2 & P1 & G0);
endmodule