module CLA_16bit(A, B, S);
input [15:0] A, B;
output [15:0] S;
wire [4:0] sum_ae, sum_bf, sum_cg, sum_dh;
wire [5:0] sum_ae_bf, sum_cg_dh;
wire [10:0] dontCare;
//level 1 of the addition tree
CLA_4bit sum_ae_com(.A(A[15:12]), .B(B[15:12]), .S(sum_ae));
CLA_4bit sum_bf_comp(.A(A[11:8]), .B(B[11:8]), .S(sum_bf));
CLA_4bit sum_cg_comp(.A(A[7:4]), .B(B[7:4]), .S(sum_cg));
CLA_4bit sum_dh_comp(.A(A[3:0]), .B(B[3:0]), .S(sum_dh));

//level 2 of the reduction tree
CLA_4bit sum_ae_bf_1(.A(sum_ae[3:0]), .B(sum_bf[3:0]), .S(sum_ae_bf[3:0]));
CLA_4bit sum_ae_bf_2(.A({4{sum_ae[4]}}), .B({4{sum_bf[4]}}), .S({dontCare[1:0],sum_ae_bf[5:4]}));
CLA_4bit sum_cg_dh_1(.A(sum_cg[3:0]), .B(sum_dh[3:0]), .S(sum_cg_dh[3:0]));
CLA_4bit sum_cg_dh_2(.A({4{sum_cg[4]}}), .B({4{sum_dh[4]}}), .S({dontCare[3:2],sum_cg_dh[5:4]}));

//level 3 of the reduction tree
CLA_4bit sum_ae_bf_cg_dh_1(.A(sum_ae_bf[3:0]), .B(sum_cg_dh[3:0]), .S(S[3:0]));
CLA_4bit sum_ae_bf_cg_dh_2(.A({{2{sum_ae_bf[5]}},sum_ae_bf[5:4]}), .B({{2{sum_cg_dh[5]}},sum_cg_dh[5:4]}), .S(S[7:0]));

//signextending the msb of the sum work
assign S[15:8] = {8{S[7]}};
endmodule