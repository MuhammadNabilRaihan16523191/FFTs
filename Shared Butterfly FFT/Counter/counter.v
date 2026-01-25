`timescale 1ns/1ps

module counter #(
    parameter WIDTH = 13
)(
    input  wire              clk,
    input  wire              rst,
    input  wire              en,        

    output reg  [WIDTH-1:0]  count,     
    output reg               count_over 
);  
    wire [WIDTH:0] count_next = count + 1;
    assign count_over = count_next[WIDTH];

    always @(posedge clk) begin
        if (rst) begin
            count      <= 0;
            count_over <= 0;
        end else if (en) begin
            count      <= count_next[WIDTH-1:0];
        end
    end
endmodule