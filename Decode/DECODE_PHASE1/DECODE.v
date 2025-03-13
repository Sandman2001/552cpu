module DECODE(
    // Clock and reset
    input clk,
    input rst_n,
    
    // Instruction input
    input [15:0] instruction,

    // PC input
    input [15:0] PC_plus_2,
    
    // Register write back (from later pipeline stage)
    input [15:0] WriteRegData_Ext, // External write data
    
    // Flag register inputs
    input Z_flag,                  // Zero flag
    input N_flag,                  // Negative flag
    input V_flag,                  // Overflow flag
    
    // ALU inputs
    output [15:0] ALU_input_1,     // ALU input 1
    output [15:0] ALU_input_2,     // ALU input 2

    // Individual flag control signals
    output        en_Z,            // Enable Zero flag update
    output        en_V,            // Enable Overflow flag update
    output        en_N,            // Enable Negative flag update
    
    // Control signals output
    output [3:0] ALUOp,            // ALU operation
    output MemRead,                // Memory read enable
    output MemWrite,               // Memory write enable
    output MemToReg,               // Select between ALU result and memory data
    output BranchTaken,            // Branch condition satisfied
    output [15:0] BranchAddr,      // Branch target address
    output HLT,                     // Halt signal
    output [15:0] SW_data                  // SW DATA
);

    // Internal wires for register file and control signals
    wire [3:0] SrcReg1, SrcReg2, DstReg;
    wire [1:0] ImdChoice;
    wire RegWrite;
    wire ALUSrc_1, ALUSrc_2;
    wire PCToReg;
    wire [15:0] WriteRegData;
    wire [15:0] ShiftedImm;        // Immediate value shifted left by 1 bit
    wire is_b_instr, is_br_instr;  // Instruction type signals
    wire branch_cond;              // Branch condition result
    wire [2:0] ccc;
    wire [15:0] SrcData1;
    wire [15:0] SrcData2;
    wire [15:0] ImmExt;
    
    // Detect branch instruction types
    assign is_b_instr = (instruction[15:12] == 4'b1100);   // B instruction
    assign is_br_instr = (instruction[15:12] == 4'b1101);  // BR instruction
    
    // Instantiate control unit
    control_unit ctrl(
        .instr(instruction),
        .SrcReg1(SrcReg1),
        .SrcReg2(SrcReg2),
        .DstReg(DstReg),
        .RegWrite(RegWrite),       
        .ALUOp(ALUOp),
        .ALUSrc_1(ALUSrc_1),
        .ALUSrc_2(ALUSrc_2),
        .ImdChoice(ImdChoice),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemToReg(MemToReg),
        .BranchEn(BranchEn),
        .PCToReg(PCToReg),
        .HLT(HLT),
        .ccc(ccc),
        .en_Z(en_Z),
        .en_N(en_N),
        .en_V(en_V),
        .disable_bypass(disable_bypass),
        .shft(shft)
    );

    // Instantiate register file
    RegisterFile regfile(
        .clk(clk),
        .rst(~rst_n),
        .SrcReg1(SrcReg1),
        .SrcReg2(SrcReg2),
        .DstReg(DstReg),    
        .WriteReg(RegWrite),       // Use external write enable
        .DstData(WriteRegData),    // Use external write data
        .disable_bypass(disable_bypass),
        .SrcData1(SrcData1),
        .SrcData2(SrcData2)
    );

    // Instantiate instruction processor for immediate extension
    imm_proc imm_proc_inst(
        .mem_instruction(instruction),
        .imd_choice(ImdChoice),    // Direct connection to control unit output
        .shft(shft),
        .se_instruction(ImmExt)
    );
    
    wire [15:0] Imm_br;
    assign Imm_br = {{7{instruction[8]}}, instruction[8:0]} << 1;

    // Calculate branch address for B instruction using Addr_Shifter
    wire [15:0] B_target_addr;
    Addr_Shifter branch_adder(
        .A(Imm_br),            // Shifted immediate value
        .B(PC_plus_2),             // PC+2
        .S(B_target_addr)          // Branch target address
    );
    
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
    assign branch_cond = 
        (ccc == 3'b000) ? cond_NEQ :
        (ccc == 3'b001) ? cond_EQ :
        (ccc == 3'b010) ? cond_GT :
        (ccc == 3'b011) ? cond_LT :
        (ccc == 3'b100) ? cond_GTE :
        (ccc == 3'b101) ? cond_LTE :
        (ccc == 3'b110) ? cond_OVFL :
        (ccc == 3'b111) ? cond_UNCOND :
        1'b0;
    
    // Branch is taken if BranchEn is active and condition is satisfied
    assign BranchTaken = BranchEn & branch_cond;
    
    // Select branch target address based on instruction type
    // For B: Use calculated target address
    // For BR: Use register value (rs)
    assign BranchAddr = is_b_instr ? B_target_addr : SrcData1;
    
    // Signal assignments
    assign WriteRegData = PCToReg ? PC_plus_2 : WriteRegData_Ext;
    assign ALU_input_1 = ALUSrc_1 ? PC_plus_2 : SrcData1;
    assign ALU_input_2 = ALUSrc_2 ? ImmExt : SrcData2;
    assign SW_data = SrcData2;

endmodule