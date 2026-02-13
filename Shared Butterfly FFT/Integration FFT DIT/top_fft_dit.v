`timescale 1ns/1ps

module top_fft_dit #(
    parameter N = 8192,
    parameter ADDR_WIDTH = $clog2(N)
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire [1:0]            mode,       // 0: Idle, 1: Calc, 2: Write
    input  wire [15:0]           x_in_ext,   // Input 16-bit (Q2.14)
    
    // --- Output untuk Monitoring ---
    output wire [1:0]            state,
    output wire [ADDR_WIDTH-1:0] rd_addr,
    output wire [ADDR_WIDTH-1:0] wr_addr,
    output wire [ADDR_WIDTH-2:0] k,
    output wire [31:0]           w,
    output wire                  ram_wr_en,
    output wire                  done,
    output wire [$clog2(ADDR_WIDTH):0] stage, // Monitoring Stage (0-12)
    output wire [2*(16 + (1 << $clog2(ADDR_WIDTH)))-1:0] ram_dout // Monitoring RAM Out
);

    // --- Local Parameters untuk Internal Logic ---
    // bit_growth = 1 << 4 = 16
    // component_width = 16 + 16 = 32 bit
    // RAM_WIDTH = 2 * 32 = 64 bit
    localparam COMP_WIDTH = 16 + (1 << $clog2(ADDR_WIDTH)); 
    localparam RAM_WIDTH  = 2 * COMP_WIDTH;

    // --- Sinyal Internal ---
    wire main_over;
    wire [ADDR_WIDTH-1:0] main_count;
    wire stage_over;
    wire point_count_rst, stage_count_rst;
    wire [RAM_WIDTH-1:0] ram_din_ext;
    
    // --- Data Formatting ---
    // Konkat: [16-bit 0 | x_in_ext] [32-bit 0]
    assign ram_din_ext = { 16'h0000, x_in_ext, 32'h0000_0000 };

    // --- 1. Control Unit (CU) ---
    cu_fft #(.N(N)) cu_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .mode(mode),
        .count_over(main_over),
        .stage(stage), // Output ke port monitoring
        .state(state),
        .point_count_rst(point_count_rst),
        .stage_count_rst(stage_count_rst),
        .wr_en(ram_wr_en),
        .done(done)
    );

    // --- 2. Main Counter (8192) ---
    counter #(.WIDTH(ADDR_WIDTH)) main_counter_inst (
        .clk(clk),
        .rst(point_count_rst),
        .en(1'b1),
        .count(main_count),
        .count_over(main_over)
    );

    // --- 3. Stage Counter (13 Stages) ---
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

    // --- 5. RAM Complex (Dual Port) ---
    dual_port_ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(RAM_WIDTH)
    ) ram_inst (
        .clk(clk),
        .wr_en(ram_wr_en),
        .rd_addr(rd_addr),
        .wr_addr(wr_addr),
        .wr_in(ram_din_ext), 
        .rd_out(ram_dout)
    );
    
    w_gen #(
        .DATA_WIDTH(16),
        .N(N),
        .FRAC_BITS(14),
        .LUT_FILE("quarter_sine_lut_8192.mem")
    ) twiddle_generator (
        .clk(clk),
        .rst(rst),
        .k(k),
        .w(w)
    );
    
endmodule