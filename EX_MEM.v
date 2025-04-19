module EX_MEM (
    input         clk,
    input         rst_n,
    // Inputs from EX stage
    input  [15:0] in_ALU_result,   // ALU Output from EX
    input  [15:0] in_SW_data,      // Data for store words forwarded to MEM
    input         in_MemWrite,     // Memory write enable
    input         in_MemRead,      // Memory read enable
    input         in_MemToReg,     // Writeback mux select
    input         in_RegWrite,     // Writeback register write enable
    input         in_HLT,          // Halt instruction signal
    input  [3:0]  in_DstReg,       // Destination register from EX
    input  [3:0]  in_RT,           // RT field from ID/EX (for forwarding)
    
    // Outputs to MEM stage
    output [15:0] out_ALU_result,  // ALU result forwarded to MEM
    output [15:0] out_SW_data,     // Data for store words in MEM
    output        out_MemWrite,    // Memory write signal forwarded to MEM
    output        out_MemRead,     // Memory read signal forwarded to MEM
    output        out_MemToReg,    // Writeback mux select forwarded to MEM
    output        out_RegWrite,    // Writeback register write enable forwarded to MEM
    output        out_HLT,         // Halt signal forwarded to MEM
    output [3:0]  out_DstReg,      // Destination register forwarded to MEM
    output [3:0]  out_RT           // RT field forwarded to MEM (for forwarding)
);

    dff ALU_res_reg [15:0](.q(out_ALU_result), .d(in_ALU_result), .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff SW_data_reg [15:0](.q(out_SW_data), .d(in_SW_data), .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff MemWrite_reg       (.q(out_MemWrite), .d(in_MemWrite), .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff MemRead_reg        (.q(out_MemRead),  .d(in_MemRead),  .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff MemToReg_reg       (.q(out_MemToReg), .d(in_MemToReg), .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff RegWrite_reg       (.q(out_RegWrite), .d(in_RegWrite), .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff HLT_reg            (.q(out_HLT),      .d(in_HLT),      .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff DstReg_reg [3:0]   (.q(out_DstReg),   .d(in_DstReg),   .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff RT_reg       [3:0] (.q(out_RT),       .d(in_RT),       .wen(1'b1), .clk(clk), .rst(~rst_n));

endmodule
