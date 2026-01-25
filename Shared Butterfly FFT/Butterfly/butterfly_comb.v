module butterfly_comb #(
    parameter DATA_WIDTH   = 32,
    parameter FACTOR_WIDTH = 16,
    parameter FRAC_BITS    = 14 
) (
    input   wire [2*DATA_WIDTH-1:0]     in_x0, 
    input   wire [2*DATA_WIDTH-1:0]     in_x1, 
    input   wire [2*FACTOR_WIDTH-1:0]   w,     
    
    output  wire [2*DATA_WIDTH-1:0]     out_x0,
    output  wire [2*DATA_WIDTH-1:0]     out_x1
);

    // ---------------------------------------------------------
    // 1. Unpacking & Sign Extension
    // ---------------------------------------------------------
    wire signed [DATA_WIDTH-1:0] x0_r = in_x0[2*DATA_WIDTH-1 : DATA_WIDTH];
    wire signed [DATA_WIDTH-1:0] x0_i = in_x0[DATA_WIDTH-1 : 0];
    wire signed [DATA_WIDTH-1:0] x1_r = in_x1[2*DATA_WIDTH-1 : DATA_WIDTH];
    wire signed [DATA_WIDTH-1:0] x1_i = in_x1[DATA_WIDTH-1 : 0];
    
    wire signed [FACTOR_WIDTH-1:0] w_r = w[2*FACTOR_WIDTH-1 : FACTOR_WIDTH];
    wire signed [FACTOR_WIDTH-1:0] w_i = w[FACTOR_WIDTH-1 : 0];

    // ---------------------------------------------------------
    // 2. Complex Multiplication (x1 * w)
    // ---------------------------------------------------------
    wire signed [DATA_WIDTH+FACTOR_WIDTH-1:0] prod_rr = x1_r * w_r;
    wire signed [DATA_WIDTH+FACTOR_WIDTH-1:0] prod_ii = x1_i * w_i;
    wire signed [DATA_WIDTH+FACTOR_WIDTH-1:0] prod_ri = x1_r * w_i;
    wire signed [DATA_WIDTH+FACTOR_WIDTH-1:0] prod_ir = x1_i * w_r;

    // Combine products to get BW Real and BW Imaginary
    // Penambahan bit (+1) untuk menjaga carry sebelum scaling
    wire signed [DATA_WIDTH+FACTOR_WIDTH:0] full_bw_r = prod_rr - prod_ii;
    wire signed [DATA_WIDTH+FACTOR_WIDTH:0] full_bw_i = prod_ri + prod_ir;

    // ---------------------------------------------------------
    // 3. Scaling & Truncation (Q_FORMAT)
    // ---------------------------------------------------------
    // Menggeser koma sebanyak FRAC_BITS (14) untuk kembali ke skala DATA_WIDTH
    wire signed [DATA_WIDTH-1:0] bw_r = full_bw_r[FRAC_BITS + DATA_WIDTH - 1 : FRAC_BITS];
    wire signed [DATA_WIDTH-1:0] bw_i = full_bw_i[FRAC_BITS + DATA_WIDTH - 1 : FRAC_BITS];

    // ---------------------------------------------------------
    // 4. Final Butterfly Logic (x0 + BW dan x0 - BW)
    // ---------------------------------------------------------
    // Hasil penjumlahan 32-bit + 32-bit bisa menghasilkan 33-bit (bit growth)
    // Namun kita simpan kembali ke 32-bit sesuai permintaan sistem memori
    
    wire signed [DATA_WIDTH-1:0] y0_r = x0_r + bw_r;
    wire signed [DATA_WIDTH-1:0] y0_i = x0_i + bw_i;
    wire signed [DATA_WIDTH-1:0] y1_r = x0_r - bw_r;
    wire signed [DATA_WIDTH-1:0] y1_i = x0_i - bw_i;

    // Packing ke output bus
    assign out_x0 = {y0_r, y0_i};
    assign out_x1 = {y1_r, y1_i};
endmodule