module CLA_16bit_AddSub(A, B, sub, Sum, Error);
input[15:0] A, B;
input sub;  //indicate subtraction or addition
output[15:0] Sum;
output Error;
//intermediate outputs to allow for choosing between arithmatic saturations and actual output
wire [15:0] Sum_temp;
//wires for the Propigate of each 4bit group, Generate of each 4bit group and Carry of each 4bit group
wire PG0, GG0, CG1, PG1, GG1, CG2, PG2, GG2, CG3, PG3, GG3;
//instaniate 4 4bit CLA block to all for adding 4 4-bit values in parrellel
//Cin0 is 0 so you know that Cin1 will be GG0 bc Cin1 = GG0 OR Cin0 and PG0 which means Cin1 = GG0
CLA_4bit_AddSub CLA_block0(.A(A[3:0]), .B(B[3:0]), .sub(sub), .Cin(sub), .P(PG0), .G(GG0), .S(Sum_temp[3:0]));
CLA_4bit_AddSub CLA_block1(.A(A[7:4]), .B(B[7:4]), .sub(sub), .Cin(CG1), .P(PG1), .G(GG1), .S(Sum_temp[7:4]));
CLA_4bit_AddSub CLA_block2(.A(A[11:8]), .B(B[11:8]), .sub(sub), .Cin(CG2), .P(PG2), .G(GG2), .S(Sum_temp[11:8]));
CLA_4bit_AddSub CLA_block3(.A(A[15:12]), .B(B[15:12]), .sub(sub), .Cin(CG3), .P(PG3), .G(GG3), .S(Sum_temp[15:12]));

//logic for the carry in for all 4 4-BIT CLA blocks
assign cG1 = GG0 | (PG0 & sub);
assign CG2 = GG1 | (PG1 & GG0);
assign CG3 = GG2 | (PG2 & GG1) | (PG2 & PG1 & GG0) ;
//Logic to detect overflow
assign Error = (A[15] & B[15] & (~Sum[15])) | ((~A[15]) & (~B[15]) & Sum[15]);
//choosing for output of pos saturation
assign Sum = (A[15] & B[15] & (~Sum[15]))? 16'7FFF : Sum_temp;
//choosing for output of neg saturation
assign Sum = ((~A[15]) & (~B[15]) & Sum[15])? 16'8000 : Sum_temp;

endmodule

