`timescale 1ns/1ps

module w_gen #(
    parameter DATA_WIDTH = 16,  
    parameter ADDR_WIDTH = 11, 
    parameter FRAC_BITS  = 14,
    parameter LUT_FILE   = "sine_lut_8192.mem"
)(
    input  wire                             clk,
    input  wire                             rst, 
    input  wire         [ADDR_WIDTH+1:0]    k,   
    
    output wire signed  [2*DATA_WIDTH-1:0]  w
);
// Sine LUT
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] sine_lut [0:(1<<ADDR_WIDTH)-1];
    initial begin
        $readmemh(LUT_FILE, sine_lut);
    end

// Pipeline Stage 0
    reg [ADDR_WIDTH-1:0] reg_k_direct;
    reg [ADDR_WIDTH-1:0] reg_k_inv;
    reg [1:0]            reg_k_quad;

    always @(posedge clk) begin
        if (rst) begin
            reg_k_direct    <= 0;
            reg_k_inv       <= 0;
            reg_k_quad      <= 0;
        end else begin
            reg_k_direct    <= k[ADDR_WIDTH-1:0];           
            reg_k_inv       <= -k[ADDR_WIDTH-1:0];  
            reg_k_quad      <= k[ADDR_WIDTH+1:ADDR_WIDTH];
        end
    end

// Pipeline Stage 1
    reg         val_inv_sel;
    reg [1:0]   quadrant;

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
        val_direct  <= reg_val_direct;
        val_inv     <= (val_inv_sel) ? reg_val_inv : ONE;

        case (quadrant) 
            2'b00: begin // Kuadran 1
                w_r <= val_inv;       // Re = cos(k')
                w_i <= -val_direct;   // Im = -sin(k')
            end
            2'b01: begin // Kuadran 2
                w_r <= -val_direct;   // Re = -sin(k')
                w_i <= -val_inv;      // Im = -cos(k')
            end
            2'b10: begin // Kuadran 3
                w_r <= -val_inv;      // Re = -cos(k')
                w_i <= val_direct;    // Im = sin(k')
            end
            2'b11: begin // Kuadran 4
                w_r <= val_direct;    // Re = sin(k')
                w_i <= val_inv;       // Im = cos(k')
            end
            default: begin
                w_r <= 0;
                w_i <= 0;
            end
        endcase
    end

    assign w = {w_r, w_i};
endmodule