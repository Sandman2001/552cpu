module ID_EX(
    input         clk,
    input         rst_n,
    input         flush,  // Flush input signal

    // Data signals for EX stage 
    input [15:0]  in_ALU_in1, 
    input [15:0]  in_ALU_in2, 
    input [15:0]  in_SW_data,
    input         in_en_Z, 
    input         in_en_V, 
    input         in_en_N, 
    input         in_MemToReg, 
    input         in_MemRead, 
    input         in_MemWrite,
    input [3:0]   in_ALUOp,
    input         in_RegWrite,
    input         in_HLT,

    input [3:0]   in_RS,
    input [3:0]   in_RT,
    input [3:0]   in_RD,

    input         in_Ovfl,
    input         in_Neg,
    input         in_Zero,

    output        out_Ovfl,
    output        out_Neg,
    output        out_Zero,
    output        out_HLT,
    
    // Outputs to EX stage
    output [15:0] out_ALU_in1, 
    output [15:0] out_ALU_in2, 
    output [15:0] out_SW_data,
    output        out_en_Z, 
    output        out_en_V, 
    output        out_en_N, 
    output        out_MemToReg, 
    output        out_MemRead, 
    output        out_MemWrite,
    output        out_RegWrite,
    output [3:0]  out_ALUOp,
    
    // Outputs for register specifiers (RS, RT, RD)
    output [3:0]  out_RS,
    output [3:0]  out_RT,
    output [3:0]  out_RD
);

// Intermediate signals: if flush is high, force the input to 0; otherwise pass through.
wire [15:0] alu_in1_d    = flush ? 16'b0 : in_ALU_in1;
wire [15:0] alu_in2_d    = flush ? 16'b0 : in_ALU_in2;
wire [15:0] sw_data_d    = flush ? 16'b0 : in_SW_data;
wire        en_Z_d       = flush ? 1'b0    : in_en_Z;
wire        en_V_d       = flush ? 1'b0    : in_en_V;
wire        en_N_d       = flush ? 1'b0    : in_en_N;
wire [3:0]  aluOp_d      = flush ? 4'b0    : in_ALUOp;
wire        memRead_d    = flush ? 1'b0    : in_MemRead;
wire        memWrite_d   = flush ? 1'b0    : in_MemWrite;
wire        memToReg_d   = flush ? 1'b0    : in_MemToReg;

// Intermediate signals for register numbers
wire [3:0] rs_d = flush ? 4'b0 : in_RS;
wire [3:0] rt_d = flush ? 4'b0 : in_RT;
wire [3:0] rd_d = flush ? 4'b0 : in_RD;

// D flip-flops for each signal.
dff ALU_in1_reg [15:0] (.q(out_ALU_in1), .d(alu_in1_d),    .wen(1'b1), .clk(clk), .rst(~rst_n));
dff ALU_in2_reg [15:0] (.q(out_ALU_in2), .d(alu_in2_d),    .wen(1'b1), .clk(clk), .rst(~rst_n));
dff SW_data_reg  [15:0] (.q(out_SW_data), .d(sw_data_d),     .wen(1'b1), .clk(clk), .rst(~rst_n));
dff en_Z_reg (.q(out_en_Z), .d(en_Z_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff en_V_reg (.q(out_en_V), .d(en_V_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff en_N_reg (.q(out_en_N), .d(en_N_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff ALUOp_reg [3:0] (.q(out_ALUOp), .d(aluOp_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff MemRead_reg (.q(out_MemRead), .d(memRead_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff MemWrite_reg (.q(out_MemWrite), .d(memWrite_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff MemToReg_reg (.q(out_MemToReg), .d(memToReg_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff RegWrite_reg (.q(out_RegWrite), .d(in_RegWrite), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff HLT_reg (.q(out_HLT), .d(in_HLT), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff Zero_reg (.q(out_Zero), .d(in_Zero), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff Neg_reg (.q(out_Neg), .d(in_Neg), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff Ovfl_reg (.q(out_Ovfl), .d(in_Ovfl), .wen(1'b1), .clk(clk), .rst(~rst_n));

// D flip-flops for register specifiers
dff RS_reg [3:0] (.q(out_RS), .d(rs_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff RT_reg [3:0] (.q(out_RT), .d(rt_d), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff RD_reg [3:0] (.q(out_RD), .d(rd_d), .wen(1'b1), .clk(clk), .rst(~rst_n));

endmodule
