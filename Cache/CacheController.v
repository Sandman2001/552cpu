/*
Andrew Sanders - 4/28/2025
This module is designed to interface the memory and cache modules together
module will intiate cache checks and memory calls
the cache controller will output the required data, update the cache
*/

module CacheController(clk, rst, memRead, memWrite, ins_addr, mem_addr, memDataIn, instDataIn, memDataOut, instDataOut, IFStall, MEMStall);
    input clk, rst;
    input memRead, memWrite;
    input [15:0] mem_addr, ins_addr;
    input [15:0] memDataIn, instDataIn;
    output [15:0] memDataOut, instDataOut;
    output IFStall, MEMStall;

    // Data Cache intermediates
    wire [7:0] D_MetaDataIn1, D_MetaDataIn2; //for each set
    wire D_MetaWrite1, D_MetaWrite2;
    wire [63:0] D_BlockEnable;
    wire [7:0] D_MetaDataOut1, D_MetaDataOut2;
    wire [15:0] D_DataIn;
    wire D_DataWrite1, D_DataWrite2, D_FSMMetaEn;
    wire [7:0] D_inst_wrd_en, D_WordEnable;
    wire [15:0] D_DataOut1, D_DataOut2;

    wire [5:0] D_index;
    wire [2:0] D_offset;
    wire [7:0] D_tag;
    wire [7:0] D_FSM_wrd_en;

    wire dataHit1, dataHit2, dataMiss;

    wire D_fsm_busy, D_FSMDataEn;
    wire [15:0] D_memToRead;
    wire D_stall;


    // Instruction Cache intermediates
    wire [7:0] I_MetaDataIn1, I_MetaDataIn2;
    wire I_MetaWrite1, I_MetaWrite2;
    wire [63:0] I_BlockEnable;
    wire [7:0] I_MetaDataOut1, I_MetaDataOut2;
    wire [15:0] I_DataIn;
    wire I_DataWrite1, I_DataWrite2;
    wire [7:0] I_inst_wrd_en, I_WordEnable;
    wire [15:0] I_DataOut1, I_DataOut2;

    wire [5:0] I_index;
    wire [2:0] I_offset;
    wire [7:0] I_tag;
    wire [7:0] I_FSM_wrd_en;

    wire instHit1, instHit2, instMiss;

    wire I_fsm_busy, I_FSMMetaEn, I_FSMDataEn;
    wire [15:0] I_memToRead;
    wire I_stall;

    // Memory intermediates
    wire [15:0] mainMemOut, mainMemAddr;
    wire mainMemEnable, mainMemWR, mainMemValid;


    /**
     * Data cache
     *
     **/
    assign D_offset = mem_addr[3:1];
    assign D_index = mem_addr[9:4];
    assign D_tag = mem_addr[15:10];


    //Find set
    blockEnable dataBlockEn(.set_index(D_index), .blockEn(D_BlockEnable));

    //Find block offset
    wordEnable dataWordEn(.b_offset(D_offset), .wordEn(D_inst_wrd_en));

    //check for hits
    assign dataHit1 = (D_tag == D_MetaDataOut1[7:2]) & D_MetaDataOut1[0];
    assign dataHit2 = (D_tag == D_MetaDataOut2[7:2]) & D_MetaDataOut2[0];
    assign dataMiss = ~dataHit1 & ~dataHit2 & (memRead | memWrite);

    //data cache input signals
    assign D_MetaDataIn1 =  ~dataMiss ? {D_MetaDataOut1[7:2], ~dataHit1, D_MetaDataOut1[0]} : (~D_MetaDataOut1[1]) ? {D_tag, 1'b0, 1'b1} : D_MetaDataOut1; // {tag, LRU, valid}
    assign D_MetaDataIn2 =  ~dataMiss ? {D_MetaDataOut2[7:2], ~dataHit2, D_MetaDataOut2[0]} :  (D_MetaDataOut1[1]) ? {D_tag, 1'b0, 1'b1} : D_MetaDataOut2;
    assign D_DataIn = (dataMiss) ? mainMemOut : memDataIn; //check if there was cache miss. Yes: Data in from memory, no: update with input value dataIn

    assign D_MetaWrite1 = D_FSMMetaEn; //enable write to LRU
    assign D_MetaWrite2 = D_FSMMetaEn;
    
     //Choose word enable
    assign D_WordEnable = (dataMiss) ? D_FSM_wrd_en : D_inst_wrd_en;

    assign D_DataWrite1 = (D_FSMDataEn & ~D_MetaDataOut2[1] & dataMiss) | (memWrite & dataHit1); //update the data array if you miss or hit //OR if it's LRU, LRU if it's meta is 1
    assign D_DataWrite2 = (D_FSMDataEn & D_MetaDataOut2[1] & dataMiss) | (memWrite & dataHit2);


    dcache dataCache(.clk(clk), .rst(rst), .MetaDataIn1(D_MetaDataIn1), .MetaDataIn2(D_MetaDataIn2), .MetaWrite1(D_MetaWrite1), .MetaWrite2(D_MetaWrite2), 
                    .BlockEnable(D_BlockEnable), .MetaDataOut1(D_MetaDataOut1), .MetaDataOut2(D_MetaDataOut2), .DataIn(D_DataIn), 
                    .DataWrite1(D_DataWrite1), .DataWrite2(D_DataWrite2), .WordEnable(D_WordEnable), .DataOut1(D_DataOut1), .DataOut2(D_DataOut2));

    cache_fill_FSM dataCacheFSM(.clk(clk), .rst_n(~rst), .miss_detected(dataMiss & ~I_fsm_busy), .miss_address(mem_addr), .fsm_busy(D_fsm_busy), 
                    .write_data_array(D_FSMDataEn), .write_tag_array(D_FSMMetaEn), .memory_address(D_memToRead), .memory_data(mainMemOut), .memory_data_valid(mainMemValid), 
                    .wrd_en(D_FSM_wrd_en), .stall(D_stall));

    assign MEMStall = D_stall | dataMiss;
    assign memDataOut = dataMiss ? (16'h0000) : (dataHit1 ? D_DataOut1 : D_DataOut2);

    //main mem    
    assign mainMemAddr = instMiss ? I_memToRead : dataMiss ? D_memToRead : mem_addr;
    assign mainMemEnable = (D_fsm_busy | I_fsm_busy) & (dataMiss | instMiss | memWrite); //enable if withe Cache is in the WAIT state AND if theres is a miss or a memWrite
    assign mainMemWR = (memWrite & ~dataMiss);
    /**
     * Instruction cache
     *
     **/
    assign I_offset = ins_addr[3:1];
    assign I_index = ins_addr[9:4];
    assign I_tag = ins_addr[15:10];

    //Find set
    blockEnable instBlockEn(.set_index(I_index), .blockEn(I_BlockEnable));

    //Find block offset
    wordEnable instWordEn(.b_offset(I_offset), .wordEn(I_inst_wrd_en));

    //check for hits
    assign instHit1 = (I_tag == I_MetaDataOut1[7:2]) & I_MetaDataOut1[0];
    assign instHit2 = (I_tag == I_MetaDataOut2[7:2]) & I_MetaDataOut2[0];
    assign instMiss = ~instHit1 & ~instHit2;

    //instruction cache input signals
    //assign I_MetaDataIn1 = instHit1 ? {I_MetaDataOut1[7:2], 1'b0, I_MetaDataOut1[0]} : instHit2 ? {I_MetaDataOut1[7:2], 1'b1, I_MetaDataOut1[0]} : {I_tag, 1'b0, 1'b1}; //if hit then update tag and set LRU = 0, else if hit on the other line update LRU = 1, else keep the same
    assign I_MetaDataIn1 = ~instMiss ? {I_MetaDataOut1[7:2], ~instHit1, I_MetaDataOut1[0]} : (~I_MetaDataOut1[1]) ? {I_tag, 1'b0, 1'b1} : I_MetaDataOut1;
    //assign I_MetaDataIn2 = instHit2 ? {I_tag, 1'b0, 1'b1} : instHit1 ? {I_MetaDataOut2[7:2], 1'b1, I_MetaDataOut2[0]} : I_MetaDataOut2;
    assign I_MetaDataIn2 = ~instMiss ? {I_MetaDataOut2[7:2], ~instHit2, I_MetaDataOut2[0]} :  (I_MetaDataOut1[1]) ? {I_tag, 1'b0, 1'b1} : I_MetaDataOut2;
    assign I_DataIn = mainMemOut;

    assign I_MetaWrite1 = I_FSMMetaEn;
    assign I_MetaWrite2 = I_FSMMetaEn;

    //Choose word enable
    assign I_WordEnable = (instMiss) ? I_FSM_wrd_en : I_inst_wrd_en;
    
    assign I_DataWrite1 = (I_FSMDataEn & ~I_MetaDataOut2[1] & instMiss); //update the inst array if you miss or hit //OR if it's LRU, LRU if it's meta is 1
    assign I_DataWrite2 = (I_FSMDataEn & I_MetaDataOut2[1] & instMiss);


    icache instCache(.clk(clk), .rst(rst), .MetaDataIn1(I_MetaDataIn1), .MetaDataIn2(I_MetaDataIn2), .MetaWrite1(I_MetaWrite1), .MetaWrite2(I_MetaWrite2), 
                    .BlockEnable(I_BlockEnable), .MetaDataOut1(I_MetaDataOut1), .MetaDataOut2(I_MetaDataOut2), .DataIn(I_DataIn), 
                    .DataWrite1(I_DataWrite1), .DataWrite2(I_DataWrite2), .WordEnable(I_WordEnable), .DataOut1(I_DataOut1), .DataOut2(I_DataOut2));

    cache_fill_FSM instCacheFSM(.clk(clk), .rst_n(~rst), .miss_detected(instMiss & ~D_fsm_busy), .miss_address(ins_addr), .fsm_busy(I_fsm_busy), 
                    .write_data_array(I_FSMDataEn), .write_tag_array(I_FSMMetaEn), .memory_address(I_memToRead), .memory_data(mainMemOut), .memory_data_valid(mainMemValid), 
                    .wrd_en(I_FSM_wrd_en), .stall (I_stall));

    assign IFStall = I_stall;
    assign instDataOut = instMiss ? (16'h0000) : (instHit1 ? I_DataOut1 : I_DataOut2);

    

    memory4c mainMem(.data_out(mainMemOut), .data_in(memDataIn), .addr(mainMemAddr), .enable(mainMemEnable | mainMemWR), .wr(mainMemWR), .clk(clk), .rst(rst), .data_valid(mainMemValid));
    
endmodule