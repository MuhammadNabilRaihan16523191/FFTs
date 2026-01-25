module bit_reverse #(
    parameter WIDTH = 13
)(
    input  wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_rev
            assign out[i] = in[WIDTH-1-i];
        end
    endgenerate
endmodule