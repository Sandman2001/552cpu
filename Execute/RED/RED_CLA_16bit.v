module RED_CLA_16bit(A, B, S);
input [15:0] A, B;
output [15:0] S;
wire [7:0] sum_ae, sum_bf, sum_cg, sum_dh;
wire carry_ae_bf, carry_cg_dh, carry_tot;
wire [8:0]  sum_ae_bf, sum_cg_dh;
wire [8:0] sum;


assign sum_ae [7:5] = 4'h0;
assign sum_bf [7:5] = 4'h0;
assign sum_cg [7:5] = 4'h0;
assign sum_dh [7:5] = 4'h0;


//level 1 of the addition tree
RED_CLA_4bit sum_ae_comp(.A(A[15:12]), .B(B[15:12]), .Cin(1'b0), .S(sum_ae[4:0]));
RED_CLA_4bit sum_bf_comp(.A(A[11:8]), .B(B[11:8]), .Cin(1'b0), .S(sum_bf[4:0]));
RED_CLA_4bit sum_cg_comp(.A(A[7:4]), .B(B[7:4]), .Cin(1'b0), .S(sum_cg[4:0]));
RED_CLA_4bit sum_dh_comp(.A(A[3:0]), .B(B[3:0]), .Cin(1'b0), .S(sum_dh[4:0]));

//level 2 of the reduction tree
RED_CLA_4bit sum_ae_bf_1(.A(sum_ae[3:0]), .B(sum_bf[3:0]), .Cin(1'b0), .S({carry_ae_bf,sum_ae_bf[3:0]}));
RED_CLA_4bit sum_ae_bf_2(.A(sum_ae[7:4]), .B(sum_bf[7:4]), .Cin(carry_ae_bf), .S(sum_ae_bf[8:4]));

RED_CLA_4bit sum_cg_dh_1(.A(sum_cg[3:0]), .B(sum_dh[3:0]), .Cin(1'b0), .S({carry_cg_dh,sum_cg_dh[3:0]}));
RED_CLA_4bit sum_cg_dh_2(.A(sum_cg[7:4]), .B(sum_dh[7:4]), .Cin(carry_cg_dh), .S(sum_cg_dh[8:4]));
//level 3 of the reduction tree
RED_CLA_4bit sum_ae_bf_cg_dh_1(.A(sum_ae_bf[3:0]), .B(sum_cg_dh[3:0]), .Cin(1'b0), .S({carry_tot,sum[3:0]}));
RED_CLA_4bit sum_ae_bf_cg_dh_2(.A(sum_ae_bf[7:4]), .B(sum_cg_dh[7:4]), .Cin(carry_tot), .S(sum[8:4]));

//signextending the msb of the sum work
assign S = {{9{sum[6]}}, sum[6:0]};
endmodule