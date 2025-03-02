module fetch(clk, rst_n, branch_flag, branch_target, instruction, PC);

	/////////////////////
	// Ports and Wires //
	/////////////////////

	input clk;						// clock
	input rst_n;					// active low reset
	input branch_flag;				// MUX branch indicator flag
	input  [15:0] branch_target;	// target PC location
	output [15:0] instruction;		// Instruction fetched from memory
	output [15:0] PC;				// PC output for branch calculation

	wire [15:0] pc_plus_2; 			// Output from CLA for PC + 2
	wire [15:0] pc_out_bus;			// Current PC value
	wire [15:0] next_pc;			// MUX output

	///////////////////////////
	// Module Instantiations //
	///////////////////////////

	// CLA Adder: Increments PC value by 2
	CLA_16bit_AddSub pcADDER(
	.A(pc_out_bus),
	.B(16'h0002),
	.sub(1'b0), 
	.Sum(pc_plus_2),
	.Cout()
	 );

	// Memory: Get instruction from memory
	memory1c memINSTR(
	.data_out(instruction), 
	.data_in(16'b0), 
	.addr(pc_out_bus), 
	.enable(1'b1), 
	.wr(1'b0), 
	.clk(clk), 
	.rst(~rst_n)
	); 
	
	// PC Register: Updates pc value every clock cycle
	Register pcREG(
	.clk(clk),
	.rst_n(rst_n),
	.D(next_pc),
	.WriteReg(1'b1),		// always update pc
	.ReadEnable1(1'b1),		// always read out
	.ReadEnable2(1'b0),		// unused
	.Bitline1(pc_out_bus),	
	.Bitline2()				// unused bitline
	);
	
	/////////////////////////
	// Combinational Logic //
	/////////////////////////
	
	// PC Value MUX
	assign next_pc = (branch_flag) ? branch_target : pc_plus_2; 

	// Drive PC output
	assign PC = pc_out_bus;
	
endmodule