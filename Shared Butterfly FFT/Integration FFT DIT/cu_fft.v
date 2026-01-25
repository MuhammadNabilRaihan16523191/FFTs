`timescale 1ns/1ps

module cu_fft #(
    parameter N        = 8192
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,   

    input  wire [1:0] mode,      // 0:Idle, 1:Calc, 2:Write

    input  wire       count_over,

    input  wire [$clog2($clog2(N))-1 : 0]   stage, 

    output reg  [1:0] state,
         
    output reg        point_count_rst,
    output reg        stage_count_rst,
    output reg        wr_en,
    output reg        done   
);
    // State mapping
    localparam S_LOAD  = 2'b00;
    localparam S_CALC  = 2'b01;
    localparam S_WRITE = 2'b10;
    localparam S_IDLE  = 2'b11;

    localparam LAST_STAGE = $clog2(N) - 1;

    reg calc_done;
    reg [2:0] delay;

    always @(posedge clk) begin
        if (rst) begin
            state       <= S_IDLE;

            point_count_rst <= 1'b1;
            stage_count_rst <= 1'b1;

            wr_en       <= 1'b0;

            calc_done   <= 1'b0;
            done        <= 1'b0;

            delay       <= 3'b000;
        end else begin
            if (en) begin
                case (state)
                    S_IDLE: 
                        begin
                            case (mode)
                                2'b01: 
                                    begin
                                        state       <= S_LOAD;
                                        point_count_rst   <= 1'b0;

                                        wr_en       <= 1'b1;

                                        calc_done   <= 1'b0;
                                        done        <= 1'b0;
                                    end
                                2'b10:
                                    begin
                                        state       <= S_WRITE;
                                        point_count_rst   <= 1'b0;
                                    end
                                default: 
                                    begin
                                        state       <= S_IDLE;
                                        point_count_rst   <= 1'b1;
                                    end
                            endcase
                        end
                    S_LOAD:
                        begin 
                            if (count_over) begin
                                state <= S_CALC;
                                wr_en <= 1'b0;
                                stage_count_rst <= 1'b0;
                            end
                        end
                    S_CALC: 
                        begin
                            if ((stage == LAST_STAGE) & count_over) begin
                                state       <= S_CALC;
                                calc_done   <= 1'b1;
                            end

                            if (calc_done) begin
                                if (delay != 3'b000) begin
                                    state       <= S_CALC;
                                    delay       <= delay - 1;
                                end else begin
                                    state       <= S_IDLE;
                                    point_count_rst   <= 1'b1;
                                    stage_count_rst <= 1'b1;
                                    wr_en       <= 1'b0;
                                    done        <= 1'b1;
                                end
                            end else begin
                                if (delay != 3'b100) begin
                                    state <= S_CALC;
                                    delay <= delay + 1;
                                end else begin
                                    state <= S_CALC;
                                    wr_en <= 1'b1;
                                end
                            end
                        end
                    S_WRITE: 
                        begin
                            if (count_over) begin
                                state <= S_IDLE;
                                point_count_rst   <= 1'b1;
                            end
                        end
                    default: state <= S_IDLE;
                endcase
            end
        end
    end
endmodule