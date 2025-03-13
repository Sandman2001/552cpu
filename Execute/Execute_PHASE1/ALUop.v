module ALUop(ALUop, AddSub, sub, XOR, RED, PADDSB, out);
input [2:0] ALUop;
input [15:0] AddSub, XOR, RED, PADDSB;
output sub; //signal to choose if adding or subtracting
output [15:0] out; //output of the ALU

//muxing between the different ALU operatioins
assign out = (ALUop[2:1] == 2'b00) ? AddSub :
             (ALUop == 3'b010) ? XOR :
             (ALUop == 3'b011) ? RED : PADDSB;

endmodule