`timescale 1ns/1ps

module top_fft_dit #(
    parameter N = 8192,
    parameter ADDR_WIDTH = $clog2(N)
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire [1:0]  mode,       // 0: Idle, 1: Calc, 2: Write
    
    // Output untuk monitoring/koneksi ke RAM & Butterfly
    output wire [1:0]  state,
    output wire [ADDR_WIDTH-1:0] rd_addr,
    output wire [ADDR_WIDTH-1:0] wr_addr,
    output wire [ADDR_WIDTH-2:0] k,
    output wire        ram_wr_en,  // Dari CU
    output wire        done        // Dari CU
);

    // --- Sinyal Internal ---
    wire cnt_en;
    wire point_count_rst, stage_count_rst;
    wire main_over;
    wire [ADDR_WIDTH-1:0] main_count;
    wire [$clog2(ADDR_WIDTH)-1:0] stage;
    wire stage_over; // Tidak dipakai langsung, tapi dari counter stage

    // --- 1. Control Unit (CU) ---
    // CU menerima stage untuk tahu kapan mencapai LAST_STAGE (12)
    cu_fft #(.N(N)) cu_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .mode(mode),
        .count_over(main_over),
        .stage(stage),
        .state(state),
        .point_count_rst(point_count_rst),
        .stage_count_rst(stage_count_rst),
        .wr_en(ram_wr_en),
        .done(done)
    );

    // --- 2. Main Counter (Point Counter 8192) ---
    counter #(.WIDTH(ADDR_WIDTH)) main_counter_inst (
        .clk(clk),
        .rst(point_count_rst), // Reset jika sistem rst atau CU rst
        .en(1'b1),
        .count(main_count),
        .count_over(main_over)
    );

    // --- 3. Stage Counter (Counter 13 Stage: 0-12) ---
    // Di-enable hanya saat main_counter overflow (setiap 8192 clock)
    counter #(.WIDTH($clog2(ADDR_WIDTH))) stage_counter_inst (
        .clk(clk),
        .rst(stage_count_rst),
        .en(main_over), 
        .count(stage),
        .count_over(stage_over)
    );

    // --- 4. Address Generator ---
    addr_gen_dit #(.ADDR_WIDTH(ADDR_WIDTH)) addr_gen_inst (
        .clk(clk),
        .rst(point_count_rst),
        .state(state),
        .count(main_count),
        .count_over(main_over),
        .stage(stage),
        .rd_addr(rd_addr),
        .wr_addr(wr_addr),
        .k(k)
    );

endmodule