module RED_CLA_16bit(A, B, S);
input [15:0] A, B;
output [15:0] S;
wire [7:0] sum_ae, sum_bf, sum_cg, sum_dh;
wire carry_ae_bf, carry_cg_dh, carry_tot;

wire ovfl_ae, ovfl_bf, ovfl_cg, ovfl_dh;
wire ovfl_ae_bf, ovfl_cg_dh; //Overflow flags to check for the second level of tree to check for overflow
wire ovfl_tot; //Overflow flag to check for the third level of tree to check for overflow
wire [8:0]  sum_ae_bf, sum_cg_dh;
wire [8:0] sum;

wire c_temp_ae, c_temp_bf, c_temp_cg, c_temp_dh;//temp carry to see if need to adjust with overflow
wire c_temp_ae_bf, c_temp_cg_dh;//temp carry to see if need to adjust with overflow
wire c_temp_tot;//temp carry to see if need to adjust with overflow

assign sum_ae [7:5] = 4'h0;
assign sum_bf [7:5] = 4'h0;
assign sum_cg [7:5] = 4'h0;
assign sum_dh [7:5] = 4'h0;


//level 1 of the addition tree
RED_CLA_4bit sum_ae_comp(.A(A[15:12]), .B(B[15:12]), .Cin(1'b0), .Ovfl(ovfl_ae), .S({c_temp_ae, sum_ae[3:0]}));
RED_CLA_4bit sum_bf_comp(.A(A[11:8]), .B(B[11:8]), .Cin(1'b0), .Ovfl(ovfl_bf), .S({c_temp_bf, sum_bf[3:0]}));
RED_CLA_4bit sum_cg_comp(.A(A[7:4]), .B(B[7:4]), .Cin(1'b0), .Ovfl(ovfl_cg), .S({c_temp_cg, sum_cg[3:0]}));
RED_CLA_4bit sum_dh_comp(.A(A[3:0]), .B(B[3:0]), .Cin(1'b0), .Ovfl(ovfl_dh), .S({c_temp_dh, sum_dh[3:0]}));
//muxing to choose if need to care about the carry bit of each sum
assign sum_ae[4] = ovfl_ae ? c_temp_ae : sum_ae[3];
assign sum_bf[4] = ovfl_bf ? c_temp_bf : sum_bf[3];
assign sum_cg[4] = ovfl_cg ? c_temp_cg : sum_cg[3];
assign sum_dh[4] = ovfl_dh ? c_temp_dh : sum_dh[3];

//level 2 of the reduction tree
RED_CLA_4bit sum_ae_bf_1(.A(sum_ae[3:0]), .B(sum_bf[3:0]), .Cin(1'b0), .Ovfl(), .S({carry_ae_bf,sum_ae_bf[3:0]}));
RED_CLA_4bit sum_ae_bf_2(.A(sum_ae[7:4]), .B(sum_bf[7:4]), .Cin(carry_ae_bf), .Ovfl(ovfl_ae_bf), .S({sum_ae_bf[8:6],c_temp_ae_bf,sum_ae_bf[4]}));

RED_CLA_4bit sum_cg_dh_1(.A(sum_cg[3:0]), .B(sum_dh[3:0]), .Cin(1'b0), .Ovfl(), .S({carry_cg_dh,sum_cg_dh[3:0]}));
RED_CLA_4bit sum_cg_dh_2(.A(sum_cg[7:4]), .B(sum_dh[7:4]), .Cin(carry_cg_dh), .Ovfl(ovfl_cg_dh), .S({sum_cg_dh[8:6],c_temp_cg_dh,sum_cg_dh[4]}));
//muxing to choose if need to care about the carry bit of each sum
assign sum_ae_bf[5] = (sum_ae[4] & sum_bf[4] & (~sum_ae_bf[4])) | ((~sum_ae[4]) & (~sum_bf[4]) & sum_ae_bf[4]) ? c_temp_ae_bf : sum_ae_bf[4];
assign sum_cg_dh[5] = (sum_cg[4] & sum_dh[4] & (~sum_cg_dh[4])) | ((~sum_cg[4]) & (~sum_dh[4]) & sum_cg_dh[4]) ? c_temp_ae_bf : sum_cg_dh[4];

//level 3 of the reduction tree
RED_CLA_4bit sum_ae_bf_cg_dh_1(.A(sum_ae_bf[3:0]), .B(sum_cg_dh[3:0]), .Cin(1'b0), .Ovfl(), .S({carry_tot,S[3:0]}));
RED_CLA_4bit sum_ae_bf_cg_dh_2(.A(sum_ae_bf[7:4]), .B(sum_cg_dh[7:4]), .Cin(carry_tot), .Ovfl(ovfl_tot), .S({sum[1:0],c_temp_tot,S[5:4]}));



//signextending the msb of the sum depending on overflow or not
assign S[15:6] = (sum_ae_bf[5] & sum_cg_dh[5] & (~S[5])) | ((~sum_ae_bf[5]) & (~sum_cg_dh[5]) & S[5]) ? {10{c_temp_tot}} : {10{S[5]}};
endmodule