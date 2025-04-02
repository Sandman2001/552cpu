// Converts 4-bit register ID to 16-bit one-hot encoding
module ReadDecoder_4_16(input [3:0] RegId, output [15:0] Wordline);
    assign Wordline[0]  = (RegId == 4'b0000);
    assign Wordline[1]  = (RegId == 4'b0001);
    assign Wordline[2]  = (RegId == 4'b0010);
    assign Wordline[3]  = (RegId == 4'b0011);
    assign Wordline[4]  = (RegId == 4'b0100);
    assign Wordline[5]  = (RegId == 4'b0101);
    assign Wordline[6]  = (RegId == 4'b0110);
    assign Wordline[7]  = (RegId == 4'b0111);
    assign Wordline[8]  = (RegId == 4'b1000);
    assign Wordline[9]  = (RegId == 4'b1001);
    assign Wordline[10] = (RegId == 4'b1010);
    assign Wordline[11] = (RegId == 4'b1011);
    assign Wordline[12] = (RegId == 4'b1100);
    assign Wordline[13] = (RegId == 4'b1101);
    assign Wordline[14] = (RegId == 4'b1110);
    assign Wordline[15] = (RegId == 4'b1111);
endmodule

module WriteDecoder_4_16(input [3:0] RegId, input WriteReg, output [15:0] Wordline);
    assign Wordline[0]  = WriteReg & (RegId == 4'b0000);
    assign Wordline[1]  = WriteReg & (RegId == 4'b0001);
    assign Wordline[2]  = WriteReg & (RegId == 4'b0010);
    assign Wordline[3]  = WriteReg & (RegId == 4'b0011);
    assign Wordline[4]  = WriteReg & (RegId == 4'b0100);
    assign Wordline[5]  = WriteReg & (RegId == 4'b0101);
    assign Wordline[6]  = WriteReg & (RegId == 4'b0110);
    assign Wordline[7]  = WriteReg & (RegId == 4'b0111);
    assign Wordline[8]  = WriteReg & (RegId == 4'b1000);
    assign Wordline[9]  = WriteReg & (RegId == 4'b1001);
    assign Wordline[10] = WriteReg & (RegId == 4'b1010);
    assign Wordline[11] = WriteReg & (RegId == 4'b1011);
    assign Wordline[12] = WriteReg & (RegId == 4'b1100);
    assign Wordline[13] = WriteReg & (RegId == 4'b1101);
    assign Wordline[14] = WriteReg & (RegId == 4'b1110);
    assign Wordline[15] = WriteReg & (RegId == 4'b1111);
endmodule

module BitCell(
    input clk,
    input rst,             // active high reset
    input D,
    input WriteEnable,
    input ReadEnable1,
    input ReadEnable2,
    inout Bitline1,
    inout Bitline2
);
    wire q; 

    dff dff_1(.q(q), .d(D), .wen(WriteEnable), .clk(clk), .rst(rst));
    
    // Tri-state buffers for read operations
    assign Bitline1 = ReadEnable1 ? q : 1'bz;
    assign Bitline2 = ReadEnable2 ? q : 1'bz;
endmodule


module Register(
    input clk,
    input rst,             // active high reset
    input [15:0] D,
    input WriteReg,
    input ReadEnable1,
    input ReadEnable2,
    inout [15:0] Bitline1,
    inout [15:0] Bitline2
);
    // Instantiate 16 BitCells to form a 16-bit register
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : bit_cells
            BitCell bit_cell_inst(
                .clk(clk),
                .rst(rst),
                .D(D[i]),
                .WriteEnable(WriteReg),
                .ReadEnable1(ReadEnable1),
                .ReadEnable2(ReadEnable2),
                .Bitline1(Bitline1[i]),
                .Bitline2(Bitline2[i])
            );
        end
    endgenerate
endmodule


module RegisterFile(
    input clk,
    input rst,             // active high reset for internal modules
    input [3:0] SrcReg1,
    input [3:0] SrcReg2,
    input [3:0] DstReg,
    input WriteReg,
    input [15:0] DstData,
    inout [15:0] SrcData1,
    inout [15:0] SrcData2
);
    // Decode register addresses
    wire [15:0] ReadWordline1, ReadWordline2, WriteWordline;
    
    ReadDecoder_4_16 read_decoder1(.RegId(SrcReg1), .Wordline(ReadWordline1));
    ReadDecoder_4_16 read_decoder2(.RegId(SrcReg2), .Wordline(ReadWordline2));
    WriteDecoder_4_16 write_decoder(.RegId(DstReg), .WriteReg(WriteReg), .Wordline(WriteWordline));
    
    wire bypass_read1, bypass_read2;

    assign bypass_read1 = WriteReg && (SrcReg1 == DstReg);
    assign bypass_read2 = WriteReg && (SrcReg2 == DstReg);

    assign SrcData1 = bypass_read1 ? DstData : 16'bz;
    assign SrcData2 = bypass_read2 ? DstData : 16'bz;
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : registers
            Register register_inst(
                .clk(clk),
                .rst(rst),
                .D(DstData),
                .WriteReg(WriteWordline[i]),
                .ReadEnable1(ReadWordline1[i] & ~bypass_read1), // disable read if bypassing
                .ReadEnable2(ReadWordline2[i] & ~bypass_read2), // disable read if bypassing
                .Bitline1(SrcData1),
                .Bitline2(SrcData2)
            );
        end
    endgenerate
endmodule
