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

    // Manually instantiate 16 BitCells
    BitCell bit_cell0 (
        .clk(clk),
        .rst(rst),
        .D(D[0]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[0]),
        .Bitline2(Bitline2[0])
    );
    BitCell bit_cell1 (
        .clk(clk),
        .rst(rst),
        .D(D[1]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[1]),
        .Bitline2(Bitline2[1])
    );
    BitCell bit_cell2 (
        .clk(clk),
        .rst(rst),
        .D(D[2]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[2]),
        .Bitline2(Bitline2[2])
    );
    BitCell bit_cell3 (
        .clk(clk),
        .rst(rst),
        .D(D[3]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[3]),
        .Bitline2(Bitline2[3])
    );
    BitCell bit_cell4 (
        .clk(clk),
        .rst(rst),
        .D(D[4]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[4]),
        .Bitline2(Bitline2[4])
    );
    BitCell bit_cell5 (
        .clk(clk),
        .rst(rst),
        .D(D[5]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[5]),
        .Bitline2(Bitline2[5])
    );
    BitCell bit_cell6 (
        .clk(clk),
        .rst(rst),
        .D(D[6]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[6]),
        .Bitline2(Bitline2[6])
    );
    BitCell bit_cell7 (
        .clk(clk),
        .rst(rst),
        .D(D[7]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[7]),
        .Bitline2(Bitline2[7])
    );
    BitCell bit_cell8 (
        .clk(clk),
        .rst(rst),
        .D(D[8]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[8]),
        .Bitline2(Bitline2[8])
    );
    BitCell bit_cell9 (
        .clk(clk),
        .rst(rst),
        .D(D[9]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[9]),
        .Bitline2(Bitline2[9])
    );
    BitCell bit_cell10 (
        .clk(clk),
        .rst(rst),
        .D(D[10]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[10]),
        .Bitline2(Bitline2[10])
    );
    BitCell bit_cell11 (
        .clk(clk),
        .rst(rst),
        .D(D[11]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[11]),
        .Bitline2(Bitline2[11])
    );
    BitCell bit_cell12 (
        .clk(clk),
        .rst(rst),
        .D(D[12]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[12]),
        .Bitline2(Bitline2[12])
    );
    BitCell bit_cell13 (
        .clk(clk),
        .rst(rst),
        .D(D[13]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[13]),
        .Bitline2(Bitline2[13])
    );
    BitCell bit_cell14 (
        .clk(clk),
        .rst(rst),
        .D(D[14]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[14]),
        .Bitline2(Bitline2[14])
    );
    BitCell bit_cell15 (
        .clk(clk),
        .rst(rst),
        .D(D[15]),
        .WriteEnable(WriteReg),
        .ReadEnable1(ReadEnable1),
        .ReadEnable2(ReadEnable2),
        .Bitline1(Bitline1[15]),
        .Bitline2(Bitline2[15])
    );

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
    
    wire bypass_read1 = WriteReg && (SrcReg1 == DstReg);
    wire bypass_read2 = WriteReg && (SrcReg2 == DstReg);

    assign SrcData1 = bypass_read1 ? DstData : 16'bz;
    assign SrcData2 = bypass_read2 ? DstData : 16'bz;
    
    // Manually instantiate 16 Registers
    Register reg0(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[0]),
        .ReadEnable1(ReadWordline1[0] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[0] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg1(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[1]),
        .ReadEnable1(ReadWordline1[1] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[1] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg2(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[2]),
        .ReadEnable1(ReadWordline1[2] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[2] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg3(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[3]),
        .ReadEnable1(ReadWordline1[3] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[3] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg4(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[4]),
        .ReadEnable1(ReadWordline1[4] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[4] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg5(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[5]),
        .ReadEnable1(ReadWordline1[5] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[5] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg6(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[6]),
        .ReadEnable1(ReadWordline1[6] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[6] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg7(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[7]),
        .ReadEnable1(ReadWordline1[7] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[7] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg8(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[8]),
        .ReadEnable1(ReadWordline1[8] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[8] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg9(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[9]),
        .ReadEnable1(ReadWordline1[9] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[9] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg10(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[10]),
        .ReadEnable1(ReadWordline1[10] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[10] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg11(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[11]),
        .ReadEnable1(ReadWordline1[11] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[11] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg12(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[12]),
        .ReadEnable1(ReadWordline1[12] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[12] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg13(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[13]),
        .ReadEnable1(ReadWordline1[13] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[13] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg14(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[14]),
        .ReadEnable1(ReadWordline1[14] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[14] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );
    Register reg15(
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(WriteWordline[15]),
        .ReadEnable1(ReadWordline1[15] & ~bypass_read1),
        .ReadEnable2(ReadWordline2[15] & ~bypass_read2),
        .Bitline1(SrcData1),
        .Bitline2(SrcData2)
    );


endmodule
