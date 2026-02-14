`timescale 1ns/1ps

module butterfly_feeder #(
    parameter DATA_WIDTH = 16
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire                      en,
    input  wire                      sel,
    input  wire [2*DATA_WIDTH-1:0]   ram_data,
    output reg  [2*DATA_WIDTH-1:0]   x0,
    output reg  [2*DATA_WIDTH-1:0]   x1,
    output wire                      pair_valid
);
    reg [2*DATA_WIDTH-1:0] x0_stage0;
    assign pair_valid = en && sel;

    always @(posedge clk) begin
        if (rst) begin
            x0_stage0  <= {(2*DATA_WIDTH){1'b0}};
            x0        <= {(2*DATA_WIDTH){1'b0}};
            x1        <= {(2*DATA_WIDTH){1'b0}};
        end else begin
            if (en) begin
                if (!sel) begin
                    x0_stage0 <= ram_data;
                end else begin
                    x0 <= x0_stage0;
                    x1 <= ram_data;
                end
            end
        end
    end
endmodule
