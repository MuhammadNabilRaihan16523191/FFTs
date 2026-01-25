`timescale 1ns/1ps

module tb_top_fft_dit;

    // Parameters
    parameter N = 8192;
    parameter ADDR_WIDTH = 13;
    parameter CLK_PERIOD = 10; // 100 MHz

    // Signals
    reg clk;
    reg rst;
    reg en;
    reg [1:0] mode;
    
    wire [1:0]  state;
    wire [ADDR_WIDTH-1:0] rd_addr;
    wire [ADDR_WIDTH-1:0] wr_addr;
    wire [ADDR_WIDTH-2:0] k;
    wire ram_wr_en;
    wire done;

    // Instantiate Top Module
    top_fft_dit #(
        .N(N),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .mode(mode),
        .state(state),
        .rd_addr(rd_addr),
        .wr_addr(wr_addr),
        .k(k),
        .ram_wr_en(ram_wr_en),
        .done(done)
    );

    // Clock Generator
    always #(CLK_PERIOD/2) clk = ~clk;

    // Monitor Logic - Mencetak perubahan Stage dan Alamat awal
    integer prev_stage = -1;
    always @(posedge clk) begin
        if (state == 2'b01) begin // Hanya monitor saat S_CALC
            if (uut.stage !== prev_stage) begin
                $display("\n--- MENGASAH STAGE %0d ---", uut.stage);
                $display("Time\t Count\t Phase\t RD_ADDR\t WR_ADDR\t K_IDX");
                prev_stage = uut.stage;
            end
            
            // Cetak 4 butterfly pertama di setiap stage untuk verifikasi
            if (uut.main_count < 8) begin
                $display("%0t\t %0d\t %0b\t %0d\t\t %0d\t\t %0d", 
                         $time, uut.main_count, uut.main_count[0], rd_addr, wr_addr, k);
            end
        end
    end

    // Stimulus
    initial begin
        // Inisialisasi
        clk = 0;
        rst = 1;
        en = 0;
        mode = 0;

        // Reset
        #(CLK_PERIOD * 5);
        rst = 0;
        en = 1;
        
        $display("Starting FFT Calculation Mode...");
        mode = 2'b01; // Mulai LOAD lalu CALC

        // Tunggu State pindah ke LOAD
        wait(state == 2'b00);
        $display("State: LOAD (Mengisi data bit-reversed...)");

        // Tunggu State pindah ke CALC
        wait(state == 2'b01);
        $display("State: CALC (Memulai proses FFT In-Place...)");

        // Tunggu sampai semua 13 stage selesai
        wait(done == 1'b1);
        
        $display("\n--- FFT SELESAI TOTAL ---");
        $display("Waktu Selesai: %0t", $time);
        
        #(CLK_PERIOD * 10);
        $finish;
    end

    // Safety timeout
    initial begin
        #20000000; // Timeout jika terjadi infinite loop
        $display("Timeout: Simulation took too long.");
        $finish;
    end

endmodule