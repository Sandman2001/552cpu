module DECODE(
    // Clock and reset
    input clk,
    input rst_n,
    
    // Instruction input
    input [15:0] instruction,

    // PC input
    input [15:0] PC_plus_2,
    
    input [15:0] WriteRegData_Ext, // External write data
    
    // Flag register inputs
    input Z_flag,                  // Zero flag
    input N_flag,                  // Negative flag
    input V_flag,                  // Overflow flag

    // Read from EX/MEM register
    input EX_MEM_ReadMem,               // MemRead from prev instr to check for load
    input [3:0] EX_MEM_RS,
    input [3:0] EX_MEM_RT,
    
    input [3:0] EX_MEM_RD,
    
    // ALU inputs
    output [15:0] ALU_input_1,     // ALU input 1
    output [15:0] ALU_input_2,     // ALU input 2

    // Input into EX/MEM
    output [3:0] RS,
    output [3:0] RT,
    output [3:0] RD,

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
    wire is_b_instr;
    wire [2:0] ccc;
    wire [15:0] SrcData1;
    wire [15:0] SrcData2;
    wire [15:0] ImmExt;
    wire stall;
    
    // Detect branch instruction types
    assign is_b_instr = (instruction[15:12] == 4'b1100);   // B instruction

    assign RS = SrcReg1;
    assign RT = SrcReg2;
    assign RD = DstReg;
    
    // Instantiate control unit
    control_unit ctrl(
        .instr(instruction),
        .Z_flag(Z_flag),              
        .N_flag(N_flag),                
        .V_flag(V_flag),               
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
        .PCToReg(PCToReg),
        .HLT(HLT),
        .ccc(ccc),
        .en_Z(en_Z),
        .en_N(en_N),
        .en_V(en_V),
        .BranchTaken(BranchTaken),
        .is_b_instr(is_b_instr),
        .is_br_instr(is_br_instr)
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
        .SrcData1(SrcData1),
        .SrcData2(SrcData2)
    );

    // Instantiate instruction processor for immediate extension
    imm_proc imm_proc_inst(
        .mem_instruction(instruction),
        .imd_choice(ImdChoice),    // Direct connection to control unit output
        .se_instruction(ImmExt)
    );

    // Calculate branch address for B instruction using Addr_Shifter
    wire [15:0] B_target_addr;
    Addr_Shifter branch_adder(
        .A(ImmExt),            // Shifted immediate value
        .B(PC_plus_2),             // PC+2
        .S(B_target_addr)          // Branch target address
    );

    data_hazard stall_calc(
    .EX_MEM_ReadMem(EX_MEM_ReadMem),    
    .RS(RS),                
    .RT(RT),                
    .EX_MEM_RD(EX_MEM_RD),         
    .is_br_instr(is_br_instr),         
    .stall(stall)              
    );

    
    
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