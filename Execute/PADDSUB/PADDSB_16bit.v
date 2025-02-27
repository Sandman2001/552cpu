// The PADDSB instruction performs four half-byte additions in parallel to realize sub-word parallelism. 
// Specifically, each of the four half bytes (4-bits) will be treated as separate numbers stored in a single word as a byte vector.
// When PADDSB is performed, the four numbers will be added separately. 
// To be more specific, let the contents in rs and rt be aaaa_bbbb_cccc_dddd and eeee_ffff_gggg_hhhh, respectively,
// where a, b, c, d, e, f, g and h in {0, 1}. 
// Then after execution of PADDSB, the contents of rd will be {sat(aaaa+eeee), sat(bbbb+ffff), sat(cccc+gggg), sat(dddd+hhhh)}. 


module PADDSB_16bit (
    input  [15:0] A,
    input  [15:0] B,
    input sub,
    output [15:0] Sum
);

wire [3:0] A_E, B_F, C_G, D_H;
wire [3:0]tempA_E,tempB_F,tempC_G,tempD_H; //temp wires to prevent contention
wire Ovfl_AE, Ovfl_BF, Ovfl_CG, Ovfl_DH;

//saturating logic
//negative saturation: if msb of inputs is 1 & msb of sum is 0(overflow), then saturate to b1000 (-8)
//positive saturation: if msb of inputs is 0 & msb of sum is 1(overflow), then saturate to b0111 (7)
addsub_4bit DopH(.A(A[3:0]), .B(B[3:0]), .sub(sub), .Sum(D_H), .Ovfl(Ovfl_AE));
addsub_4bit CopG(.A(A[7:4]), .B(B[7:4]), .sub(sub), .Sum(C_G), .Ovfl(Ovfl_BF));
addsub_4bit BopF(.A(A[11:8]), .B(B[11:8]), .sub(sub), .Sum(B_F), .Ovfl(Ovfl_CG));
addsub_4bit AopE(.A(A[15:12]), .B(B[15:12]), .sub(sub), .Sum(A_E), .Ovfl(Ovfl_DH));

//saturation logic: if overflow, saturate to 7 (sub = 0) or -8 (sub = 1)
assign tempA_E = Ovfl_AE ? (sub ? 4'h8 : 4'h7) : A_E;
assign tempB_F = Ovfl_BF ? (sub ? 4'h8 : 4'h7) : B_F;
assign tempC_G = Ovfl_CG ? (sub ? 4'h8 : 4'h7) : C_G;
assign tempD_H = Ovfl_DH ? (sub ? 4'h8 : 4'h7) : D_H;

assign Sum = {tempA_E, tempB_F, tempC_G, tempD_H};


endmodule