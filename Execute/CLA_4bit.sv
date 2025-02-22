module CLA_4bit(A, B, sub, Cin, S, P, G);
input [3:0] A, B;
input sub; //choose between add or sub
input Cin;
output P, G;
output [3:0] S;
//wires for  propigate, generate, and carryin for each 1bit partial full adder
wire P0, G0, C1, P1, G1, C2, P2, G2, C3, P3, G3;

//4 1bit partial full adders to compute the addition of half byte
PFA PFA_block0(.A(A[0]), .B(B[0]),.sub(sub), .Cin(Cin), .P(P0), .G(G0), .S(S[0]));
PFA PFA_block1(.A(A[1]), .B(B[1]),.sub(sub), .Cin(C1), .P(P1), .G(G1), .S(S[1]));
PFA PFA_block2(.A(A[2]), .B(B[2]),.sub(sub), .Cin(C2), .P(P2), .G(G2), .S(S[2]));
PFA PFA_block3(.A(A[3]), .B(B[3]),.sub(sub), .Cin(C3), .P(P3), .G(G3), .S(S[3]));

//logic for the carry in for all 4 partial full adders
assign C1 = G0 | (P0 & Cin);
assign C2 = G1 | (P1 & G0)| (P1 & P0 & Cin);
assign C3 = G2 | (P2 & G1) | (P2 & P1 & G0) | (P2 & P1 & P0 & Cin);

//lodgic for the group generate and group propigate of the entire 4bit block
assign P = P3 & P2 & P1& P0;
assign G = G3 | (P3 & G2) | (P3 & P2 & G1) | (P3 & P2 & P1 & G0) | (P3 & P2 & P1 & P0 & Cin);


endmodule
