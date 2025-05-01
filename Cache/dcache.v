module dcache(clk, rst, MetaDataIn1, MetaDataIn2, MetaWrite1, MetaWrite2, BlockEnable, MetaDataOut1, MetaDataOut2, DataIn, DataWrite1, DataWrite2, WordEnable, DataOut1, DataOut2);
    input clk, rst;
    input [7:0] MetaDataIn1, MetaDataIn2;
    input MetaWrite1, MetaWrite2;
    input [63:0] BlockEnable;
    output [7:0] MetaDataOut1, MetaDataOut2;
    input [15:0] DataIn;
    input DataWrite1, DataWrite2;
    input [7:0] WordEnable;
    output [15:0] DataOut1, DataOut2;


    MetaDataArray meta(.clk(clk), .rst(rst), .DataIn1(MetaDataIn1), .DataIn2(MetaDataIn2), .Write1(MetaWrite1), .Write2(MetaWrite2), .BlockEnable(BlockEnable), .DataOut1(MetaDataOut1), .DataOut2(MetaDataOut2));

    DataArray data(.clk(clk), .rst(rst), .DataIn(DataIn), .Write1(DataWrite1), .Write2(DataWrite2), .BlockEnable(BlockEnable), .WordEnable(WordEnable), .DataOut1(DataOut1), .DataOut2(DataOut2));

endmodule