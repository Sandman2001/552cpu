module ALU (ALU_Out, Error, ALU_In1, ALU_In2, Opcode);
	input [3:0] ALU_In1, ALU_In2;
	input [1:0] Opcode; 
	output [3:0] ALU_Out;
	output Error; // Just to show overflow

	wire [3:0] addsub_out;
	wire flow;
	wire [3:0] nand_out, xor_out;

    addsub_4bit addsub(.A(ALU_In1), .B(ALU_In2), .sub(Opcode[0]), .Ovfl(flow), .Sum(addsub_out));
    assign nand_out = ~(ALU_In1 & ALU_In2);
    assign xor_out = ALU_In1 ^ ALU_In2;

    assign {ALU_Out, Error} = (Opcode == 2'b00) ? {addsub_out, flow} :
                              (Opcode == 2'b01) ? {addsub_out, flow} :
                              (Opcode == 2'b10) ? {nand_out, 1'b0} :
                                                  {xor_out, 1'b0};
endmodule

