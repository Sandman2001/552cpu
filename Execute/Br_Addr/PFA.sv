module PFA(A, B, Cin, P, G, S);
input A,B, Cin;
output P, G, S; //Prigate and Generate for carry look ahead chain
//partial full adder logic
assign P= A^ B;
assign S = P ^ Cin;
assign G = A & B;
endmodule 
