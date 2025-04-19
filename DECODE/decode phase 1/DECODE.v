module DECODE(
    // Clock and reset
    input clk,
    input rst_n,
    
    // Instruction and PC inputs
    input [15:0] instruction,
    input [15:0] PC_plus_2,
    
    input [15:0] WriteRegData_Ext, // External write data
    
    // Flag register inputs
    input Z_flag,                  // Zero flag
    input N_flag,                  // Negative flag
    input V_flag,                  // Overflow flag

    // Read from EX/MEM register
    input EX_MEM_ReadMem,          // MemRead from previous instruction
    input [3:0] EX_MEM_RS,
    input [3:0] EX_MEM_RT,
    input [3:0] EX_MEM_RD,
    input stall_out,
    input WriteDstReg,
    input in_RegWrite,
    
    // Flush signals
    input flush_out,               // When 1, flush the current decode outputs
    output flush_in,               // To inform FETCH to flush next instr (set when branch taken)
    
    // ALU inputs
    output [15:0] ALU_input_1,     // ALU input 1
    output [15:0] ALU_input_2,     // ALU input 2

    // Inputs into EX/MEM stage
    output [3:0] RS,
    output [3:0] RT,
    output [3:0] RD,

    output        en_Z,            // Enable Zero flag update
    output        en_V,            // Enable Overflow flag update
    output        en_N,            // Enable Negative flag update
    
    // Control signals output
    output [3:0] ALUOp,            // ALU operation
    output        MemRead,          // Memory read enable
    output        MemWrite,         // Memory write enable
    output        MemToReg,         // Select between ALU result and memory data
    output        RegWrite,
    output        BranchTaken,      // Branch condition satisfied
    output [15:0] BranchAddr,       // Branch target address
    output        HLT,              // Halt signal
    output        stall_in,         // Stall signal to prior pipeline stage
    output [15:0] SW_data           // SW DATA
);

    //-------------------------------------------------------------------------
    // Internal wires for register file and control signals
    //-------------------------------------------------------------------------
    wire [3:0] SrcReg1, SrcReg2, DstReg;
    wire [1:0] ImdChoice;
    wire ALUSrc_1, ALUSrc_2;
    wire PCToReg;
    wire [15:0] WriteRegData;
    wire is_b_instr;
    wire [2:0] ccc;
    wire [15:0] SrcData1;
    wire [15:0] SrcData2;
    wire [15:0] ImmExt;
    wire stall;

    //-------------------------------------------------------------------------
    // Flush logic: If flush_out is high, all control and data outputs become zero. 
    // We are flushing the current instruction.
    //-------------------------------------------------------------------------
    
    // For outputs computed from the register file and immediate unit,
    // first compute the raw value then condition it with flush_out.
    assign is_b_instr = (instruction[15:12] == 4'b1100);

    //-------------------------------------------------------------------------
    // Instantiate control unit (rename its control outputs to raw_* so we can condition them)
    wire raw_en_Z, raw_en_N, raw_en_V;
    wire [3:0] raw_ALUOp;
    wire raw_MemRead, raw_MemWrite, raw_MemToReg;
    wire raw_BranchTaken;
    wire raw_HLT;
    wire is_br_instr;
    
    control_unit ctrl(
        .instr(instruction),
        .Z_flag(Z_flag),              
        .N_flag(N_flag),                
        .V_flag(V_flag),               
        .SrcReg1(SrcReg1),
        .SrcReg2(SrcReg2),
        .DstReg(DstReg),
        .RegWrite(RegWrite),       
        .ALUOp(raw_ALUOp),
        .ALUSrc_1(ALUSrc_1),
        .ALUSrc_2(ALUSrc_2),
        .ImdChoice(ImdChoice),
        .MemRead(raw_MemRead),
        .MemWrite(raw_MemWrite),
        .MemToReg(raw_MemToReg),
        .PCToReg(PCToReg),
        .HLT(raw_HLT),
        .ccc(ccc),
        .en_Z(raw_en_Z),
        .en_N(raw_en_N),
        .en_V(raw_en_V),
        .BranchTaken(raw_BranchTaken),
        .is_b_instr(is_b_instr),
        .is_br_instr(is_br_instr)
    );

    //-------------------------------------------------------------------------
    // Instantiate register file
    //-------------------------------------------------------------------------
    RegisterFile regfile(
        .clk(clk),
        .rst(~rst_n),
        .SrcReg1(SrcReg1),
        .SrcReg2(SrcReg2),
        .DstReg(WriteDstReg),    
        .WriteReg(in_RegWrite),       
        .DstData(WriteRegData),    
        .SrcData1(SrcData1),
        .SrcData2(SrcData2)
    );

    //-------------------------------------------------------------------------
    // Immediate extension unit
    //-------------------------------------------------------------------------
    imm_proc imm_proc_inst(
        .mem_instruction(instruction),
        .imd_choice(ImdChoice),
        .se_instruction(ImmExt)
    );

    //-------------------------------------------------------------------------
    // Calculate branch target address for B instruction using Addr_Shifter
    //-------------------------------------------------------------------------
    wire [15:0] B_target_addr;
    Addr_Shifter branch_adder(
        .A(ImmExt),         // Immediate extended and shifted value
        .B(PC_plus_2),      // PC+2
        .S(B_target_addr)   // Branch target address
    );

    //-------------------------------------------------------------------------
    // Data hazard stall calculation
    //-------------------------------------------------------------------------
    data_hazard stall_calc(
        .EX_MEM_ReadMem(EX_MEM_ReadMem),    
        .RS(RS),                
        .RT(RT),                
        .EX_MEM_RD(EX_MEM_RD),         
        .is_br_instr(is_br_instr),         
        .stall(stall)
    );
    
    assign stall_in  = stall_out ? 1'b0 : stall;
    
    //-------------------------------------------------------------------------
    // Combinational assignments with flush conditioning
    //-------------------------------------------------------------------------
    
    // WriteRegData is internal (used only in register file write-back)
    assign WriteRegData = PCToReg ? PC_plus_2 : WriteRegData_Ext;
    
    // ALU inputs
    wire [15:0] raw_ALU_input_1 = ALUSrc_1 ? PC_plus_2 : SrcData1;
    wire [15:0] raw_ALU_input_2 = ALUSrc_2 ? ImmExt  : SrcData2;
    
    assign ALU_input_1 = flush_out ? 16'b0 : raw_ALU_input_1;
    assign ALU_input_2 = flush_out ? 16'b0 : raw_ALU_input_2;
    
    // SW data
    assign SW_data = flush_out ? 16'b0 : SrcData2;
    
    // Branch Address: For B instruction, use calculated target; for BR, use SrcData1.
    wire [15:0] raw_BranchAddr = is_b_instr ? B_target_addr : SrcData1;
    assign BranchAddr = flush_out ? 16'b0 : raw_BranchAddr;
    
    // Register specifiers
    assign RS = flush_out ? 4'b0 : SrcReg1;
    assign RT = flush_out ? 4'b0 : SrcReg2;
    assign RD = flush_out ? 4'b0 : DstReg;
    
    // Control signals from the control unit
    assign en_Z        = flush_out ? 1'b0 : raw_en_Z;
    assign en_N        = flush_out ? 1'b0 : raw_en_N;
    assign en_V        = flush_out ? 1'b0 : raw_en_V;
    assign ALUOp       = flush_out ? 4'b0  : raw_ALUOp;
    assign MemRead     = flush_out ? 1'b0 : raw_MemRead;
    assign MemWrite    = flush_out ? 1'b0 : raw_MemWrite;
    assign MemToReg    = flush_out ? 1'b0 : raw_MemToReg;
    assign BranchTaken = flush_out ? 1'b0 : raw_BranchTaken;
    assign HLT         = flush_out ? 1'b0 : raw_HLT;
    
    //-------------------------------------------------------------------------
    // Flush signal to FETCH: When a branch is taken, we set flush_in to 1.
    // This is independent of flush_out.
    //-------------------------------------------------------------------------
    assign flush_in = raw_BranchTaken;

endmodule
