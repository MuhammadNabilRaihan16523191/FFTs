module addr_gen_dit #(
    parameter ADDR_WIDTH = 13
)(
    input  wire clk,
    input  wire rst,
    input  wire [1:0] state,

    input  wire [ADDR_WIDTH-1:0] count,
    input  wire                  count_over,

    input  wire [$clog2(ADDR_WIDTH)-1:0] stage,
    
    output reg  [ADDR_WIDTH-1:0] rd_addr,
    output reg  [ADDR_WIDTH-1:0] wr_addr,
    output reg  [ADDR_WIDTH-2:0] k
);
// Read Address
    reg [ADDR_WIDTH-1:0] addr_dist;
    always @(posedge clk) begin
        if (rst) begin
            addr_dist <= 1;
        end else begin
            if ((state == 2'b01) & count_over) begin
                addr_dist <= {addr_dist[ADDR_WIDTH-2:0], 1'b0};
            end
        end
    end

    wire jump;
    group_jump_dit #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) group_jump_inst (
        .prev_addr(x0_addr),
        .stage(stage),
        .jump(jump)
    );

    reg [ADDR_WIDTH-1:0] x0_addr, x1_addr;
    always @(posedge clk) begin
        if (rst) begin
            x0_addr <= 0;
            x1_addr <= 0;
        end else begin
            if (state == 2'b01) begin
                if (count[0]) begin
                    x0_addr <= ((jump) ? x1_addr : x0_addr) + 1;
                end else begin
                    x1_addr <= x0_addr + addr_dist;
                end
            end
        end
    end

    always @(*) begin
        if (state == 2'b01) begin
            if (count[0]) begin
                rd_addr = x1_addr;
            end else begin
                rd_addr = x0_addr;
            end
        end else begin
            rd_addr = count;
        end
    end

// Write Address
    wire [ADDR_WIDTH-1:0] count_rev;
    bit_reverse #(
        .WIDTH(ADDR_WIDTH)
    ) bit_rev_count (
        .in(count),
        .out(count_rev)
    );

    reg [ADDR_WIDTH-1:0] reg_rd_addr_3, reg_rd_addr_2, reg_rd_addr_1;
    always @(posedge clk) begin
        if (rst) begin
            reg_rd_addr_1 <= 0;
            reg_rd_addr_2 <= 0;
            reg_rd_addr_3 <= 0;
        end else begin
            reg_rd_addr_1 <= rd_addr;
            reg_rd_addr_2 <= reg_rd_addr_1;
            reg_rd_addr_3 <= reg_rd_addr_2;
        end
    end

    always @(*) begin
        case (state)
            2'b00: 
                begin
                    wr_addr = count_rev;
                end
            2'b01: 
                begin
                    wr_addr = reg_rd_addr_3;
                end
            default: 
                begin 
                    wr_addr = 0;
                end
        endcase
    end

// K Index
    wire [ADDR_WIDTH-2:0] k_dist;
    bit_reverse #(
        .WIDTH(ADDR_WIDTH-1)
    ) bit_rev_k (
        .in(addr_dist[ADDR_WIDTH-1:1]),
        .out(k_dist)
    );

    always @(posedge clk) begin
        if (rst) begin
            k <= 0;
        end else begin
            if (state == 2'b01) begin
                if (count[0]) begin
                    k <= k + k_dist;
                end
            end else begin
                k <= 0;
            end
        end
    end
endmodule