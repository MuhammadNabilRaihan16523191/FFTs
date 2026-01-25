module group_jump_dit #(
    parameter ADDR_WIDTH = 13
)(
    input  wire [ADDR_WIDTH-1:0]            prev_addr,
    input  wire [$clog2(ADDR_WIDTH)-1:0]    stage,

    output wire jump
);
    localparam ARRAY_WIDTH = (1 << $clog2(ADDR_WIDTH));
    wire [ARRAY_WIDTH-1:0] jump_array;

    assign jump_array[0] = 1'b1;

    genvar i;
    generate
        for (i = 1; i < ARRAY_WIDTH; i = i + 1) begin : gen_jump
            if (i < ADDR_WIDTH) begin
                assign jump_array[i] = jump_array[i-1] & prev_addr[i-1];
            end else begin
                assign jump_array[i] = 1'b0;
            end
        end
    endgenerate

    assign jump = jump_array[stage];
endmodule