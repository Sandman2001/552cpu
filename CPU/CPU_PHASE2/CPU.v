module cpu(
    input         clk,       
    input         rst_n,     
    output        hlt,       // Halt signal now comes from IF/ID
    output [15:0] pc         // Current PC (from FETCH; for debugging)
);

    // Global Stall Signal (unchanged)
    wire stall_global;
    assign stall_global = 1'b0;

    wire [15:0] forwarded_ALU_in1;
    wire [15:0] forwarded_ALU_in2;
    wire [15:0] forwarded_SW_data;

    wire [1:0] ForwardA, ForwardB;
    wire       ForwardMem;
    wire       dec_HLT, idex_HLT, exmem_HLT, memwb_HLT;

    //------------------------------------------------------------------------
    // FETCH Stage (Updated to use IF/ID branch/hlt feedback)
    //------------------------------------------------------------------------
    wire [15:0] instruction;
    wire [15:0] PC;
    wire [15:0] PC_plus_two;
    wire [15:0] exmem_SW_data;
    wire [15:0] WriteRegData_Ext;
    wire [15:0] out_SW_data;
    wire [3:0] idex_RS;
    wire [3:0] idex_RT;
    wire [3:0] idex_RD;
    wire [3:0] in_RT;
    wire [3:0] ID_EX_Rt;
    wire [3:0] ID_EX_Rs;
    wire [15:0] SW_data;
    wire [15:0] idex_SW_data;
    wire [3:0]  memwb_DstReg;
    wire        memwb_RegWrite;
    wire [15:0] mem_out;
    wire [15:0] alu_result;
    
    // Wires from IF/ID register feedback
    wire [15:0] ifid_branch_addr;
    wire        ifid_branch_taken;
    wire        ifid_hlt;
    
    fetch fetch_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .branch_flag  (ifid_branch_taken),
        .branch_target(ifid_branch_addr),
        .stall        (stall_global),
        .instruction  (instruction),
        .PC           (PC),
        .PC_plus_two  (PC_plus_two)
    );

    //------------------------------------------------------------------------
    // IF/ID Pipeline Register (Updated)
    //------------------------------------------------------------------------
    wire [15:0] ifid_PC_out;
    wire [15:0] ifid_instr_out;
    wire        ifid_stall_out;
    wire        ifid_flush_out;
    wire [15:0] BranchAddr_feedback;
    wire        dec_flush_out;
    
    IF_ID_reg if_id_reg_inst (
        .PC_plus_2_in   (PC_plus_two),
        .PC_current_in  (PC),
        .instr_in       (instruction),
        // New feedback inputs from DECODE
        .branch_addr_in (BranchAddr_feedback),  
        .branch_taken_in(BranchTaken_feedback),
        .hlt_in         (dec_HLT),
        .flush_in       (dec_flush_out),         
        .stall_in       (stall_global),
        .clk            (clk),
        .rst_n          (rst_n),
        .stall_out      (ifid_stall_out),
        .flush_out      (ifid_flush_out),
        .PC_reg_out     (ifid_PC_out),
        .instr_reg_out  (ifid_instr_out),
        .branch_addr_reg_out(ifid_branch_addr),
        .branch_taken_reg_out(ifid_branch_taken),
        .hlt_reg_out    (ifid_hlt)
    );

    //------------------------------------------------------------------------
    // DECODE Stage (Updated to drive feedback signals)
    //------------------------------------------------------------------------
    // DECODE now outputs BranchAddr, BranchTaken, and HLT for feedback.
    wire [15:0] ALU_input_1, ALU_input_2;
    wire [3:0]  dec_RS, dec_RT, dec_RD;
    wire        en_Z, en_V, en_N;
    wire [3:0]  ALUOp;
    wire        MemRead, MemWrite, MemToReg;
    wire        dec_stall_out;
    wire        dec_RegWrite;
    wire [3:0]  idex_ALUOp;
    wire [15:0] wb_data;
    wire        dec_Ovfl, dec_Zero, dec_Neg;

    DECODE decode_inst (
        .clk               (clk),
        .rst_n             (rst_n),
        .instruction       (ifid_instr_out),
        .PC_plus_2         (ifid_PC_out),
        .WriteRegData_Ext  (wb_data),
        .Z_flag            (exe_Zero),
        .N_flag            (exe_Neg),
        .V_flag            (exe_Ovfl),
        .EX_MEM_ReadMem    (idex_MemRead),
        .EX_MEM_RS         (idex_RS),
        .EX_MEM_RT         (idex_RT),
        .EX_MEM_RD         (idex_RD),
        .WriteDstReg       (memwb_DstReg),
        .stall_out         (ifid_stall_out),
        .flush_out         (ifid_flush_out),
        .flush_in          (dec_flush_out),
        .ALU_input_1       (ALU_input_1),
        .ALU_input_2       (ALU_input_2),
        .RS                (dec_RS),
        .RT                (dec_RT),
        .RD                (dec_RD),
        .en_Z              (en_Z),
        .en_V              (en_V),
        .en_N              (en_N),
        .ALUOp             (ALUOp),
        .MemRead           (MemRead),
        .MemWrite          (MemWrite),
        .MemToReg          (MemToReg),
        .BranchTaken       (BranchTaken_feedback),
        .BranchAddr        (BranchAddr_feedback),
        .HLT               (dec_HLT),
        .stall_in          (dec_stall_out),
        .SW_data           (SW_data),
        .RegWrite          (dec_RegWrite),
        .in_RegWrite       (memwb_RegWrite),
        .halted            (ifid_hlt)
    );

    wire [15:0] idex_ALU_in1;
    wire [15:0] idex_ALU_in2;

    //------------------------------------------------------------------------
    // ID/EX, EX/MEM, MEM/WB Pipeline Registers (Updated)
    //------------------------------------------------------------------------
    // Remove propagation of HLT downstream – set HLT inputs to 0.
    ID_EX id_ex_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .flush(dec_flush_out),
        .in_ALU_in1(ALU_input_1),
        .in_ALU_in2(ALU_input_2),
        .in_SW_data(SW_data),
        .in_en_Z(en_Z),
        .in_en_V(en_V),
        .in_en_N(en_N),
        .in_MemToReg(MemToReg),
        .in_MemRead(MemRead),
        .in_MemWrite(MemWrite),
        .in_ALUOp(ALUOp),
        .in_RS(dec_RS),
        .in_RT(dec_RT),
        .in_RD(dec_RD),
        .in_HLT(dec_HLT),
        .out_ALU_in1(idex_ALU_in1),
        .out_ALU_in2(idex_ALU_in2),
        .out_SW_data(idex_SW_data),
        .out_en_Z(idex_en_Z),
        .out_en_V(idex_en_V),
        .out_en_N(idex_en_N),
        .out_MemToReg(idex_MemToReg),
        .out_MemRead(idex_MemRead),
        .out_MemWrite(idex_MemWrite),
        .out_ALUOp(idex_ALUOp),
        .out_RS(idex_RS),
        .out_RT(idex_RT),
        .out_RD(idex_RD),
        .in_RegWrite(dec_RegWrite),
        .out_RegWrite(idex_RegWrite),
        .in_Ovfl(exe_Ovfl),
        .in_Neg(exe_Neg),
        .in_Zero(exe_Zero),
        .out_Ovfl(dec_Ovfl),
        .out_Neg(dec_Neg),
        .out_Zero(dec_Zero),
        .out_HLT(idex_HLT)
    );

    //-------------------------------------------------------------------------
    // Execute Stage
    //-------------------------------------------------------------------------
    Execute execute_inst (
        .ALU_In1(forwarded_ALU_in1),
        .ALU_In2(forwarded_ALU_in2),
        .Opcode(idex_ALUOp),
        .ALU_Out(alu_result),
        .Ovfl(exe_Ovfl),
        .Neg(exe_Neg),
        .Zero(exe_Zero),
        .en_Z(idex_en_Z),
        .en_N(idex_en_N),
        .en_V(idex_en_V),
        .clk(clk),
        .rst_n(rst_n)
    );


    //-------------------------------------------------------------------------
    // EX/MEM Pipeline Register
    //-------------------------------------------------------------------------
    // Now stores the RT field from ID/EX (for forwarding).
    wire [15:0] exmem_ALU_result;
    wire        exmem_MemWrite, exmem_MemRead, exmem_MemToReg, exmem_RegWrite;
    wire [3:0]  exmem_DstReg, exmem_RT;
    EX_MEM ex_mem_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_ALU_result(alu_result), 
        .in_SW_data(idex_SW_data),
        .in_MemWrite(idex_MemWrite),
        .in_MemRead(idex_MemRead),
        .in_MemToReg(idex_MemToReg),
        .in_RegWrite(idex_RegWrite),
        .in_HLT(idex_HLT),
        .in_DstReg(idex_RD),           // Destination register from DECODE
        .in_RT(idex_RT),               // RT from ID/EX for forwarding
        .out_ALU_result(exmem_ALU_result),
        .out_SW_data(exmem_SW_data),
        .out_MemWrite(exmem_MemWrite),
        .out_MemRead(exmem_MemRead),
        .out_MemToReg(exmem_MemToReg),
        .out_RegWrite(exmem_RegWrite),
        .out_DstReg(exmem_DstReg),
        .out_RT(exmem_RT),
        .out_HLT(exmem_HLT)
    );

    //-------------------------------------------------------------------------
    // Data Memory
    //-------------------------------------------------------------------------
    memory1c data_memory (
        .data_out(mem_out),
        .data_in(forwarded_SW_data),
        .addr(alu_result),
        .enable(idex_MemRead | idex_MemWrite),
        .wr(idex_MemWrite & (~idex_MemRead)),
        .clk(clk),
        .rst(~rst_n)
    );

    //-------------------------------------------------------------------------
    // MEM/WB Pipeline Register
    //-------------------------------------------------------------------------
    wire [15:0] memwb_ALU_result, memwb_memData;
    wire        memwb_MemToReg;

    MEM_WB mem_wb_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_ALU_result(exmem_ALU_result),
        .in_memData(mem_out),  // For load instructions, data read from memory
        .in_MemToReg(exmem_MemToReg),
        .in_RegWrite(exmem_RegWrite),
        .in_HLT(exmem_HLT),
        .in_DstReg(exmem_DstReg),
        .out_ALU_result(memwb_ALU_result),
        .out_memData(memwb_memData),
        .out_MemToReg(memwb_MemToReg),
        .out_RegWrite(memwb_RegWrite),
        .out_DstReg(memwb_DstReg),
        .out_HLT(memwb_HLT)
    );

    //-------------------------------------------------------------------------
    // Writeback Stage
    //-------------------------------------------------------------------------
    Writeback writeback_inst (
        .memData(memwb_memData),
        .ALU_out(memwb_ALU_result),
        .memToReg(memwb_MemToReg),
        .regWriteData(wb_data)
    );

    //-------------------------------------------------------------------------
    // Forwarding Muxes for ALU Inputs
    //-------------------------------------------------------------------------
    assign forwarded_ALU_in1 = (ForwardA == 2'b10) ? exmem_ALU_result :
                               (ForwardA == 2'b01) ? wb_data : idex_ALU_in1;
    assign forwarded_ALU_in2 = (ForwardB == 2'b10) ? exmem_ALU_result :
                               (ForwardB == 2'b01) ? wb_data : idex_ALU_in2;
    assign forwarded_SW_data = ForwardMem ? wb_data : exmem_SW_data;

    //-------------------------------------------------------------------------
    // Forwarding Unit
    //-------------------------------------------------------------------------

    ForwardingUnit forward_unit (
        .MEM_WB_RegWrite(memwb_RegWrite),
        .EX_MEM_RegWrite(exmem_RegWrite),
        .ID_EX_MemWrite(idex_MemWrite),
        .MEM_WB_Rd(memwb_DstReg),
        .EX_MEM_Rd(exmem_DstReg),
        .EX_MEM_Rt(exmem_RT),
        .ID_EX_Rt(idex_RT),
        .ID_EX_Rs(idex_RS),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardMem(ForwardMem),
        .ALU_OpCode(idex_ALUOp)
    );

    //-------------------------------------------------------------------------
    // Top-Level Output Assignment
    //-------------------------------------------------------------------------
    assign pc = PC;        // Current PC from FETCH (for debugging)
    assign hlt = memwb_HLT;   // Halt signal from ID/EX stage

endmodule
