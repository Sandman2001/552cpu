module PFA(A, B, sub, Cin, P, G, S);
input A,B, Cin;
input sub; //choose between add or sub
output P, G, S; //Prigate and Generate for carry look ahead chain
//partial full adder logic
wire Bin; //Bin allows for add or sub of B so now can choose between add or sub
assign Bin = sub ^ B;
assign P= A^ Bin;
assign S = P ^ Cin;
assign G = A & Bin;
endmodule 
