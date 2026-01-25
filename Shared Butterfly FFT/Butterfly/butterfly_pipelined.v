module butterfly_pipelined #(
    parameter DATA_WIDTH   = 32,
    parameter FACTOR_WIDTH = 16,
    parameter FRAC_BITS    = 14 
) (
    input   wire                        clk,
    input   wire                        rst,

    input   wire [2*DATA_WIDTH-1:0]     in_x0, // {Real, Imag}
    input   wire [2*DATA_WIDTH-1:0]     in_x1, // {Real, Imag}
    input   wire [2*FACTOR_WIDTH-1:0]   w,     // {Real, Imag}
    
    output  reg  [2*DATA_WIDTH-1:0]     out_x0,
    output  reg  [2*DATA_WIDTH-1:0]     out_x1
);

    // ---------------------------------------------------------
    // STAGE 0: Input Registers
    // ---------------------------------------------------------
    reg signed [DATA_WIDTH-1:0]   s0_x0_r, s0_x0_i;
    reg signed [DATA_WIDTH-1:0]   s0_x1_r, s0_x1_i;
    reg signed [FACTOR_WIDTH-1:0] s0_w_r,  s0_w_i;

    always @(posedge clk) begin
        if (!rst) begin
            s0_x0_r <= 0; s0_x0_i <= 0;
            s0_x1_r <= 0; s0_x1_i <= 0;
            s0_w_r  <= 0; s0_w_i  <= 0;
        end else begin
            s0_x0_r <= in_x0[2*DATA_WIDTH-1 : DATA_WIDTH];
            s0_x0_i <= in_x0[DATA_WIDTH-1 : 0];
            s0_x1_r <= in_x1[2*DATA_WIDTH-1 : DATA_WIDTH];
            s0_x1_i <= in_x1[DATA_WIDTH-1 : 0];
            s0_w_r  <= w[2*FACTOR_WIDTH-1 : FACTOR_WIDTH];
            s0_w_i  <= w[FACTOR_WIDTH-1 : 0];
        end
    end

    // ---------------------------------------------------------
    // STAGE 1: Multiplier Output Registers
    // ---------------------------------------------------------
    reg signed [DATA_WIDTH+FACTOR_WIDTH-1:0] s1_prod_rr, s1_prod_ii;
    reg signed [DATA_WIDTH+FACTOR_WIDTH-1:0] s1_prod_ri, s1_prod_ir;
    
    reg signed [DATA_WIDTH-1:0] s1_x0_r, s1_x0_i;

    always @(posedge clk) begin
        if (!rst) begin
            s1_prod_rr <= 0; s1_prod_ii <= 0;
            s1_prod_ri <= 0; s1_prod_ir <= 0;
            s1_x0_r    <= 0; s1_x0_i    <= 0;
        end else begin
            s1_prod_rr <= s0_x1_r * s0_w_r; // Re * Re
            s1_prod_ii <= s0_x1_i * s0_w_i; // Im * Im
            s1_prod_ri <= s0_x1_r * s0_w_i; // Re * Im
            s1_prod_ir <= s0_x1_i * s0_w_r; // Im * Re
            
            s1_x0_r    <= s0_x0_r;
            s1_x0_i    <= s0_x0_i;
        end
    end

    // ---------------------------------------------------------
    // STAGE 2: Butterfly & Final Output Registers
    // ---------------------------------------------------------
    wire signed [DATA_WIDTH+FACTOR_WIDTH:0] full_x1w_r = s1_prod_rr - s1_prod_ii;
    wire signed [DATA_WIDTH+FACTOR_WIDTH:0] full_x1w_i = s1_prod_ri + s1_prod_ir;

    wire signed [DATA_WIDTH-1:0] x1w_r = full_x1w_r[FRAC_BITS+DATA_WIDTH-1 : FRAC_BITS];
    wire signed [DATA_WIDTH-1:0] x1w_i = full_x1w_i[FRAC_BITS+DATA_WIDTH-1 : FRAC_BITS];

    always @(posedge clk) begin
        if (!rst) begin
            out_x0 <= 0;
            out_x1 <= 0;
        end else begin
            out_x0[2*DATA_WIDTH-1 : DATA_WIDTH] <= s1_x0_r + x1w_r;
            out_x0[DATA_WIDTH-1 : 0]            <= s1_x0_i + x1w_i;
            
            out_x1[2*DATA_WIDTH-1 : DATA_WIDTH] <= s1_x0_r - x1w_r;
            out_x1[DATA_WIDTH-1 : 0]            <= s1_x0_i - x1w_i;
        end
    end
endmodule