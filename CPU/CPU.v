/**
 * CPU Top Module with 5-Stage Pipeline, Forwarding, and Cache Controller
 */
module cpu (
    input         clk,    // System clock
    input         rst_n,  // Active low reset
    output        hlt,    // Halt signal (pipelined)
    output [15:0] pc      // Current program counter (from FETCH; for debugging)
);

    //-------------------------------------------------------------------------
    // Signal Declarations
    //-------------------------------------------------------------------------
    wire rst = ~rst_n; // Active high reset for internal use

    // --- Pipeline Stall Signals ---
    wire icache_stall;         // Stall signal from I-Cache controller
    wire dcache_stall;         // Stall signal from D-Cache controller
    wire stall_pipeline;       // Combined stall for pipeline registers & PC update
    assign stall_pipeline = icache_stall | dcache_stall;

    // --- Forwarding Signals ---
    wire [15:0] forwarded_ALU_in1;
    wire [15:0] forwarded_ALU_in2;
    wire [15:0] forwarded_SW_data; // Data forwarded for Store Word
    wire [1:0]  ForwardA, ForwardB; // Control signals from Forwarding Unit
    wire        ForwardMem;         // Control signal for SW data forwarding

    // --- Pipeline Stage Signals ---

    // FETCH <-> Cache Controller / IF_ID
    wire [15:0] fetch_PC;             // PC value from Fetch stage
    wire [15:0] fetch_PC_plus_two;    // PC + 2 calculated in Fetch
    wire [15:0] icache_data_out;      // Instruction data from I-Cache

    // IF/ID Register Outputs / Feedback
    wire [15:0] ifid_PC_plus_two_out; // Pipelined PC + 2 (PC_reg_out in original)
    wire [15:0] ifid_instruction;     // Pipelined instruction (instr_reg_out in original)
    wire        ifid_stall_out;       // Pipelined stall signal (unused?)
    wire        ifid_flush_out;       // Pipelined flush signal
    wire [15:0] ifid_branch_addr;     // Pipelined branch address feedback for Fetch
    wire        ifid_branch_taken;    // Pipelined branch taken feedback for Fetch
    wire        ifid_hlt;             // Pipelined HLT feedback for Fetch/Decode

    // DECODE Outputs -> ID/EX Register Inputs / Feedback
    wire [15:0] dec_ALU_input_1;
    wire [15:0] dec_ALU_input_2;
    wire [3:0]  dec_RS, dec_RT, dec_RD; // Register specifiers
    wire        dec_RegWrite;         // Register write enable signal
    wire        dec_en_Z, dec_en_V, dec_en_N; // Flag enables
    wire [3:0]  dec_ALUOp;
    wire        dec_MemRead;
    wire        dec_MemWrite;
    wire        dec_MemToReg;
    wire [15:0] dec_BranchAddr_feedback; // Branch address feedback to IF/ID
    wire        dec_BranchTaken_feedback;// Branch taken feedback to IF/ID
    wire        dec_HLT;              // Halt signal generated in Decode (feedback to IF/ID)
    wire        dec_stall_out;        // Stall signal from Decode (unused?)
    wire        dec_flush_out;        // Flush signal from Decode to IF/ID
    wire [15:0] dec_SW_data;          // Data for Store Word

    // ID/EX Register Outputs -> EXECUTE Inputs / EX_MEM Inputs
    wire [15:0] idex_ALU_in1;
    wire [15:0] idex_ALU_in2;
    wire [15:0] idex_SW_data;
    wire        idex_en_Z, idex_en_V, idex_en_N;
    wire        idex_MemToReg;
    wire        idex_MemRead;
    wire        idex_MemWrite;
    wire [3:0]  idex_ALUOp;
    wire [3:0]  idex_RS, idex_RT, idex_RD; // Pipelined register specifiers
    wire        idex_RegWrite;
    wire        idex_Ovfl_in, idex_Neg_in, idex_Zero_in; // Flags coming into ID/EX (from EXE)
    wire        idex_Ovfl_out, idex_Neg_out, idex_Zero_out; // Flags going out (to DEC)
    wire        idex_HLT;

    // EXECUTE Outputs -> EX/MEM Register Inputs
    wire [15:0] ex_ALU_result;
    wire        ex_Ovfl, ex_Neg, ex_Zero; // Flags calculated in Execute

    // EX/MEM Register Outputs -> MEM Inputs / MEM_WB Inputs
    wire [15:0] exmem_ALU_result;
    wire [15:0] exmem_SW_data;        // Pipelined Store Word data
    wire        exmem_MemWrite;
    wire        exmem_MemRead;
    wire        exmem_MemToReg;
    wire        exmem_RegWrite;
    wire [3:0]  exmem_DstReg;         // Destination register address (was RD)
    wire [3:0]  exmem_RT;             // Pipelined RT (for forwarding)
    wire        exmem_HLT;

    // MEM (Cache Controller Interaction) -> MEM/WB Register Inputs
    wire [15:0] dcache_data_out;      // Data read from D-Cache

    // MEM/WB Register Outputs -> Writeback Stage Inputs
    wire [15:0] memwb_ALU_result;
    wire [15:0] memwb_memData;        // Data read from D-Cache (pipelined)
    wire        memwb_MemToReg;
    wire        memwb_RegWrite;
    wire [3:0]  memwb_DstReg;         // Final destination register address
    wire        memwb_HLT;

    // Writeback Stage Output -> Register File Write / Decode Forwarding
    wire [15:0] wb_WriteData;         // Final data selected for register write


    //-------------------------------------------------------------------------
    // Module Instantiations
    //-------------------------------------------------------------------------

    // --- Cache Controller ---
    // Handles I-Cache and D-Cache access, memory interaction, and stalling


    CacheController cache_ctrl (
        .clk(clk),
        .rst(rst), // Controller uses active high reset

        // D-Cache Interface (from/to MEM stage - uses EX/MEM outputs)
        .memRead(exmem_MemRead),     // Read request from EX/MEM reg
        .memWrite(exmem_MemWrite),   // Write request from EX/MEM reg
        .mem_addr(exmem_ALU_result),   // Address from EX/MEM reg (ALU result)
        .memDataIn(exmem_SW_data),      // Data to write from EX/MEM reg
        .memDataOut(dcache_data_out),   // Data read result to MEM/WB reg input
        .dcache_stall(dcache_stall),      // Stall signal back to pipeline control

        // I-Cache Interface (from/to FETCH stage)
        .ins_addr(fetch_PC),           // Address from Fetch stage
        .instDataOut(icache_data_out),   // Instruction data back to Fetch
        .icache_stall(icache_stall)       // Stall signal back to pipeline control
    );


    // --- Pipeline Stages ---

    // FETCH: Generate PC, request instruction from I-Cache via controller.
    // Assumes fetch module is modified:
    // - Takes instruction via 'instruction_in' port.
    // - Takes stall signal 'stall_in' to prevent PC update (connected to stall_pipeline).
    // - Outputs PC to 'icache_addr' of controller.
    fetch fetch_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .branch_flag   (ifid_branch_taken), // Branch decision from IF/ID
        .branch_target (ifid_branch_addr),  // Branch target from IF/ID
        .stall         (stall_pipeline),    // Stall PC update on I-Cache or D-Cache miss
        // Interface with I-Cache (via Controller)
        .instruction_in(icache_data_out),   // Instruction comes from I-Cache
        .PC            (fetch_PC),          // PC output to I-Cache address and top-level
        // Outputs to IF/ID
        .PC_plus_two   (fetch_PC_plus_two)
        // Removed internal instruction memory access
        // Removed hlt input, as it comes from IF/ID now
    );

    // IF/ID Pipeline Register: Latch PC+2, instruction, and feedback signals.
    // Assumes stall input prevents register update.
    IF_ID_reg if_id_reg_inst (
        .clk               (clk),
        .rst_n             (rst_n),
        .stall_in          (stall_pipeline), // Stall input
        .PC_plus_2_in      (fetch_PC_plus_two),
        .PC_current_in     (fetch_PC),      // Latch current PC if needed downstream
        .instr_in          (icache_data_out), // Instruction from I-Cache
        .branch_addr_in    (dec_BranchAddr_feedback), // Feedback from DECODE
        .branch_taken_in   (dec_BranchTaken_feedback),// Feedback from DECODE
        .hlt_in            (dec_HLT),         // Feedback from DECODE
        .flush_in          (dec_flush_out),   // Feedback from DECODE
        // Outputs
        .stall_out         (ifid_stall_out),  // Pipelined stall (unused?)
        .flush_out         (ifid_flush_out),  // Pipelined flush
        .PC_reg_out        (ifid_PC_plus_two_out), // Pipelined PC+2
        .instr_reg_out     (ifid_instruction), // Pipelined instruction
        .branch_addr_reg_out(ifid_branch_addr), // Pipelined feedback for Fetch
        .branch_taken_reg_out(ifid_branch_taken),// Pipelined feedback for Fetch
        .hlt_reg_out       (ifid_hlt)         // Pipelined feedback for Fetch
    );

    // DECODE: Decode instruction, read registers, generate control signals, handle writeback.
    DECODE decode_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .instruction     (ifid_instruction),
        .PC_plus_2       (ifid_PC_plus_two_out),
        .WriteRegData_Ext(wb_WriteData),    // Data from Writeback stage
        .in_RegWrite     (memwb_RegWrite),    // Write enable from MEM/WB stage
        .WriteDstReg     (memwb_DstReg),      // Dest Reg Addr from MEM/WB stage
        .Z_flag          (idex_Zero_out),     // Flags from ID/EX output (originally from EXE)
        .N_flag          (idex_Neg_out),
        .V_flag          (idex_Ovfl_out),
        .EX_MEM_ReadMem  (idex_MemRead),      // Control signal from ID/EX (for hazard detection?)
        .EX_MEM_RS       (idex_RS),           // Reg specifiers from ID/EX (for hazard detection?)
        .EX_MEM_RT       (idex_RT),
        .EX_MEM_RD       (idex_RD),
        .stall_out       (dec_stall_out),     // Output stall signal (unused?)
        .flush_out       (dec_flush_out),     // Output flush signal to IF/ID
        .flush_in        (ifid_flush_out),    // Input pipelined flush
        .halted          (ifid_hlt),          // Input pipelined hlt
        // Outputs to ID/EX Register
        .ALU_input_1     (dec_ALU_input_1),
        .ALU_input_2     (dec_ALU_input_2),
        .RS              (dec_RS),
        .RT              (dec_RT),
        .RD              (dec_RD),
        .en_Z            (dec_en_Z),
        .en_V            (dec_en_V),
        .en_N            (dec_en_N),
        .ALUOp           (dec_ALUOp),
        .MemRead         (dec_MemRead),
        .MemWrite        (dec_MemWrite),
        .MemToReg        (dec_MemToReg),
        .RegWrite        (dec_RegWrite),
        .SW_data         (dec_SW_data),
        // Feedback Outputs to IF/ID Register
        .BranchTaken     (dec_BranchTaken_feedback),
        .BranchAddr      (dec_BranchAddr_feedback),
        .HLT             (dec_HLT),
        .stall_in        (ifid_stall_out)     // Input pipelined stall (unused?)
    );

    // ID/EX Pipeline Register: Latch signals. Stall on D-Cache miss.
    // Assumes stall input prevents register update.
    ID_EX id_ex_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_pipeline), // Stall input
        .flush(dec_flush_out),  // Flush input from Decode
        // Inputs from DECODE
        .in_ALU_in1(dec_ALU_input_1),
        .in_ALU_in2(dec_ALU_input_2),
        .in_SW_data(dec_SW_data),
        .in_en_Z(dec_en_Z),
        .in_en_V(dec_en_V),
        .in_en_N(dec_en_N),
        .in_MemToReg(dec_MemToReg),
        .in_MemRead(dec_MemRead),
        .in_MemWrite(dec_MemWrite),
        .in_ALUOp(dec_ALUOp),
        .in_RS(dec_RS),
        .in_RT(dec_RT),
        .in_RD(dec_RD),
        .in_HLT(dec_HLT), // HLT signal from Decode
        .in_RegWrite(dec_RegWrite),
        .in_Ovfl(ex_Ovfl), // Flags from Execute stage
        .in_Neg(ex_Neg),
        .in_Zero(ex_Zero),
        // Outputs to EXECUTE / EX/MEM Register
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
        .out_RegWrite(idex_RegWrite),
        .out_Ovfl(idex_Ovfl_out), // Flags passed back to Decode
        .out_Neg(idex_Neg_out),
        .out_Zero(idex_Zero_out),
        .out_HLT(idex_HLT) // Pipelined HLT
    );

    // EXECUTE: Perform ALU operation and calculate flags. Uses forwarded inputs.
    Execute execute_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .ALU_In1   (forwarded_ALU_in1), // Use forwarded value
        .ALU_In2   (forwarded_ALU_in2), // Use forwarded value
        .Opcode    (idex_ALUOp),
        .en_Z      (idex_en_Z),
        .en_N      (idex_en_N),
        .en_V      (idex_en_V),
        // Outputs to EX/MEM Register
        .ALU_Out   (ex_ALU_result),
        .Ovfl      (ex_Ovfl),
        .Neg       (ex_Neg),
        .Zero      (ex_Zero)
    );

    // EX/MEM Pipeline Register: Latch ALU result, flags, and MEM/WB controls. Stall on D-Cache miss.
    // Assumes stall input prevents register update.
    EX_MEM ex_mem_inst (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_pipeline), // Stall input
        // Inputs from EXECUTE / ID/EX
        .in_ALU_result(ex_ALU_result),
        .in_SW_data(idex_SW_data), // Use forwarded SW data? No, use ID/EX output
        .in_MemWrite(idex_MemWrite),
        .in_MemRead(idex_MemRead),
        .in_MemToReg(idex_MemToReg),
        .in_RegWrite(idex_RegWrite),
        .in_HLT(idex_HLT),
        .in_DstReg(idex_RD),      // Destination register from ID/EX
        .in_RT(idex_RT),          // RT from ID/EX for forwarding
        // Outputs to MEM stage / MEM/WB Register
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

    // MEM Stage: Access D-Cache via Cache Controller (Instantiation handled above).

    // MEM/WB Pipeline Register: Latch data from D-Cache/ALU result and WB controls. Stall on D-Cache miss.
    // Assumes stall input prevents register update.
    MEM_WB mem_wb_inst (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_pipeline), // Stall input
        // Inputs from MEM stage (Cache Controller / EX/MEM Reg)
        .in_ALU_result(exmem_ALU_result),
        .in_memData(dcache_data_out), // Data from D-Cache
        .in_MemToReg(exmem_MemToReg),
        .in_RegWrite(exmem_RegWrite),
        .in_HLT(exmem_HLT),
        .in_DstReg(exmem_DstReg),
        // Outputs to Writeback Stage
        .out_ALU_result(memwb_ALU_result),
        .out_memData(memwb_memData),
        .out_MemToReg(memwb_MemToReg),
        .out_RegWrite(memwb_RegWrite),
        .out_DstReg(memwb_DstReg),
        .out_HLT(memwb_HLT)
    );

    // WRITEBACK Stage: Select data to write back to register file.
    Writeback writeback_inst (
        .memData(memwb_memData),
        .ALU_out(memwb_ALU_result),
        .memToReg(memwb_MemToReg),
        .regWriteData(wb_WriteData) // Output to Decode's RegFile write port
    );

    // --- Forwarding Logic ---

    // Forwarding Muxes for ALU Inputs
    assign forwarded_ALU_in1 = (ForwardA == 2'b10) ? exmem_ALU_result :
                               (ForwardA == 2'b01) ? wb_WriteData : idex_ALU_in1;
    assign forwarded_ALU_in2 = (ForwardB == 2'b10) ? exmem_ALU_result :
                               (ForwardB == 2'b01) ? wb_WriteData : idex_ALU_in2;

    // Forwarding Mux for Store Word Data (Example: Forward from MEM/WB stage)
    // Adjust based on precise forwarding needs for SW.
    // This forwards the result selected by the writeback mux.
    assign forwarded_SW_data = ForwardMem ? wb_WriteData : exmem_SW_data;

    // Forwarding Unit
    ForwardingUnit forward_unit (
        .MEM_WB_RegWrite(memwb_RegWrite),
        .EX_MEM_RegWrite(exmem_RegWrite),
        .ID_EX_MemWrite(idex_MemWrite), // Needed for SW forwarding logic?
        .MEM_WB_Rd(memwb_DstReg),
        .EX_MEM_Rd(exmem_DstReg),
        .EX_MEM_Rt(exmem_RT),         // Rt passed from EX/MEM
        .ID_EX_Rt(idex_RT),           // Rt from ID/EX
        .ID_EX_Rs(idex_RS),           // Rs from ID/EX
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardMem(ForwardMem),      // Enable SW forwarding
        .ALU_OpCode(idex_ALUOp)       // ALUOp might influence forwarding needs
    );


    //-------------------------------------------------------------------------
    // Top-Level Output Assignment
    //-------------------------------------------------------------------------
    assign pc = fetch_PC;   // Current PC from FETCH (for debugging)
    assign hlt = memwb_HLT; // Halt signal from final pipeline stage (MEM/WB)

endmodule