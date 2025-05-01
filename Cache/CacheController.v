/*
Andrew Sanders - 4/28/2025
This module is designed to interface the memory and cache modules together
module will intiate cache checks and memory calls
the cache controller will output the required data, update the cache
*/
module CacheController(
    input  wire         clk,
    input  wire         rst,
    input  wire         memRead, //logic sent by cpu to read memory
    input  wire         memWrite, //logic sent by cpu to write memory
    input  wire [15:0]  ins_addr, //icache addr
    input  wire [15:0]  mem_addr, //dcache addr
    input  wire [15:0]  memDataIn,
    output wire [15:0]  memDataOut,
    output wire [15:0]  instDataOut,
    output wire         icache_stall,   // Stall signal for IF stage
    output wire         dcache_stall  // Stall signal for MEM stage (and upstream)
);

    // Data cache local signals
    wire [2:0]   data_offset;
    wire [5:0]   data_index;
    wire [7:0]   data_tag;

    wire         data_hit_way0;
    wire         data_hit_way1;
    wire         data_miss;
    wire         data_fsm_busy;
    wire [15:0]  data_fsm_addr;
    wire         data_fsm_data_en;
    wire         data_fsm_meta_en;
    wire [7:0]   data_fsm_word_en;
    wire         data_cache_stall;

    wire [7:0]   data_meta_in_way0;
    wire [7:0]   data_meta_in_way1;
    wire         data_meta_write_way0;
    wire         data_meta_write_way1;
    wire [63:0]  data_block_enable;
    wire [7:0]   data_meta_out_way0;
    wire [7:0]   data_meta_out_way1;
    wire [7:0]   data_inst_word_enable;
    wire [7:0]   data_word_enable;
    wire [15:0]  data_write_back;
    wire [15:0]  data_out_way0;
    wire [15:0]  data_out_way1;

    // Instruction cache local signals
    wire [2:0]   inst_offset;
    wire [5:0]   inst_index;
    wire [7:0]   inst_tag;

    wire         inst_hit_way0;
    wire         inst_hit_way1;
    wire         inst_miss;
    wire         inst_fsm_busy;
    wire [15:0]  inst_fsm_addr;
    wire         inst_fsm_data_en;
    wire         inst_fsm_meta_en;
    wire [7:0]   inst_fsm_word_en;
    wire         inst_cache_stall;

    wire [7:0]   inst_meta_in_way0;
    wire [7:0]   inst_meta_in_way1;
    wire         inst_meta_write_way0;
    wire         inst_meta_write_way1;
    wire [63:0]  inst_block_enable;
    wire [7:0]   inst_meta_out_way0;
    wire [7:0]   inst_meta_out_way1;
    wire [7:0]   inst_inst_word_enable;
    wire [7:0]   inst_word_enable;
    wire [15:0]  inst_write_back;
    wire [15:0]  inst_out_way0;
    wire [15:0]  inst_out_way1;

    // Main memory interface
    wire [15:0]  main_data_out;
    wire [15:0]  mainMemAddr;
    wire         mainMemEnable;
    wire         mainMemWR;
    wire         mainMemValid;

    // --- Data cache logic ---
    assign data_offset = mem_addr[3:1];
    assign data_index  = mem_addr[9:4];
    assign data_tag    = mem_addr[15:10];

    blockEnable dataBlockEn(
        .set_index(data_index),
        .blockEn(data_block_enable)
    );
    //used to check if hit/miss
    wordEnable dataWordEn(
        .b_offset(data_offset),
        .wordEn(data_inst_word_enable)
    );

    assign data_hit_way0 = (data_tag == data_meta_out_way0[7:2]) & data_meta_out_way0[0];
    assign data_hit_way1 = (data_tag == data_meta_out_way1[7:2]) & data_meta_out_way1[0];
    assign data_miss     = ~data_hit_way0 & ~data_hit_way1 & (memRead | memWrite);

    assign data_meta_in_way0 = ~data_miss
        ? {data_meta_out_way0[7:2], ~data_hit_way0, data_meta_out_way0[0]}
        : (~data_meta_out_way0[1] ? {data_tag, 1'b0, 1'b1} : data_meta_out_way0);

    assign data_meta_in_way1 = ~data_miss
        ? {data_meta_out_way1[7:2], ~data_hit_way1, data_meta_out_way1[0]}
        : ( data_meta_out_way0[1] ? {data_tag, 1'b0, 1'b1} : data_meta_out_way1);

    assign data_write_back = data_miss ? main_data_out : memDataIn;

    assign data_meta_write_way0 = data_fsm_meta_en;
    assign data_meta_write_way1 = data_fsm_meta_en;

    assign data_word_enable = data_miss ? data_fsm_word_en : data_inst_word_enable;

    dcache dataCache(
        .clk(clk), .rst(rst),
        .MetaDataIn1(data_meta_in_way0), .MetaDataIn2(data_meta_in_way1),
        .MetaWrite1(data_meta_write_way0), .MetaWrite2(data_meta_write_way1),
        .BlockEnable(data_block_enable),
        .MetaDataOut1(data_meta_out_way0), .MetaDataOut2(data_meta_out_way1),
        .DataIn(data_write_back),
        .DataWrite1(data_fsm_data_en & ~data_meta_out_way1[1] & data_miss),
        .DataWrite2(data_fsm_data_en &  data_meta_out_way1[1] & data_miss),
        .WordEnable(data_word_enable),
        .DataOut1(data_out_way0), .DataOut2(data_out_way1)
    );

    cache_fill_FSM dataCacheFSM(
        .clk(clk), .rst_n(~rst),
        //inputs into fsm
        .miss_detected(data_miss & ~inst_fsm_busy),
        .miss_address(mem_addr),
        .write_data_array(data_fsm_data_en),
        .write_tag_array(data_fsm_meta_en),
        .memory_address(data_fsm_addr),
        .memory_data(main_data_out),
        .memory_data_valid(mainMemValid),
        .wrd_en(data_fsm_word_en),  //not in our module
        .stall(data_cache_stall), //not in our module
        .fsm_busy(data_fsm_busy)
    );

    assign dcache_stall   = data_fsm_busy | data_miss;
    assign memDataOut = data_miss ? 16'h0000 : (data_hit_way0 ? data_out_way0 : data_out_way1);


    // --- Instruction cache logic ---
    assign inst_offset = ins_addr[3:1];
    assign inst_index  = ins_addr[9:4];
    assign inst_tag    = ins_addr[15:10];

    blockEnable instBlockEn(
        .set_index(inst_index),
        .blockEn(inst_block_enable)
    );

    wordEnable instWordEn(
        .b_offset(inst_offset),
        .wordEn(inst_inst_word_enable)
    );

    assign inst_hit_way0 = (inst_tag == inst_meta_out_way0[7:2]) & inst_meta_out_way0[0];
    assign inst_hit_way1 = (inst_tag == inst_meta_out_way1[7:2]) & inst_meta_out_way1[0];
    assign inst_miss     = ~inst_hit_way0 & ~inst_hit_way1;

    assign inst_meta_in_way0 = ~inst_miss
        ? {inst_meta_out_way0[7:2], ~inst_hit_way0, inst_meta_out_way0[0]}
        : (~inst_meta_out_way0[1] ? {inst_tag, 1'b0, 1'b1} : inst_meta_out_way0);

    assign inst_meta_in_way1 = ~inst_miss
        ? {inst_meta_out_way1[7:2], ~inst_hit_way1, inst_meta_out_way1[0]}
        : ( inst_meta_out_way0[1] ? {inst_tag, 1'b0, 1'b1} : inst_meta_out_way1);

    assign inst_write_back = main_data_out;

    assign inst_meta_write_way0 = inst_fsm_meta_en;
    assign inst_meta_write_way1 = inst_fsm_meta_en;

    assign inst_word_enable = inst_miss ? inst_fsm_word_en : inst_inst_word_enable;

    icache instCache(
        .clk(clk), .rst(rst),
        .MetaDataIn1(inst_meta_in_way0), .MetaDataIn2(inst_meta_in_way1),
        .MetaWrite1(inst_meta_write_way0), .MetaWrite2(inst_meta_write_way1),
        .BlockEnable(inst_block_enable),
        .MetaDataOut1(inst_meta_out_way0), .MetaDataOut2(inst_meta_out_way1),
        .DataIn(inst_write_back),
        .DataWrite1(inst_fsm_data_en & ~inst_meta_out_way1[1] & inst_miss),
        .DataWrite2(inst_fsm_data_en &  inst_meta_out_way1[1] & inst_miss),
        .WordEnable(inst_word_enable),
        .DataOut1(inst_out_way0), .DataOut2(inst_out_way1)
    );

    cache_fill_FSM instCacheFSM(
        .clk(clk), .rst_n(~rst),
        .miss_detected(inst_miss & ~data_fsm_busy),
        .miss_address(ins_addr),
        .fsm_busy(inst_fsm_busy),
        .write_data_array(inst_fsm_data_en),
        .write_tag_array(inst_fsm_meta_en),
        .memory_address(inst_fsm_addr),
        .memory_data(main_data_out),
        .memory_data_valid(mainMemValid),
        .wrd_en(inst_fsm_word_en),
        .stall(inst_cache_stall)
    );

    assign icache_stall      = inst_cache_stall;
    assign instDataOut  = inst_miss ? 16'h0000 : (inst_hit_way0 ? inst_out_way0 : inst_out_way1);


    // --- Main memory arbitration ---
    assign mainMemAddr   = inst_miss ? inst_fsm_addr : (data_miss ? data_fsm_addr : mem_addr);
    assign mainMemEnable = (data_fsm_busy | inst_fsm_busy) & (data_miss | inst_miss | memWrite);
    assign mainMemWR     = memWrite & ~data_miss;


    // --- Main memory module ---
    memory4c mainMem(
        .data_out(main_data_out),
        .data_in(memDataIn),
        .addr(mainMemAddr),
        .enable(mainMemEnable | mainMemWR),
        .wr(mainMemWR),
        .clk(clk),
        .rst(rst),
        .data_valid(mainMemValid)
    );

endmodule
