module Execute(ALU_In1, ALU_In2, Opcode, ALU_Out, Ovfl, Neg, Zero, en_Z, en_N, en_V, clk, rst_n);

input [15:0] ALU_In1, ALU_In2;  //input to ALU
input [3:0] Opcode;
input en_Z, en_N, en_V, clk, rst_n;
output [15:0] ALU_Out;
output Ovfl;
output Neg;
output Zero;

wire Z_in, N_in, V_in;
ALU alu(.ALU_In1(ALU_In1), .ALU_In2(ALU_In2), .Opcode(Opcode) , .ALU_Out(ALU_Out), .Ovfl(V_in), .Neg(N_in), .Zero(Z_in));

Flag_Reg flag_reg(.Z_in(Z_in), .N_in(N_in), .V_in(V_in), .en_Z(en_Z), .en_N(en_N), .en_V(en_V), .clk(clk), .rst_n(rst_n), .Z_out(Zero), .N_out(Neg), .V_out(Ovfl));

endmodule