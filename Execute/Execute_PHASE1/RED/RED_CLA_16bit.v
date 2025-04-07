module RED_CLA_16bit(A, B, S);
input [15:0] A, B; //16 bit word to be split up into 4 4 bit words
output [15:0] S; //16 bit word that is the sign extended sum of the 4 4 bit words
wire [7:0] a, b, c, d, e, f, g, h; //8bit signextended of the 4 bit words to be added
wire [8:0] sum_ae, sum_bf, sum_cg, sum_dh; //sums of the 4 4 bit words level1
wire c_ae, c_bf, c_cg, c_dh; //carry bits of the 4 4 bit words level 1

wire [8:0] sum_ae_bf, sum_cg_dh; //sums of the 4 4 bit words level 2
wire c_ae_bf, c_cg_dh; //carry bits of the 4 4 bit words level 2

wire [8:0] sum_ae_bf_cg_dh; //sums of the 4 4 bit words level 3
wire c_final; //carry bits of the 4 4 bit words level 3

//sign extending the 4 bit words
assign a = {{4{A[15]}}, A[15:12]};
assign b = {{4{A[11]}}, A[11:8]};
assign c = {{4{A[7]}}, A[7:4]};
assign d = {{4{A[3]}}, A[3:0]};
assign e = {{4{B[15]}}, B[15:12]};
assign f = {{4{B[11]}}, B[11:8]};
assign g = {{4{B[7]}}, B[7:4]};
assign h = {{4{B[3]}}, B[3:0]}; 

//level 1 of the addition tree
RED_CLA_4bit sum_ae1(.A(a[3:0]), .B(e[3:0]), .Cin(1'b0), .S( {c_ae, sum_ae[3:0]}));
RED_CLA_4bit sum_ae2(.A(a[7:4]), .B(e[7:4]), .Cin(c_ae), .S(sum_ae[8:4]));

RED_CLA_4bit sum_bf1(.A(b[3:0]), .B(f[3:0]), .Cin(1'b0), .S( {c_bf, sum_bf[3:0]}));
RED_CLA_4bit sum_bf2(.A(b[7:4]), .B(f[7:4]), .Cin(c_bf), .S(sum_bf[8:4]));

RED_CLA_4bit sum_cg1(.A(c[3:0]), .B(g[3:0]), .Cin(1'b0), .S( {c_cg, sum_cg[3:0]}));
RED_CLA_4bit sum_cg2(.A(c[7:4]), .B(g[7:4]), .Cin(c_cg), .S(sum_cg[8:4]));

RED_CLA_4bit sum_dh1(.A(d[3:0]), .B(h[3:0]), .Cin(1'b0), .S( {c_dh, sum_dh[3:0]}));
RED_CLA_4bit sum_dh2(.A(d[7:4]), .B(h[7:4]), .Cin(c_dh), .S(sum_dh[8:4]));

//level 2 of the reduction tree
RED_CLA_4bit sum_ae_bf1(.A(sum_ae[3:0]), .B(sum_bf[3:0]), .Cin(1'b0), .S( {c_ae_bf, sum_ae_bf[3:0]}));
RED_CLA_4bit sum_ae_bf2(.A(sum_ae[7:4]), .B(sum_bf[7:4]), .Cin(c_ae_bf), .S(sum_ae_bf[8:4]));

RED_CLA_4bit sum_cg_dh1(.A(sum_cg[3:0]), .B(sum_dh[3:0]), .Cin(1'b0), .S({c_cg_dh, sum_cg_dh[3:0]}));
RED_CLA_4bit sum_cg_dh2(.A(sum_cg[7:4]), .B(sum_dh[7:4]), .Cin(c_cg_dh), .S(sum_cg_dh[8:4]));

//level 3 of the reduction tree
RED_CLA_4bit sum_ae_bf_cg_dh1(.A(sum_ae_bf[3:0]), .B(sum_cg_dh[3:0]), .Cin(1'b0), .S( {c_final, sum_ae_bf_cg_dh[3:0]}));
RED_CLA_4bit sum_ae_bf_cg_dh2(.A(sum_ae_bf[7:4]), .B(sum_cg_dh[7:4]), .Cin(c_final), .S(sum_ae_bf_cg_dh[8:4]));

assign S = {{9{sum_ae_bf_cg_dh[8]}},sum_ae_bf_cg_dh[6:0]};

endmodule