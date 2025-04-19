module cpu(
    input         clk,    // System clock
    input         rst_n,  // Active low reset
    output        hlt,    // Halt signal (from pipelined HLT)
    output [15:0] pc_out  // Current program counter (from FETCH)
);

    //-------------------------------------------------------------------------
    // Wire Declarations
    //-------------------------------------------------------------------------

    // FETCH outputs
    wire [15:0] instruction;    // Fetched instruction
    wire [15:0] PC;             // Current PC value from FETCH
    wire [15:0] PC_plus_two;    // PC + 2 from FETCH

    // IF/ID pipeline outputs
    wire [15:0] ifid_PC_out, ifid_instr_out;

    // DECODE outputs (to be pipelined)
    wire [15:0] ALU_input_1, ALU_input_2;
    wire        en_Z, en_V, en_N;
    wire [3:0]  ALUOp;
    wire        MemRead, MemWrite, MemToReg;
    wire        BranchTaken;
    wire [15:0] BranchAddr;
    wire [15:0] SW_data;
    // Note: 'hlt' is also generated in DECODE

    // ID/EX pipeline outputs
    wire [15:0] idex_ALU_in1, idex_ALU_in2, idex_BranchAddr, idex_SW_data;
    wire        idex_en_Z, idex_en_V, idex_en_N;
    wire [3:0]  idex_ALUOp;
    wire        idex_MemRead, idex_MemWrite, idex_MemToReg;
    wire        idex_BranchTaken;
    wire        idex_HLT;

    // Execute outputs & flag signals
    wire [15:0] alu_result;
    wire        Zero, Neg, Ovfl;

    // Writeback signal
    wire [15:0] wb_data;

    //-------------------------------------------------------------------------
    // Module Instantiations
    //-------------------------------------------------------------------------

    // FETCH: Generate PC, fetch instruction, and compute PC+2.
    fetch fetch_inst(
        .clk          (clk),
        .rst_n        (rst_n),
        .branch_flag  (idex_BranchTaken),
        .branch_target(idex_BranchAddr),
        .hlt          (idex_HLT),
        .instruction  (instruction),
        .PC           (PC),
        .PC_plus_two  (PC_plus_two)
    );

    // IF/ID Pipeline Register: Latch PC+2 and instruction.
    // Flush and nop signals are tied to 0 (no hazards/flushes currently).
    IF_ID_reg if_id_reg_inst(
        .inc_PC_in (PC_plus_two),
        .instr_in  (instruction),
        .PC_out    (ifid_PC_out),
        .instr_out (ifid_instr_out),
        .flush     (1'b0),
        .nop       (1'b0),
        .clk       (clk),
        .rst_n     (rst_n)
    );

    // DECODE: Decode instruction and generate control/ALU signals.
    DECODE decode_inst(
        .clk               (clk),
        .rst_n             (rst_n),
        .instruction       (ifid_instr_out),
        .PC_plus_2         (ifid_PC_out),
        .WriteRegData_Ext  (wb_data),
        .Z_flag            (Zero),
        .N_flag            (Neg),
        .V_flag            (Ovfl),
        .ALU_input_1       (ALU_input_1),
        .ALU_input_2       (ALU_input_2),
        .en_Z              (en_Z),
        .en_V              (en_V),
        .en_N              (en_N),
        .ALUOp             (ALUOp),
        .MemRead           (MemRead),
        .MemWrite          (MemWrite),
        .MemToReg          (MemToReg),
        .BranchTaken       (BranchTaken),
        .BranchAddr        (BranchAddr),
        .HLT               (hlt),
        .SW_data           (SW_data)
    );

    // ID/EX Pipeline Register: Latch signals for the Execute/MEM stages.
    ID_EX id_ex_reg_inst(
        .in_ALU_in1    (ALU_input_1),
        .in_ALU_in2    (ALU_input_2),
        .out_ALU_in1   (idex_ALU_in1),
        .out_ALU_in2   (idex_ALU_in2),
        .in_en_Z       (en_Z),
        .out_en_Z      (idex_en_Z),
        .in_en_V       (en_V),
        .out_en_V      (idex_en_V),
        .in_en_N       (en_N),
        .out_en_N      (idex_en_N),
        .in_ALUOp      (ALUOp),
        .out_ALUOp     (idex_ALUOp),
        .in_MemRead    (MemRead),
        .out_MemRead   (idex_MemRead),
        .in_MemWrite   (MemWrite),
        .out_MemWrite  (idex_MemWrite),
        .in_MemToReg   (MemToReg),
        .out_MemToReg  (idex_MemToReg),
        .in_BranchTaken(BranchTaken),
        .out_BranchTaken(idex_BranchTaken),
        .in_BranchAddr (BranchAddr),
        .out_BranchAddr(idex_BranchAddr),
        .in_HLT        (hlt),
        .out_HLT       (idex_HLT),
        .in_SW_data    (SW_data),
        .out_SW_data   (idex_SW_data)
    );

    // Execute: Perform ALU operation using pipelined ALU inputs.
    Execute execute_inst(
        .ALU_In1   (idex_ALU_in1),
        .ALU_In2   (idex_ALU_in2),
        .Opcode    (idex_ALUOp),
        .ALU_Out   (alu_result),
        .Ovfl      (Ovfl),
        .Neg       (Neg),
        .Zero      (Zero),
        .en_Z      (idex_en_Z),
        .en_N      (idex_en_N),
        .en_V      (idex_en_V),
        .clk       (clk),
        .rst_n     (rst_n)
    );

    // Data Memory: Use ALU result as address and pipelined SW_data as input.
    wire [15:0] mem_out;
    memory1c data_memory (
        .data_out (mem_out),
        .data_in  (idex_SW_data),
        .addr     (alu_result),
        .enable   (idex_MemRead | idex_MemWrite),
        .wr       (idex_MemWrite & (~idex_MemRead)),
        .clk      (clk),
        .rst      (~rst_n)
    );

    // Writeback: Select between memory data and ALU result based on pipelined MemToReg.
    Writeback writeback_inst(
        .memData     (mem_out),
        .ALU_out     (alu_result),
        .memToReg    (idex_MemToReg),
        .regWriteData(wb_data)
    );

    //-------------------------------------------------------------------------
    // Top-Level Output Assignment
    //-------------------------------------------------------------------------
    assign pc_out = PC;

endmodule
