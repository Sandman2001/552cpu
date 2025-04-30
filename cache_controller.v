/**
 * Cache Controller Module
 *
 * Interfaces between the CPU pipeline stages (IF, MEM), I-Cache, D-Cache,
 * and Main Memory. Handles cache lookups, miss detection, fill operations
 * (using cache_fill_FSM), write-through policy, and memory arbitration.
 */
module cache_controller (
    input         clk,
    input         rst, // Active high reset

    // Interface from Pipeline (MEM stage for D$, IF stage for I$)
    input         dcache_memRead,     // Read request to D-Cache
    input         dcache_memWrite,    // Write request to D-Cache
    input  [15:0] dcache_addr,        // Address for D-Cache access (from MEM stage)
    input  [15:0] dcache_dataIn,      // Data to write to D-Cache (from MEM stage)
    input  [15:0] icache_addr,        // Address for I-Cache access (from IF stage)

    // Interface to Pipeline (MEM stage for D$, IF stage for I$)
    output [15:0] dcache_dataOut,     // Data read from D-Cache (to MEM stage)
    output [15:0] icache_dataOut,     // Data read from I-Cache (to IF stage)
    output        icache_stall,       // Stall signal for IF stage
    output        dcache_stall        // Stall signal for MEM stage (and upstream)
);

    //--------------------------------------------------------------------------
    // Internal Wires & Signals
    //--------------------------------------------------------------------------

    // --- D-Cache Signals ---
    wire [5:0]  dcache_index;
    wire [2:0]  dcache_offset;        // Offset within block requested by CPU
    wire [7:0]  dcache_tag;
    wire        dcache_hit_way0;
    wire        dcache_hit_way1;
    wire        dcache_miss;
    wire [7:0]  dcache_meta_out_way0; // {tag[7:2], LRU(1bit), valid(1bit)}
    wire [7:0]  dcache_meta_out_way1;
    wire [15:0] dcache_data_out_way0;
    wire [15:0] dcache_data_out_way1;
    wire [7:0]  dcache_meta_in_way0;
    wire [7:0]  dcache_meta_in_way1;
    wire        dcache_meta_write_way0;
    wire        dcache_meta_write_way1;
    wire [15:0] dcache_data_in_muxed; // Data input to cache (from CPU or Memory)
    wire        dcache_data_write_way0;
    wire        dcache_data_write_way1;
    wire [63:0] dcache_block_enable;  // One-hot enable for the cache set
    wire [7:0]  dcache_req_word_en;   // Word enable based on CPU request offset
    wire [7:0]  dcache_fsm_word_en;   // Word enable based on FSM fill offset
    wire [7:0]  dcache_word_enable_muxed; // Selected word enable for cache write

    // --- D-Cache Fill FSM Signals ---
    wire        dcache_fsm_busy;
    wire        dcache_fsm_write_data; // FSM signals data word is ready
    wire        dcache_fsm_write_tag;  // FSM signals block fill complete
    wire [15:0] dcache_fsm_mem_addr;   // Address FSM wants to read from memory
    wire [15:0] dcache_fsm_cache_addr; // Address FSM is writing back to cache
    wire [2:0]  dcache_fsm_offset;     // Offset FSM is writing back to cache

    // --- I-Cache Signals ---
    wire [5:0]  icache_index;
    wire [2:0]  icache_offset;        // Offset within block requested by CPU
    wire [7:0]  icache_tag;
    wire        icache_hit_way0;
    wire        icache_hit_way1;
    wire        icache_miss;
    wire [7:0]  icache_meta_out_way0; // {tag[7:2], LRU(1bit), valid(1bit)}
    wire [7:0]  icache_meta_out_way1;
    wire [15:0] icache_data_out_way0;
    wire [15:0] icache_data_out_way1;
    wire [7:0]  icache_meta_in_way0;
    wire [7:0]  icache_meta_in_way1;
    wire        icache_meta_write_way0;
    wire        icache_meta_write_way1;
    wire [15:0] icache_data_in_from_mem; // Data input to cache (always from Memory)
    wire        icache_data_write_way0;
    wire        icache_data_write_way1;
    wire [63:0] icache_block_enable;  // One-hot enable for the cache set
    wire [7:0]  icache_req_word_en;   // Word enable based on CPU request offset
    wire [7:0]  icache_fsm_word_en;   // Word enable based on FSM fill offset
    wire [7:0]  icache_word_enable_muxed; // Selected word enable for cache write

    // --- I-Cache Fill FSM Signals ---
    wire        icache_fsm_busy;
    wire        icache_fsm_write_data; // FSM signals data word is ready
    wire        icache_fsm_write_tag;  // FSM signals block fill complete
    wire [15:0] icache_fsm_mem_addr;   // Address FSM wants to read from memory
    wire [15:0] icache_fsm_cache_addr; // Address FSM is writing back to cache
    wire [2:0]  icache_fsm_offset;     // Offset FSM is writing back to cache

    // --- Memory Interface Signals ---
    wire [15:0] mem_data_from_memory; // Data coming from main memory
    wire [15:0] mem_addr_to_memory;   // Address going to main memory
    wire        mem_enable;           // Memory chip enable
    wire        mem_write_enable;     // Memory write enable (for write-through)
    wire        mem_data_valid;       // Signal from memory indicating valid data


    //--------------------------------------------------------------------------
    // D-Cache Logic
    //--------------------------------------------------------------------------

    // Address Decomposition
    assign dcache_offset = dcache_addr[3:1];
    assign dcache_index  = dcache_addr[9:4];
    assign dcache_tag    = dcache_addr[15:10]; // Assuming tag is bits 15:10 based on index/offset

    // Generate block enable (selects the set in the cache array)
    blockEnable dataBlockEn (.set_index(dcache_index), .blockEn(dcache_block_enable));

    // Generate word enable based on CPU request address offset
    wordEnable dataReqWordEn (.b_offset(dcache_offset), .wordEn(dcache_req_word_en));

    // Hit Detection (Check tag and valid bit for both ways)
    // Assuming Metadata format: {tag[5:0], LRU[1], Valid[0]} based on 8-bit width shown before
    // Adjust slicing if metadata format is different (e.g., D_MetaDataOut1[7:2] for 6-bit tag)
    assign dcache_hit_way0 = (dcache_tag == dcache_meta_out_way0[7:2]) & dcache_meta_out_way0[0];
    assign dcache_hit_way1 = (dcache_tag == dcache_meta_out_way1[7:2]) & dcache_meta_out_way1[0];
    assign dcache_miss     = ~(dcache_hit_way0 | dcache_hit_way1) & (dcache_memRead | dcache_memWrite); // Miss only if access requested

    // Metadata Input Logic (Update LRU on hit, set Tag/Valid/LRU on miss based on LRU state)
    // Way 0 is LRU if dcache_meta_out_way0[1] == 1
    assign dcache_meta_in_way0 = ~dcache_miss
                                    ? {dcache_meta_out_way0[7:2], dcache_hit_way1, dcache_meta_out_way0[0]} // Hit: Update LRU (way0 used -> way1 is LRU)
                                    : (dcache_meta_out_way0[1])                                            // Miss: Check if Way 0 is LRU
                                        ? {dcache_tag, 1'b0, 1'b1}                                         //       Yes: Write new tag, set valid, clear LRU (way0 used)
                                        : dcache_meta_out_way0;                                            //       No: Keep Way 0 as is
    assign dcache_meta_in_way1 = ~dcache_miss
                                    ? {dcache_meta_out_way1[7:2], dcache_hit_way0, dcache_meta_out_way1[0]} // Hit: Update LRU (way1 used -> way0 is LRU)
                                    : (~dcache_meta_out_way0[1])                                           // Miss: Check if Way 1 is LRU (i.e. Way 0 not LRU)
                                        ? {dcache_tag, 1'b0, 1'b1}                                         //       Yes: Write new tag, set valid, clear LRU (way1 used)
                                        : dcache_meta_out_way1;                                            //       No: Keep Way 1 as is

    // Metadata Write Enable (Only enable write when FSM signals fill completion)
    assign dcache_meta_write_way0 = dcache_fsm_write_tag;
    assign dcache_meta_write_way1 = dcache_fsm_write_tag;

    // Data Input Mux (Select data from CPU for writes on hit, or from Memory on miss fill)
    assign dcache_data_in_muxed = (dcache_miss) ? mem_data_from_memory : dcache_dataIn;

    // Generate word enable based on FSM cache address offset during fill
    assign dcache_fsm_offset = dcache_fsm_cache_addr[3:1];
    wordEnable dataFSMWordEn (.b_offset(dcache_fsm_offset), .wordEn(dcache_fsm_word_en));

    // Select appropriate word enable for the cache data array
    assign dcache_word_enable_muxed = (dcache_miss) ? dcache_fsm_word_en : dcache_req_word_en;

    // Data Write Enable Logic
    // Write on miss fill: If FSM provides data AND this way is the LRU way being replaced.
    // Write on hit: If CPU requests write AND it's a hit on this way.
    assign dcache_data_write_way0 = (dcache_fsm_write_data & dcache_meta_out_way0[1] & dcache_miss)  // Fill way 0 if it's LRU
                                  | (dcache_memWrite & dcache_hit_way0);                           // Write hit way 0
    assign dcache_data_write_way1 = (dcache_fsm_write_data & ~dcache_meta_out_way0[1] & dcache_miss) // Fill way 1 if it's LRU
                                  | (dcache_memWrite & dcache_hit_way1);                           // Write hit way 1

    // D-Cache Instance
    dcache dataCache (
        .clk(clk),
        .rst(rst),
        .MetaDataIn1(dcache_meta_in_way0), // Metadata input for way 0
        .MetaDataIn2(dcache_meta_in_way1), // Metadata input for way 1
        .MetaWrite1(dcache_meta_write_way0), // Metadata write enable for way 0
        .MetaWrite2(dcache_meta_write_way1), // Metadata write enable for way 1
        .BlockEnable(dcache_block_enable), // Set selector
        .MetaDataOut1(dcache_meta_out_way0), // Metadata output from way 0
        .MetaDataOut2(dcache_meta_out_way1), // Metadata output from way 1
        .DataIn(dcache_data_in_muxed),     // Data input (muxed)
        .DataWrite1(dcache_data_write_way0), // Data write enable for way 0
        .DataWrite2(dcache_data_write_way1), // Data write enable for way 1
        .WordEnable(dcache_word_enable_muxed), // Word selector within the block
        .DataOut1(dcache_data_out_way0),   // Data output from way 0
        .DataOut2(dcache_data_out_way1)    // Data output from way 1
    );

    // D-Cache Fill FSM Instance (Handles fetching block from memory on miss)
    cache_fill_FSM dataCacheFSM (
        .clk(clk),
        .rst_n(~rst), // FSM uses active low reset
        .miss_detected(dcache_miss & ~icache_fsm_busy), // Detect miss only if I-cache FSM is not busy (arbitration)
        .miss_address(dcache_addr),   // Address that missed
        .memory_data_valid(mem_data_valid), // Valid signal from memory
        // Outputs from FSM
        .fsm_busy(dcache_fsm_busy),         // FSM is busy handling miss
        .write_data_array(dcache_fsm_write_data), // FSM has valid data word for cache
        .write_tag_array(dcache_fsm_write_tag),   // FSM finished filling block
        .memory_address(dcache_fsm_mem_addr),   // Address FSM wants from memory
        .cache_address(dcache_fsm_cache_addr)   // Address FSM is writing to cache (provides offset)
    );

    // D-Cache Output to CPU (Select data from correct way on hit, 0 on miss/stall)
    assign dcache_dataOut = dcache_miss ? 16'h0000 : (dcache_hit_way0 ? dcache_data_out_way0 : dcache_data_out_way1);

    // D-Cache Stall Signal (Stall if miss detected OR FSM is busy filling)
    assign dcache_stall = dcache_miss | dcache_fsm_busy;


    //--------------------------------------------------------------------------
    // I-Cache Logic
    //--------------------------------------------------------------------------

    // Address Decomposition
    assign icache_offset = icache_addr[3:1];
    assign icache_index  = icache_addr[9:4];
    assign icache_tag    = icache_addr[15:10]; // Assuming tag is bits 15:10

    // Generate block enable
    blockEnable instBlockEn (.set_index(icache_index), .blockEn(icache_block_enable));

    // Generate word enable based on CPU request address offset
    wordEnable instReqWordEn (.b_offset(icache_offset), .wordEn(icache_req_word_en));

    // Hit Detection
    assign icache_hit_way0 = (icache_tag == icache_meta_out_way0[7:2]) & icache_meta_out_way0[0];
    assign icache_hit_way1 = (icache_tag == icache_meta_out_way1[7:2]) & icache_meta_out_way1[0];
    assign icache_miss     = ~(icache_hit_way0 | icache_hit_way1); // I-cache always reads

    // Metadata Input Logic (Update LRU on hit, set Tag/Valid/LRU on miss)
    assign icache_meta_in_way0 = ~icache_miss
                                    ? {icache_meta_out_way0[7:2], icache_hit_way1, icache_meta_out_way0[0]}
                                    : (icache_meta_out_way0[1])
                                        ? {icache_tag, 1'b0, 1'b1}
                                        : icache_meta_out_way0;
    assign icache_meta_in_way1 = ~icache_miss
                                    ? {icache_meta_out_way1[7:2], icache_hit_way0, icache_meta_out_way1[0]}
                                    : (~icache_meta_out_way0[1])
                                        ? {icache_tag, 1'b0, 1'b1}
                                        : icache_meta_out_way1;

    // Metadata Write Enable
    assign icache_meta_write_way0 = icache_fsm_write_tag;
    assign icache_meta_write_way1 = icache_fsm_write_tag;

    // Data Input (Always comes from memory for I-Cache fills)
    assign icache_data_in_from_mem = mem_data_from_memory;

    // Generate word enable based on FSM cache address offset during fill
    assign icache_fsm_offset = icache_fsm_cache_addr[3:1];
    wordEnable instFSMWordEn (.b_offset(icache_fsm_offset), .wordEn(icache_fsm_word_en));

    // Select appropriate word enable for the cache data array
    // For I-cache, writes only happen on miss fill, so FSM word enable is used when writing.
    // Reads use the request offset implicitly within the cache module.
    assign icache_word_enable_muxed = icache_fsm_word_en; // Only FSM triggers writes

    // Data Write Enable Logic (Only write during miss fill when FSM provides data for the LRU way)
    assign icache_data_write_way0 = (icache_fsm_write_data & icache_meta_out_way0[1] & icache_miss);
    assign icache_data_write_way1 = (icache_fsm_write_data & ~icache_meta_out_way0[1] & icache_miss);

    // I-Cache Instance
    icache instCache (
        .clk(clk),
        .rst(rst),
        .MetaDataIn1(icache_meta_in_way0),
        .MetaDataIn2(icache_meta_in_way1),
        .MetaWrite1(icache_meta_write_way0),
        .MetaWrite2(icache_meta_write_way1),
        .BlockEnable(icache_block_enable),
        .MetaDataOut1(icache_meta_out_way0),
        .MetaDataOut2(icache_meta_out_way1),
        .DataIn(icache_data_in_from_mem), // Data always from memory
        .DataWrite1(icache_data_write_way0),
        .DataWrite2(icache_data_write_way1),
        .WordEnable(icache_word_enable_muxed), // Controls write location during fill
        .DataOut1(icache_data_out_way0),
        .DataOut2(icache_data_out_way1)
    );

    // I-Cache Fill FSM Instance
    cache_fill_FSM instCacheFSM (
        .clk(clk),
        .rst_n(~rst),
        .miss_detected(icache_miss & ~dcache_fsm_busy), // Detect miss only if D-cache FSM is not busy (arbitration)
        .miss_address(icache_addr),
        .memory_data_valid(mem_data_valid),
        // Outputs from FSM
        .fsm_busy(icache_fsm_busy),
        .write_data_array(icache_fsm_write_data),
        .write_tag_array(icache_fsm_write_tag),
        .memory_address(icache_fsm_mem_addr),
        .cache_address(icache_fsm_cache_addr)
    );

    // I-Cache Output to CPU
    assign icache_dataOut = icache_miss ? 16'h0000 : (icache_hit_way0 ? icache_data_out_way0 : icache_data_out_way1);

    // I-Cache Stall Signal (Stall only while FSM is busy filling)
    assign icache_stall = icache_fsm_busy;


    //--------------------------------------------------------------------------
    // Main Memory Interface Logic
    //--------------------------------------------------------------------------

    // Memory Address Mux (Prioritize I-Cache FSM, then D-Cache FSM, then D-Cache write-through)
    assign mem_addr_to_memory = icache_fsm_busy ? icache_fsm_mem_addr : // I-Cache miss fill
                                dcache_fsm_busy ? dcache_fsm_mem_addr : // D-Cache miss fill
                                dcache_memWrite ? dcache_addr :         // D-Cache write-through hit
                                16'hxxxx; // Default/inactive address (adjust as needed)

    // Memory Write Enable (Only for D-Cache write-through on hit)
    // Note: FSM handles reads only. Writes happen directly on hit for write-through.
    assign mem_write_enable = dcache_memWrite & ~dcache_miss;

    // Memory Enable (Enable memory if either FSM is busy OR a D-cache write-through is happening)
    assign mem_enable = icache_fsm_busy | dcache_fsm_busy | mem_write_enable;

    // Main Memory Instance (Using 4-cycle read latency version)
    memory4c mainMem (
        .data_out(mem_data_from_memory),
        .data_in(dcache_dataIn),      // Data for write-through comes from CPU
        .addr(mem_addr_to_memory),
        .enable(mem_enable),
        .wr(mem_write_enable),
        .clk(clk),
        .rst(rst),
        .data_valid(mem_data_valid)
    );

endmodule