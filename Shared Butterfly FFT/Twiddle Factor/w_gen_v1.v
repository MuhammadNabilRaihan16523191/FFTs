`timescale 1ns/1ps

module w_gen #(
    parameter DATA_WIDTH = 16,  
    parameter N          = 8192,
    parameter FRAC_BITS  = 14,
    parameter LUT_FILE   = "quarter_sine_lut_8192.mem"
)(
    input  wire                             clk,
    input  wire                             rst, 
    input  wire         [$clog2(N/2)-1:0]   k,   
    
    output wire signed  [2*DATA_WIDTH-1:0]  w
);
// Sine LUT
    localparam LUT_ADDR_WIDTH = $clog2(N/4);
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] sine_lut [0:(1<<LUT_ADDR_WIDTH)-1];
    initial begin
        $readmemh(LUT_FILE, sine_lut);
    end

// Pipeline Stage 0
    reg [LUT_ADDR_WIDTH-1:0] reg_k_direct;
    reg [LUT_ADDR_WIDTH-1:0] reg_k_inv;
    reg                      reg_k_quad;

    always @(posedge clk) begin
        if (rst) begin
            reg_k_direct    <= 0;
            reg_k_inv       <= 0;
            reg_k_quad      <= 0;
        end else begin
            reg_k_direct    <= k[LUT_ADDR_WIDTH-1:0];           
            reg_k_inv       <= -k[LUT_ADDR_WIDTH-1:0];  
            reg_k_quad      <= k[LUT_ADDR_WIDTH];
        end
    end

// Pipeline Stage 1
    reg val_inv_sel;
    reg quadrant;

    reg signed [DATA_WIDTH-1:0] reg_val_direct;
    reg signed [DATA_WIDTH-1:0] reg_val_inv;
    
    always @(posedge clk) begin
        if (rst) begin
            val_inv_sel     <= 0;
            quadrant        <= 0;

            reg_val_direct  <= 0;
            reg_val_inv     <= 0;
        end else begin 
            val_inv_sel     <= |reg_k_direct;
            quadrant        <= reg_k_quad;

            reg_val_direct  <= sine_lut[reg_k_direct];
            reg_val_inv     <= sine_lut[reg_k_inv];
        end
    end

// Output Mapping
    localparam ONE = (1 << FRAC_BITS);
    reg signed [DATA_WIDTH-1:0] val_direct, val_inv;

    reg signed [DATA_WIDTH-1:0] w_r, w_i;

    always @(*) begin
        val_direct  = reg_val_direct;
        val_inv     = (val_inv_sel) ? reg_val_inv : ONE;

        case (quadrant) 
            1'b0: begin // Kuadran 1
                w_r = val_inv;       // Re = cos(k')
                w_i = -val_direct;   // Im = -sin(k')
            end
            1'b1: begin // Kuadran 2
                w_r = -val_direct;   // Re = -sin(k')
                w_i = -val_inv;      // Im = -cos(k')
            end
            default: begin
                w_r = 0;
                w_i = 0;
            end
        endcase
    end

    assign w = {w_r, w_i};
endmodule