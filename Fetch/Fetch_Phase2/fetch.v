module fetch(
    clk,
    rst_n,
    branch_flag,
    branch_target,
    stall,
    instruction,
    PC,
    PC_plus_two
);
  // Port declarations in order
  input         clk;
  input         rst_n;
  input         branch_flag;
  input  [15:0] branch_target;
  input         stall;
  output [15:0] instruction;
  output [15:0] PC;
  output [15:0] PC_plus_two;

  // Internal wires
  wire [15:0] pc_plus_2;    // PC + 2 result from CLA
  wire [15:0] pc_out_bus;   // Current PC value from register
  wire [15:0] pc_vs_branch; // PC or branch target for memory fetch
  wire [15:0] next_pc;      // Next PC value from MUX
  wire        inc_PC;       // Enable signal for PC update
  wire [3:0]  opcode;
  wire        instr_halt;   // Halt detected from instruction opcode
  wire        en_inc;       // Instruction not halt flag
  wire [15:0] adder_input;
  wire halted;


  assign adder_input = branch_flag ? branch_target : pc_out_bus; 

  // CLA Adder: Increment PC by 2
  CLA_16bit_AddSub pcADDER (
      .A(adder_input),
      .B(16'h0002),
      .sub(1'b0),
      .Sum(pc_plus_2),
      .Error()
  );

  // Instruction Memory: Fetch instruction (active-high reset)
  memory1c memINSTR (
      .data_out(instruction),
      .data_in(16'b0),
      .addr(pc_vs_branch),
      .enable(1'b1),
      .wr(1'b0),
      .clk(clk),
      .rst(~rst_n)
  );

  // Extract opcode and detect halt from the instruction
  assign opcode     = instruction[15:12];
  assign instr_halt = branch_flag ? 1'b0 : (opcode == 4'b1111) | (halted);
  assign en_inc     = (opcode != 4'b1111);      // NOT A HALT

  // D Flip-Flop for Halt Flag: Once a halt is detected, remains high.
  dff halted_ff (
      .q(halted),
      .d(instr_halt),
      .wen(1'b1),
      .clk(clk),
      .rst(~rst_n)
  );

  // PC update enable: normally update if not halted and not stalled,
  // but always update on branch.
  assign inc_PC = branch_flag ? 1'b1 : (en_inc ? ~(halted | stall) : 1'b0);

  // PC Register: Updates on rising edge when enabled.
  Register pcREG (
      .clk(clk),
      .rst(~rst_n),
      .D(next_pc),
      .WriteReg(inc_PC),
      .ReadEnable1(1'b1),
      .ReadEnable2(1'b0),
      .Bitline1(pc_out_bus),
      .Bitline2()
  );

  // Determine next PC: branch target if branch_flag, or
  // loop on current PC if halted, otherwise increment by 2.
  assign next_pc     =  instr_halt ? pc_out_bus : pc_plus_2;
  assign pc_vs_branch = branch_flag ? branch_target : pc_out_bus;

  // Output assignments
  assign PC = pc_vs_branch;
  assign PC_plus_two = pc_plus_2;

endmodule
