module control_unit(
    // Input
    input [15:0] instr,            // 16-bit instruction from instruction memory

    // Flag register inputs
    input Z_flag,                  // Zero flag
    input N_flag,                  // Negative flag
    input V_flag,                  // Overflow flag
    
    // Register file addressing
    output [3:0] SrcReg1,          // First source register address
    output [3:0] SrcReg2,          // Second source register address
    output [3:0] DstReg,           // Destination register address
    
    // Register file control signals
    output        RegWrite,        // Enable writing to register file
    
    // ALU control signals
    output [3:0]  ALUOp,           // Operation code for ALU
    output        ALUSrc_1,        // 0: Use SrcReg1, 1: Use PC+2 
    output        ALUSrc_2,        // 0: Use SrcReg2, 1: Use immediate
    output [1:0]  ImdChoice,       // Immediate choice for different operations
    
    // Memory control signals
    output        MemRead,         // Enable reading from data memory
    output        MemWrite,        // Enable writing to data memory
    output        MemToReg,        // 0: Use ALU result, 1: Use memory data
    
    // PC control signals
    output [2:0]  ccc,             // Branch condition code
    
    // Individual flag control signals
    output        en_Z,            // Enable Zero flag update
    output        en_V,            // Enable Overflow flag update
    output        en_N,            // Enable Negative flag update
    
    // Special path control
    output        PCToReg,         // 0: Use result from MemToReg, 1: Use PC+2

    // Branch related outputs
    output        BranchTaken,
    output        is_b_instr,
    output        is_br_instr,
    
    // HLT
    output        HLT              // Halt signal
);

    // Extract opcode and condition code from instruction
    wire [3:0] opcode;
    assign opcode = instr[15:12];
    assign ccc    = instr[11:9];

    // Instruction type constants
    parameter ADD     = 4'b0000;
    parameter SUB     = 4'b0001;
    parameter XOR     = 4'b0010;
    parameter RED     = 4'b0011;
    parameter SLL     = 4'b0100;
    parameter SRA     = 4'b0101;
    parameter ROR     = 4'b0110;
    parameter PADDSB  = 4'b0111;
    parameter LW      = 4'b1000;
    parameter SW      = 4'b1001;
    parameter LLB     = 4'b1010;
    parameter LHB     = 4'b1011;
    parameter B       = 4'b1100;
    parameter BR      = 4'b1101;
    parameter PCS     = 4'b1110;
    parameter HLT_OP  = 4'b1111;
    
    // Determine instruction types
    wire is_arith, is_shift, is_mem_load, is_mem_store, is_branch, is_pcs, is_hlt;
    wire is_ld_imm;
    wire branch_cond;  
    
    assign is_arith = (opcode == ADD) | (opcode == SUB) | (opcode == XOR) | 
                      (opcode == RED) | (opcode == PADDSB);
    assign is_shift     = (opcode == SLL) | (opcode == SRA) | (opcode == ROR);
    assign is_ld_imm       = (opcode == LLB) | (opcode == LHB);
    assign is_mem_load  = (opcode == LW) | is_ld_imm;
    assign is_mem_store = (opcode == SW);
    assign is_branch    = (opcode == B) | (opcode == BR);
    assign is_br_instr  = (opcode == BR);
    assign is_pcs       = (opcode == PCS);
    assign is_hlt       = (opcode == HLT_OP);
    
    // Register addressing
    assign SrcReg1 = is_ld_imm ? instr[11:8] : instr[7:4];
    assign SrcReg2 = (opcode == SW) ? instr[11:8] : instr[3:0];
    assign DstReg  = instr[11:8];

    // Generate control signals
    // Register Write: active for arithmetic, shift, memory load, and PCS instructions
    assign RegWrite = is_arith | is_shift | is_mem_load | is_pcs;
    
    // ALU Operation: use ADD for memory operations and branch, else use opcode directly
    assign ALUOp = ((opcode == SW) || (opcode == LW) || (opcode == B) || (opcode == BR)) ? ADD : opcode;
    
    // ALU Sources
    assign ALUSrc_1  = (opcode == B); 
    assign ALUSrc_2  = is_shift | is_mem_load | is_mem_store | (opcode == B);
    
    // Immediate choice configuration
    assign ImdChoice = {is_ld_imm, (opcode == LW) | (opcode == SW) | is_ld_imm | is_shift};
    
    // Memory access controls
    assign MemRead  = (opcode == LW);
    assign MemWrite = is_mem_store;
    assign MemToReg = (opcode == LW);
    
    // PC control
    assign is_b_instr = (opcode == B);
    
    // Individual flag enables:
    // - ADD and SUB update all flags (Z, V, N)
    // - XOR, SLL, SRA, ROR update only the Zero flag.
    assign en_Z = (opcode == ADD) | (opcode == SUB) | (opcode == XOR) | 
                  (opcode == SLL) | (opcode == SRA) | (opcode == ROR);
    assign en_V = (opcode == ADD) | (opcode == SUB);
    assign en_N = (opcode == ADD) | (opcode == SUB);
    
    // Special path: PC to Register for PCS instruction
    assign PCToReg = is_pcs;
    
    // Halt: active for HLT instruction
    assign HLT = is_hlt;

    // Branch condition evaluation logic using combinational logic with ternary operators
    // NEQ (Z = 0)
    wire cond_NEQ = ~Z_flag;
    // EQ (Z = 1)
    wire cond_EQ = Z_flag;
    // GT (Z = N = 0)
    wire cond_GT = ~Z_flag & ~N_flag;
    // LT (N = 1)
    wire cond_LT = N_flag;
    // GTE (Z = 1 or Z = N = 0)
    wire cond_GTE = Z_flag | (~Z_flag & ~N_flag);
    // LTE (N = 1 or Z = 1)
    wire cond_LTE = N_flag | Z_flag;
    // OVFL (V = 1)
    wire cond_OVFL = V_flag;
    // UNCOND (always)
    wire cond_UNCOND = 1'b1;

    // Select branch condition based on ccc
    assign branch_cond = is_branch ?
        (ccc == 3'b000) ? cond_NEQ :
        (ccc == 3'b001) ? cond_EQ :
        (ccc == 3'b010) ? cond_GT :
        (ccc == 3'b011) ? cond_LT :
        (ccc == 3'b100) ? cond_GTE :
        (ccc == 3'b101) ? cond_LTE :
        (ccc == 3'b110) ? cond_OVFL :
        (ccc == 3'b111) ? cond_UNCOND :
        1'b0 : 1'b0;

    assign BranchTaken = is_branch & branch_cond;
     
endmodule
