module IF_ID_reg(
    // Inputs from FETCH
    input  [15:0] PC_plus_2_in,   // PC+2 computed in FETCH
    input  [15:0] PC_current_in,  // Current PC from FETCH
    input  [15:0] instr_in,       // Fetched instruction

    // New inputs from DECODE for branch/halt feedback
    input  [15:0] branch_addr_in,
    input         branch_taken_in,
    input         hlt_in,

    // Stall and flush control signals (incoming)
    input         flush_in,       // Asserted when pipeline flush is needed
    input         stall_in,       // Asserted for one cycle to hold PC and instr

    // Clock and reset
    input         clk,
    input         rst_n,

    // Stall and flush signals (outputs to downstream stages)
    output        stall_out,
    output        flush_out,

    // Outputs to DECODE stage (or feedback to FETCH)
    output [15:0] PC_reg_out,     // PC value (PC+2 if no stall; otherwise current PC)
    output [15:0] instr_reg_out,  // Instruction to be decoded
    // New outputs for branch/halt feedback to FETCH
    output [15:0] branch_addr_reg_out,
    output        branch_taken_reg_out,
    output        hlt_reg_out
);

    // Internal registers for PC values
    wire [15:0] PC_plus_2_reg;
    wire [15:0] PC_current_reg;

    // Latch PC+2 from FETCH
    dff PC_plus_2_ff [15:0] (
        .q(PC_plus_2_reg),
        .d(PC_plus_2_in),
        .wen(1'b1),
        .clk(clk),
        .rst(~rst_n)
    );

    // Latch current PC from FETCH
    dff PC_current_ff [15:0] (
        .q(PC_current_reg),
        .d(PC_current_in),
        .wen(1'b1),
        .clk(clk),
        .rst(~rst_n)
    );

    // Latch fetched instruction
    dff instr_ff [15:0] (
        .q(instr_reg_out),
        .d(instr_in),
        .wen(1'b1),
        .clk(clk),
        .rst(~rst_n)
    );

    // Propagate stall signal
    dff stall_ff (
        .q(stall_out),
        .d(stall_in),
        .wen(1'b1),
        .clk(clk),
        .rst(~rst_n)
    );

    // Propagate flush signal
    dff flush_ff (
        .q(flush_out),
        .d(flush_in),
        .wen(1'b1),
        .clk(clk),
        .rst(~rst_n)
    );

    // Latch branch address from DECODE
    dff branch_addr_ff [15:0] (
        .q(branch_addr_reg_out),
        .d(branch_addr_in),
        .wen(1'b1),
        .clk(clk),
        .rst(~rst_n)
    );

    // Latch branch taken signal from DECODE
    dff branch_taken_ff (
        .q(branch_taken_reg_out),
        .d(branch_taken_in),
        .wen(1'b1),
        .clk(clk),
        .rst(~rst_n)
    );

    // Latch halt signal from DECODE
    dff hlt_ff (
        .q(hlt_reg_out),
        .d(hlt_in),
        .wen(1'b1),
        .clk(clk),
        .rst(~rst_n)
    );

    // Output current PC: hold current if stalled; else use PC+2.
    assign PC_reg_out = (stall_out) ? PC_current_reg : PC_plus_2_reg;

endmodule
