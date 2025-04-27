// mem_arbiter.v
// Arbitration between I-cache and D-cache requests to main memory
// 3-cycle D-cache priority window upon detecting a memory instruction in ID

module mem_arbiter (
    input        clk,
    input        rst_n,
    input        flush,

    // from ID?EX pipeline register
    input        dec_is_mem,      // 1 when load/store instruction
    input  [1:0] prio_count_in,

    // I-cache request
    input        i_req_valid,
    output       i_req_ready,
    input  [15:0] i_req_addr,
    input        i_req_rw,
    input  [15:0] i_req_wdata,

    // D-cache request
    input        d_req_valid,
    output       d_req_ready,
    input  [15:0] d_req_addr,
    input        d_req_rw,
    input  [15:0] d_req_wdata,

    // to memory
    output       mem_req_valid,
    input        mem_req_ready,
    output [15:0] mem_req_addr,
    output       mem_req_rw,
    output [15:0] mem_req_wdata,

    // next prio_count to pipeline register
    output [1:0] prio_count_out
);

// next priority count logic
wire [1:0] next_count;
assign next_count = flush ? 2'b00 :
                    dec_is_mem ? 2'b11 :
                    (prio_count_in == 2'b00) ? 2'b00 :
                    (prio_count_in == 2'b01) ? 2'b00 :
                    (prio_count_in == 2'b10) ? 2'b01 :
                                                2'b10;

// instantiate DFFs for prio_count
// provided dff module with synchronous reset
// ports: .d, .clk, .rst_n, .q

dff prio_count_bit1 (
    .d(next_count[1]),
    .clk(clk),
    .rst_n(rst_n),
    .q(prio_count_out[1])
);

dff prio_count_bit0 (
    .d(next_count[0]),
    .clk(clk),
    .rst_n(rst_n),
    .q(prio_count_out[0])
);

// grant logic
wire d_grant, i_grant;
assign d_grant = (d_req_valid & i_req_valid) ? (prio_count_in != 2'b00) : d_req_valid;
assign i_grant = (i_req_valid & d_req_valid) ? (prio_count_in == 2'b00) : i_req_valid;

// ready signaling
assign i_req_ready = i_grant & mem_req_ready;
assign d_req_ready = d_grant & mem_req_ready;

// memory request mux
assign mem_req_valid = (i_grant | d_grant) & mem_req_ready;
assign mem_req_addr  = i_grant ? i_req_addr  : d_req_addr;
assign mem_req_rw    = i_grant ? i_req_rw    : d_req_rw;
assign mem_req_wdata = i_grant ? i_req_wdata : d_req_wdata;

endmodule

