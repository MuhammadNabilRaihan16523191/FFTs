module butterfly_dif #(
    parameter DATA_WIDTH = 32,
    parameter FACTOR_WIDTH = 16,
    parameter FRAC_BITS = 14
) (
    input   wire                        clk,
    input   wire                        rst,

    input   wire [2*DATA_WIDTH-1:0]     in_x0, // {Real, Imag}
    input   wire [2*DATA_WIDTH-1:0]     in_x1, // {Real, Imag}
    input   wire [2*FACTOR_WIDTH-1:0]   w,     // {Real, Imag}

    output  reg  [2*DATA_WIDTH-1:0]     out_x0,
    output  reg  [2*DATA_WIDTH-1:0]     out_x1
);
// Unpacked input signals
    wire signed [DATA_WIDTH-1:0] x0_r = in_x0[2*DATA_WIDTH-1 : DATA_WIDTH];
    wire signed [DATA_WIDTH-1:0] x0_i = in_x0[DATA_WIDTH-1 : 0];
    wire signed [DATA_WIDTH-1:0] x1_r = in_x1[2*DATA_WIDTH-1 : DATA_WIDTH];
    wire signed [DATA_WIDTH-1:0] x1_i = in_x1[DATA_WIDTH-1 : 0];

    wire signed [FACTOR_WIDTH-1:0] w_r = w[2*FACTOR_WIDTH-1 : FACTOR_WIDTH];
    wire signed [FACTOR_WIDTH-1:0] w_i = w[FACTOR_WIDTH-1 : 0];

// Shared instances
    // Multipliers
    reg  signed [DATA_WIDTH-1:0]                mult1_in_a, mult2_in_a;
    reg  signed [FACTOR_WIDTH-1:0]              mult1_in_b, mult2_in_b;
    wire signed [DATA_WIDTH+FACTOR_WIDTH-1:0]   mult1_out = mult1_in_a * mult1_in_b;
    wire signed [DATA_WIDTH+FACTOR_WIDTH-1:0]   mult2_out = mult2_in_a * mult2_in_b;

    // Adders
    reg  signed [DATA_WIDTH-1:0] add1_in_a, add2_in_a;
    reg  signed [DATA_WIDTH-1:0] add1_in_b, add2_in_b;
    wire signed [DATA_WIDTH-1:0] add1_out = add1_in_a + add1_in_b;
    wire signed [DATA_WIDTH-1:0] add2_out = add2_in_a + add2_in_b;


    // Subtractors
    reg  signed [DATA_WIDTH-1:0] sub1_in_a, sub2_in_a;
    reg  signed [DATA_WIDTH-1:0] sub1_in_b, sub2_in_b;
    wire signed [DATA_WIDTH-1:0] sub1_out = sub1_in_a - sub1_in_b;
    wire signed [DATA_WIDTH-1:0] sub2_out = sub2_in_a - sub2_in_b;

    // Counter
    reg count;
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end else begin
            count <= ~count;
        end
    end

// Pipeline Stage 0
    reg signed [FACTOR_WIDTH-1:0]     reg_w_r, reg_w_i;

    always @(posedge clk) begin
        if (rst) begin
            reg_w_r <= 0;
            reg_w_i <= 0;

            add1_in_a <= 0;
            add1_in_b <= 0;

            sub1_in_a <= 0;
            sub1_in_b <= 0;
        end else begin
            if (count) begin
                add1_in_a <= x0_i;
                add1_in_b <= x1_i;

                sub1_in_a <= x0_i;
                sub1_in_b <= x1_i;
            end else begin
                reg_w_r <= w_r;
                reg_w_i <= w_i;

                add1_in_a <= x0_r;
                add1_in_b <= x1_r;

                sub1_in_a <= x0_r;
                sub1_in_b <= x1_r;
            end
        end
    end

    always @(*) begin
        if (count) begin
            mult1_in_a <= sub1_out;
            mult1_in_b <= reg_w_r;

            mult2_in_a <= sub1_out;
            mult2_in_b <= reg_w_i;
        end else begin
            mult1_in_a <= sub1_out;
            mult1_in_b <= reg_w_i;
            
            mult2_in_a <= sub1_out;
            mult2_in_b <= reg_w_r;
        end
    end

// Pipeline Stage 1
    reg signed [DATA_WIDTH-1:0] reg_add_out;

    always @(posedge clk) begin
        if (rst) begin
            reg_add_out <= 0;
        end else begin
            reg_add_out <= add1_out;

            if (count) begin
                sub2_in_a <= mult1_out[DATA_WIDTH+FRAC_BITS-1 : FRAC_BITS];
                add2_in_a <= mult2_out[DATA_WIDTH+FRAC_BITS-1 : FRAC_BITS];
            end else begin
                sub2_in_b <= mult1_out[DATA_WIDTH+FRAC_BITS-1 : FRAC_BITS];
                add2_in_b <= mult2_out[DATA_WIDTH+FRAC_BITS-1 : FRAC_BITS];
            end
        end
    end

// Pipeline Stage 2
    always @(posedge clk) begin
        if (rst) begin
            out_x0 <= 0;
            out_x1 <= 0;
        end else begin
            if (count) begin
                out_x0[DATA_WIDTH-1 : 0]            <= reg_add_out;

                out_x1[2*DATA_WIDTH-1 : DATA_WIDTH] <= sub2_out;
                out_x1[DATA_WIDTH-1 : 0]            <= add2_out;
            end else begin
                out_x0[2*DATA_WIDTH-1 : DATA_WIDTH] <= reg_add_out;
            end
        end
    end
endmodule