`timescale 1ns/1ps

module butterfly_dit #(
    parameter DATA_WIDTH   = 16,
    parameter FACTOR_WIDTH = 16,
    parameter FRAC_BITS    = 14
)(
    input  wire                           clk,
    input  wire                           rst,
    input  wire [2*DATA_WIDTH-1:0]        in_x0,
    input  wire [2*DATA_WIDTH-1:0]        in_x1,
    input  wire [2*FACTOR_WIDTH-1:0]      w,
    output reg  [2*DATA_WIDTH-1:0]        out_x0,
    output reg  [2*DATA_WIDTH-1:0]        out_x1
);
    wire signed [DATA_WIDTH-1:0] x0_r = in_x0[2*DATA_WIDTH-1:DATA_WIDTH];
    wire signed [DATA_WIDTH-1:0] x0_i = in_x0[DATA_WIDTH-1:0];
    wire signed [DATA_WIDTH-1:0] x1_r = in_x1[2*DATA_WIDTH-1:DATA_WIDTH];
    wire signed [DATA_WIDTH-1:0] x1_i = in_x1[DATA_WIDTH-1:0];

    wire signed [FACTOR_WIDTH-1:0] w_r = w[2*FACTOR_WIDTH-1:FACTOR_WIDTH];
    wire signed [FACTOR_WIDTH-1:0] w_i = w[FACTOR_WIDTH-1:0];

    reg phase;
    reg signed [DATA_WIDTH-1:0] reg_x0_r, reg_x0_i;
    reg signed [DATA_WIDTH+FACTOR_WIDTH-1:0] p1, p2, p3, p4;
    reg signed [DATA_WIDTH-1:0] tw_r, tw_i;

    always @(posedge clk) begin
        if (rst) begin
            phase       <= 1'b0;
            reg_x0_r    <= {DATA_WIDTH{1'b0}};
            reg_x0_i    <= {DATA_WIDTH{1'b0}};
            p1          <= {(DATA_WIDTH+FACTOR_WIDTH){1'b0}};
            p2          <= {(DATA_WIDTH+FACTOR_WIDTH){1'b0}};
            p3          <= {(DATA_WIDTH+FACTOR_WIDTH){1'b0}};
            p4          <= {(DATA_WIDTH+FACTOR_WIDTH){1'b0}};
            tw_r        <= {DATA_WIDTH{1'b0}};
            tw_i        <= {DATA_WIDTH{1'b0}};
            out_x0      <= {(2*DATA_WIDTH){1'b0}};
            out_x1      <= {(2*DATA_WIDTH){1'b0}};
        end else begin
            if (!phase) begin
                reg_x0_r <= x0_r;
                reg_x0_i <= x0_i;
                p1       <= x1_r * w_r;
                p2       <= x1_i * w_i;
                p3       <= x1_r * w_i;
                p4       <= x1_i * w_r;
            end else begin
                tw_r <= p1[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS] - p2[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS];
                tw_i <= p3[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS] + p4[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS];

                out_x0[2*DATA_WIDTH-1:DATA_WIDTH] <= reg_x0_r + (p1[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS] - p2[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS]);
                out_x0[DATA_WIDTH-1:0]            <= reg_x0_i + (p3[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS] + p4[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS]);
                out_x1[2*DATA_WIDTH-1:DATA_WIDTH] <= reg_x0_r - (p1[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS] - p2[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS]);
                out_x1[DATA_WIDTH-1:0]            <= reg_x0_i - (p3[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS] + p4[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS]);
            end

            phase <= ~phase;
        end
    end
endmodule
