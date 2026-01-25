`timescale 1ns/1ps

module dual_port_ram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 13 
)(
    input  wire                   clk,
    input  wire                   wr_en, 

    input  wire [ADDR_WIDTH-1:0]  wr_addr, 
    input  wire [ADDR_WIDTH-1:0]  rd_addr, 
    
    input  wire [DATA_WIDTH-1:0]  wr_in,   
    output reg  [DATA_WIDTH-1:0]  rd_out   
);
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

// Write Port
    always @(posedge clk) begin
        if (wr_en) begin
            ram[wr_addr] <= wr_in;
        end
    end

// Read Port
    always @(posedge clk) begin
        rd_out <= ram[rd_addr];
    end
endmodule