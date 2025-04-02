module fetch(
    input         clk,           // clock
    input         rst_n,         // active low reset for the CPU
    input         branch_flag,   // MUX branch indicator flag
    input  [15:0] branch_target, // target PC location
    input         hlt,     // enable PC increment
    output [15:0] instruction,   // Instruction fetched from memory
    output [15:0] PC,            // current PC (from register)
    output [15:0] PC_plus_two    // PC + 2 (for branch calculations)
);

    /////////////////////
    // Internal Wires  //
    /////////////////////
    wire [15:0] pc_plus_2;  // Result from CLA: PC + 2
    wire [15:0] pc_out_bus; // Current PC value from register
    wire [15:0] next_pc;    // Next PC value from the MUX

    ////////////////////////////////
    // Module Instantiations      //
    ////////////////////////////////

    // CLA Adder: Increments PC value by 2
    CLA_16bit_AddSub pcADDER(
        .A(pc_out_bus),
        .B(16'h0002),
        .sub(1'b0), 
        .Sum(pc_plus_2),
        .Error()
    );

    // Memory: Get instruction from memory
    // Memory expects an active-high reset (rst), so we invert rst_n.
    memory1c memINSTR(
        .data_out(instruction), 
        .data_in(16'b0), 
        .addr(pc_out_bus), 
        .enable(1'b1), 
        .wr(1'b0), 
        .clk(clk), 
        .rst(~rst_n)
    ); 

	// Instantiate a DFF to toggle the halted flag. 
	// Convert the active-low rst_n to an active-high reset for the DFF.
	wire halted;
	dff halted_ff (
		.q   (halted),
		.d   (~halted),  // When enabled, toggle the current state.
		.wen (hlt),      // When HLT is asserted, enable the toggle.
		.clk (clk),
		.rst (~rst_n)    // Internal active-high reset.
	);


	// Use the latched halted flag to enable PC updates.
	// The PC will update if not halted.
	wire inc_PC = ~halted;

	
    // PC Register: Updates the PC value every clock cycle.
    // The register reset is active low, so we pass rst_n directly.
    Register pcREG(
        .clk(clk),
        .rst(~rst_n),
        .D(next_pc),
        .WriteReg(inc_PC),   // update PC when enabled
        .ReadEnable1(1'b1),       // always read out current PC
        .ReadEnable2(1'b0),       // unused
        .Bitline1(pc_out_bus),	
        .Bitline2()               // unused
    );
	
    ////////////////////////////////
    // Combinational Logic        //
    ////////////////////////////////

    // Next PC MUX: chooses between branch target and PC+2.
    assign next_pc = (branch_flag) ? branch_target : pc_plus_2; 

    // Output assignments:
    // PC is the current PC value, and PC_plus_two is the computed PC + 2.
    assign PC = pc_out_bus;
    assign PC_plus_two = pc_plus_2;

endmodule
