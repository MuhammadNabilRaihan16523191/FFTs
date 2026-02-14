`timescale 1ns/1ps

module top_fft_dit_hold2 #(
    parameter N          = 16,
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 14,
    parameter ADDR_WIDTH = $clog2(N)
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         en,
    input  wire [1:0]                   mode,
    input  wire signed [DATA_WIDTH-1:0] x_in_ext,

    output reg                          done,
    output reg  [3:0]                   state_dbg,
    output reg  [ADDR_WIDTH-1:0]        rd_addr_dbg,
    output reg  [ADDR_WIDTH-1:0]        wr_addr_dbg,
    output reg  [ADDR_WIDTH-1:0]        pair_idx_dbg,
    output wire [2*DATA_WIDTH-1:0]      x0_hold_dbg,
    output wire [2*DATA_WIDTH-1:0]      x1_hold_dbg,
    output wire [2*DATA_WIDTH-1:0]      y0_dbg,
    output wire [2*DATA_WIDTH-1:0]      y1_dbg
);
    localparam S_IDLE  = 4'd0;
    localparam S_LOAD  = 4'd1;
    localparam S_RD0   = 4'd2;
    localparam S_CAP   = 4'd3;
    localparam S_BF0   = 4'd6;
    localparam S_BF1   = 4'd7;
    localparam S_WR0   = 4'd8;
    localparam S_WR1   = 4'd9;
    localparam S_DONE  = 4'd10;

    reg [ADDR_WIDTH-1:0] load_idx;
    reg [ADDR_WIDTH-1:0] pair_idx;
    reg                  sample_phase;

    reg                   ram_wr_en;
    reg [ADDR_WIDTH-1:0]  ram_rd_addr;
    reg [ADDR_WIDTH-1:0]  ram_wr_addr;
    reg [2*DATA_WIDTH-1:0] ram_wr_in;
    wire [2*DATA_WIDTH-1:0] ram_rd_out;

    wire                   feeder_en;
    wire [2*DATA_WIDTH-1:0] x0_hold;
    wire [2*DATA_WIDTH-1:0] x1_hold;
    wire                    feeder_pair_valid;

    reg                    bfly_rst;
    wire [2*DATA_WIDTH-1:0] y0;
    wire [2*DATA_WIDTH-1:0] y1;

    localparam signed [DATA_WIDTH-1:0] W_ONE = (1 <<< FRAC_BITS);
    wire [2*DATA_WIDTH-1:0] w_const = {W_ONE, {DATA_WIDTH{1'b0}}};

    assign x0_hold_dbg = x0_hold;
    assign x1_hold_dbg = x1_hold;
    assign y0_dbg      = y0;
    assign y1_dbg      = y1;
    assign feeder_en   = (state_dbg == S_CAP);

    butterfly_feeder #(
        .DATA_WIDTH(DATA_WIDTH)
    ) feeder_i (
        .clk(clk),
        .rst(rst),
        .en(feeder_en),
        .sel(sample_phase),
        .ram_data(ram_rd_out),
        .x0(x0_hold),
        .x1(x1_hold),
        .pair_valid(feeder_pair_valid)
    );

    dual_port_ram #(
        .DATA_WIDTH(2*DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) mem_i (
        .clk(clk),
        .wr_en(ram_wr_en),
        .wr_addr(ram_wr_addr),
        .rd_addr(ram_rd_addr),
        .wr_in(ram_wr_in),
        .rd_out(ram_rd_out)
    );

    butterfly_dit #(
        .DATA_WIDTH(DATA_WIDTH),
        .FACTOR_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) bfly_i (
        .clk(clk),
        .rst(bfly_rst),
        .in_x0(x0_hold),
        .in_x1(x1_hold),
        .w(w_const),
        .out_x0(y0),
        .out_x1(y1)
    );

    always @(posedge clk) begin
        if (rst) begin
            state_dbg    <= S_IDLE;
            done         <= 1'b0;
            load_idx     <= {ADDR_WIDTH{1'b0}};
            pair_idx     <= {ADDR_WIDTH{1'b0}};
            sample_phase <= 1'b0;
            ram_wr_en    <= 1'b0;
            ram_rd_addr  <= {ADDR_WIDTH{1'b0}};
            ram_wr_addr  <= {ADDR_WIDTH{1'b0}};
            ram_wr_in    <= {(2*DATA_WIDTH){1'b0}};
            bfly_rst     <= 1'b1;
            rd_addr_dbg  <= {ADDR_WIDTH{1'b0}};
            wr_addr_dbg  <= {ADDR_WIDTH{1'b0}};
            pair_idx_dbg <= {ADDR_WIDTH{1'b0}};
        end else begin
            ram_wr_en   <= 1'b0;
            bfly_rst    <= 1'b0;
            rd_addr_dbg <= ram_rd_addr;
            wr_addr_dbg <= ram_wr_addr;
            pair_idx_dbg <= pair_idx;

            case (state_dbg)
                S_IDLE: begin
                    done <= 1'b0;
                    if (en && mode == 2'b01) begin
                        load_idx  <= {ADDR_WIDTH{1'b0}};
                        state_dbg <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    ram_wr_en   <= 1'b1;
                    ram_wr_addr <= load_idx;
                    ram_wr_in   <= {x_in_ext, {DATA_WIDTH{1'b0}}};
                    if (load_idx == N-1) begin
                        pair_idx    <= {ADDR_WIDTH{1'b0}};
                        sample_phase <= 1'b0;
                        state_dbg   <= S_RD0;
                    end else begin
                        load_idx <= load_idx + 1'b1;
                    end
                end

                S_RD0: begin
                    ram_rd_addr <= (pair_idx << 1) + sample_phase;
                    state_dbg   <= S_CAP;
                end

                S_CAP: begin
                    if (sample_phase) begin
                        sample_phase <= 1'b0;
                        if (feeder_pair_valid) begin
                            bfly_rst  <= 1'b1;
                            state_dbg <= S_BF0;
                        end else begin
                            state_dbg <= S_CAP;
                        end
                    end else begin
                        sample_phase <= 1'b1;
                        state_dbg    <= S_RD0;
                    end
                end

                S_BF0: begin
                    state_dbg <= S_BF1;
                end

                S_BF1: begin
                    state_dbg <= S_WR0;
                end

                S_WR0: begin
                    ram_wr_en   <= 1'b1;
                    ram_wr_addr <= pair_idx << 1;
                    ram_wr_in   <= y0;
                    state_dbg   <= S_WR1;
                end

                S_WR1: begin
                    ram_wr_en   <= 1'b1;
                    ram_wr_addr <= (pair_idx << 1) + 1'b1;
                    ram_wr_in   <= y1;
                    if (pair_idx == (N/2)-1) begin
                        state_dbg <= S_DONE;
                    end else begin
                        pair_idx  <= pair_idx + 1'b1;
                        state_dbg <= S_RD0;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    if (!en || mode == 2'b00) begin
                        state_dbg <= S_IDLE;
                    end
                end

                default: begin
                    state_dbg <= S_IDLE;
                end
            endcase
        end
    end
endmodule
