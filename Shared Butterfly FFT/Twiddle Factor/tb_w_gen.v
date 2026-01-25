`timescale 1ns/1ps

module tb_w_gen;
    // Parameter disamakan dengan modul utama
    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 11;
    parameter FRAC_BITS  = 14;

    reg clk;
    reg rst;
    reg [ADDR_WIDTH+1:0] k_in;
    wire signed [2*DATA_WIDTH-1:0] w_out;

    // Instansiasi Device Under Test (DUT)
    w_gen #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .k(k_in),
        .w(w_out)
    );

    // Clock Generator (100 MHz -> Period 10ns)
    always #5 clk = ~clk;

    // Jalur penunda untuk sinkronisasi pencatatan CSV (Latency 2)
    reg [ADDR_WIDTH+1:0] k_delayed [0:2];
    
    integer file_ptr;
    integer i;

    initial begin
        // Inisialisasi awal
        clk = 0;
        rst = 1;
        k_in = 0;
        k_delayed[0] = 0;
        k_delayed[1] = 0;
        k_delayed[2] = 0;

        // Buka file CSV untuk verifikasi di Colab
        file_ptr = $fopen("w_gen_results.csv", "w");
        if (file_ptr == 0) begin
            $display("Gagal membuka file!");
            $finish;
        end
        $fdisplay(file_ptr, "k,re_fixed,im_fixed");

        // Pulse Reset (Active High sesuai desain terakhir)
        #20 rst = 0;
        @(posedge clk);

        // Streaming input k dari 0 sampai 8191
        for (i = 0; i < 8192; i = i + 1) begin
            k_in <= i;

            // Catat data jika pipeline sudah terisi (setelah 2 cycle)
            if (i >= 2) begin
                $fdisplay(file_ptr, "%d,%d,%d", 
                    k_delayed[1], 
                    $signed(w_out[2*DATA_WIDTH-1 : DATA_WIDTH]), 
                    $signed(w_out[DATA_WIDTH-1 : 0]));
            end

            @(posedge clk);
            // Geser shift register delay di TB
            k_delayed[1] <= k_delayed[0];
            k_delayed[0] <= i;
        end

        // Kuras (flush) 2 data terakhir yang masih tertahan di pipeline
        repeat(2) begin
            @(posedge clk);
            $fdisplay(file_ptr, "%d,%d,%d", 
                k_delayed[1], 
                $signed(w_out[2*DATA_WIDTH-1 : DATA_WIDTH]), 
                $signed(w_out[DATA_WIDTH-1 : 0]));
            k_delayed[1] <= k_delayed[0];
            k_delayed[0] <= 0;
        end

        $fclose(file_ptr);
        $display("Simulasi selesai. File 'w_gen_results.csv' siap diplot.");
        $finish;
    end
endmodule