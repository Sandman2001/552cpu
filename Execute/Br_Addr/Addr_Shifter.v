module Addr_Shifter(A, B, S);
input [15:0] A; // Input the signextended branch addr that needs to be shifted left
input [15:0] B; // input for the next PC addr 
output [15:0] S;  //Sum of the two addrs
wire Ovfl;
wire [15:0] A_shift; //shift the Br addr by 1 = *2

assign A_shift = {A[14:0], 1'b0};
CLA_16bit BR_addr(.A(A_shift), .B(B), .Sum(S), .Error(Ovfl));

endmodule
