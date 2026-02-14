`timescale 1ns/1ps

module tb_top_fft_dit_hold2;
    parameter N          = 16;
    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = $clog2(N);
    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst;
    reg en;
    reg [1:0] mode;
    reg signed [DATA_WIDTH-1:0] x_in_ext;

    wire done;
    wire [3:0] state_dbg;
    wire [ADDR_WIDTH-1:0] rd_addr_dbg;
    wire [ADDR_WIDTH-1:0] wr_addr_dbg;
    wire [ADDR_WIDTH-1:0] pair_idx_dbg;
    wire [2*DATA_WIDTH-1:0] x0_hold_dbg;
    wire [2*DATA_WIDTH-1:0] x1_hold_dbg;
    wire [2*DATA_WIDTH-1:0] y0_dbg;
    wire [2*DATA_WIDTH-1:0] y1_dbg;

    localparam S_WR1 = 4'd9;

    top_fft_dit_hold2 #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .mode(mode),
        .x_in_ext(x_in_ext),
        .done(done),
        .state_dbg(state_dbg),
        .rd_addr_dbg(rd_addr_dbg),
        .wr_addr_dbg(wr_addr_dbg),
        .pair_idx_dbg(pair_idx_dbg),
        .x0_hold_dbg(x0_hold_dbg),
        .x1_hold_dbg(x1_hold_dbg),
        .y0_dbg(y0_dbg),
        .y1_dbg(y1_dbg)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    integer n;
    integer fd_pair;
    initial begin
        $dumpfile("tb_top_fft_dit_hold2.vcd");
        $dumpvars(0, tb_top_fft_dit_hold2);
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        en  = 1'b0;
        mode = 2'b00;
        x_in_ext = {DATA_WIDTH{1'b0}};

        fd_pair = $fopen("top_fft_pair_results.csv", "w");
        $fdisplay(fd_pair, "pair,y0_hex,y1_hex,y0_r,y0_i,y1_r,y1_i");

        #(5*CLK_PERIOD);
        rst  = 1'b0;
        en   = 1'b1;
        mode = 2'b01;

        for (n = 0; n < N; n = n + 1) begin
            x_in_ext = n;
            #(CLK_PERIOD);
        end

        wait(done == 1'b1);
        $display("Simulation done at t=%0t", $time);
        $fclose(fd_pair);
        #(5*CLK_PERIOD);
        $finish;
    end

    always @(posedge clk) begin
        $display("t=%0t state=%0d pair=%0d rd=%0d wr=%0d x0=%h x1=%h y0=%h y1=%h done=%b",
                 $time, state_dbg, pair_idx_dbg, rd_addr_dbg, wr_addr_dbg,
                 x0_hold_dbg, x1_hold_dbg, y0_dbg, y1_dbg, done);

        if (state_dbg == S_WR1) begin
            $fdisplay(fd_pair, "%0d,%08h,%08h,%0d,%0d,%0d,%0d",
                      pair_idx_dbg,
                      y0_dbg,
                      y1_dbg,
                      $signed(y0_dbg[2*DATA_WIDTH-1:DATA_WIDTH]),
                      $signed(y0_dbg[DATA_WIDTH-1:0]),
                      $signed(y1_dbg[2*DATA_WIDTH-1:DATA_WIDTH]),
                      $signed(y1_dbg[DATA_WIDTH-1:0]));
        end
    end

    initial begin
        #200000;
        $display("Timeout");
        $finish;
    end
endmodule
