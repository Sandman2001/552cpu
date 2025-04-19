module RED_CLA_16bit(A, B, S);
  input  [15:0] A, B; // 16-bit inputs to be split into 4 half-byte operands each
  output [15:0] S;    // 16-bit final result (zero-extended)

  // Zero-extend each 4-bit nibble to 8 bits (upper 4 bits are zero)
  wire [7:0] a, b, c, d, e, f, g, h;
  assign a = {4'b0000, A[15:12]};
  assign b = {4'b0000, A[11:8]};
  assign c = {4'b0000, A[7:4]};
  assign d = {4'b0000, A[3:0]};
  assign e = {4'b0000, B[15:12]};
  assign f = {4'b0000, B[11:8]};
  assign g = {4'b0000, B[7:4]};
  assign h = {4'b0000, B[3:0]};

  // Level 1: Add corresponding nibble pairs using 4-bit CLA adders.
  // Each addition yields a 5-bit result (range 0–30).
  wire [8:0] sum_ae, sum_bf, sum_cg, sum_dh;
  wire c_ae, c_bf, c_cg, c_dh;
  RED_CLA_4bit sum_ae1(.A(a[3:0]), .B(e[3:0]), .Cin(1'b0), .S({c_ae, sum_ae[3:0]}));
  RED_CLA_4bit sum_ae2(.A(a[7:4]), .B(e[7:4]), .Cin(c_ae), .S(sum_ae[8:4]));

  RED_CLA_4bit sum_bf1(.A(b[3:0]), .B(f[3:0]), .Cin(1'b0), .S({c_bf, sum_bf[3:0]}));
  RED_CLA_4bit sum_bf2(.A(b[7:4]), .B(f[7:4]), .Cin(c_bf), .S(sum_bf[8:4]));

  RED_CLA_4bit sum_cg1(.A(c[3:0]), .B(g[3:0]), .Cin(1'b0), .S({c_cg, sum_cg[3:0]}));
  RED_CLA_4bit sum_cg2(.A(c[7:4]), .B(g[7:4]), .Cin(c_cg), .S(sum_cg[8:4]));

  RED_CLA_4bit sum_dh1(.A(d[3:0]), .B(h[3:0]), .Cin(1'b0), .S({c_dh, sum_dh[3:0]}));
  RED_CLA_4bit sum_dh2(.A(d[7:4]), .B(h[7:4]), .Cin(c_dh), .S(sum_dh[8:4]));

  // Level 2: Add the level 1 results pairwise.
  wire [8:0] sum_ae_bf, sum_cg_dh;
  wire c_ae_bf, c_cg_dh;
  RED_CLA_4bit sum_ae_bf1(.A(sum_ae[3:0]), .B(sum_bf[3:0]), .Cin(1'b0), .S({c_ae_bf, sum_ae_bf[3:0]}));
  RED_CLA_4bit sum_ae_bf2(.A(sum_ae[7:4]), .B(sum_bf[7:4]), .Cin(c_ae_bf), .S(sum_ae_bf[8:4]));

  RED_CLA_4bit sum_cg_dh1(.A(sum_cg[3:0]), .B(sum_dh[3:0]), .Cin(1'b0), .S({c_cg_dh, sum_cg_dh[3:0]}));
  RED_CLA_4bit sum_cg_dh2(.A(sum_cg[7:4]), .B(sum_dh[7:4]), .Cin(c_cg_dh), .S(sum_cg_dh[8:4]));

  // Level 3: Add the two level 2 results.
  wire [8:0] sum_total;
  wire c_final;
  RED_CLA_4bit sum_total1(.A(sum_ae_bf[3:0]), .B(sum_cg_dh[3:0]), .Cin(1'b0), .S({c_final, sum_total[3:0]}));
  RED_CLA_4bit sum_total2(.A(sum_ae_bf[7:4]), .B(sum_cg_dh[7:4]), .Cin(c_final), .S(sum_total[8:4]));

  // Final result: Since the sum is nonnegative, zero-extend to 16 bits.
  assign S = {8'b0, sum_total[6:0]};
  
endmodule
