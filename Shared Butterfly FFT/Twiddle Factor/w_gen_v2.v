`timescale 1ns/1ps

module w_gen #(
    parameter DATA_WIDTH = 16,  
    parameter N          = 8192,
    parameter FRAC_BITS  = 14,
    parameter LUT_FILE   = "sine_lut_8192.mem"
)(
    input  wire                             clk,
    input  wire                             rst, 
    input  wire         [$clog2(N/2)-1:0]   k,   
    
    output wire signed  [2*DATA_WIDTH-1:0]  w
);
// Sine LUT
    localparam LUT_ADDR_WIDTH = $clog2(N) - 2;
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] sine_lut [0:(1<<LUT_ADDR_WIDTH)-1];
    initial begin
        $readmemh(LUT_FILE, sine_lut);
    end

// Assign LUT Address and Inverse
    reg [LUT_ADDR_WIDTH-1:0] k_direct;
    reg [LUT_ADDR_WIDTH-1:0] k_inv;
    reg                      k_quad;

    always @(posedge clk) begin
        if (rst) begin
            k_direct <= 0;
            k_inv <= 0;
            k_quad <= 0;
        end else begin
            k_direct   <= k[ADDR_WIDTH-1:0];           
            k_inv      <= -k[ADDR_WIDTH-1:0];  
            k_quad     <= k[ADDR_WIDTH+1:ADDR_WIDTH];
        end
    end

// Output Mapping
    localparam ONE = (1 << FRAC_BITS);
    reg signed [DATA_WIDTH-1:0] w_r, w_i;

    always @(posedge clk) begin
        if (rst) begin 
            w_r <= 0;
            w_i <= 0;
        end else begin
            case (k_quad) 
                2'b00: begin // Kuadran 1
                    w_r <= (|k_direct) ? sine_lut[k_inv[10:0]] : ONE; // Re = cos(k')
                    w_i <= -sine_lut[k_direct];   // Im = -sin(k')
                end
                2'b01: begin // Kuadran 2
                    w_r <= -sine_lut[k_direct];   // Re = -sin(k')
                    w_i <= -((|k_direct) ? sine_lut[k_inv[10:0]] : ONE); // Im = -cos(k')
                end
                2'b10: begin // Kuadran 3
                    w_r <= -((|k_direct) ? sine_lut[k_inv[10:0]] : ONE); // Re = -cos(k')
                    w_i <= sine_lut[k_direct];    // Im = sin(k')
                end
                2'b11: begin // Kuadran 4
                    w_r <= sine_lut[k_direct];    // Re = sin(k')
                    w_i <= (|k_direct) ? sine_lut[k_inv[10:0]] : ONE; // Im = cos(k')
                end
                default: begin
                    w_r <= 0;
                    w_i <= 0;
                end
            endcase
        end
    end

    assign w = {w_r, w_i};
endmodule