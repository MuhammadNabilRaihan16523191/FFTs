`timescale 1ns/1ps

module tb_butterfly;

    // =========================================================================
    // 1. Parameter & Sinyal Utama
    // =========================================================================
    parameter DW = 32;          
    parameter FW = 16;          
    parameter FB = 14;          
    parameter SCALE = 1 << FB;

    reg clk;
    reg rst;
    reg [2*DW-1:0] in_x0;
    reg [2*DW-1:0] in_x1;
    reg [2*FW-1:0] w;

    wire [2*DW-1:0] out_x0;
    wire [2*DW-1:0] out_x1;

    // =========================================================================
    // 2. Variabel Testbench & Buffer Sinkronisasi
    // =========================================================================
    integer i, fd;
    integer seed = 13223014; // NIM
    
    reg signed [DW-1:0] a_r, a_i, b_r, b_i;
    reg signed [FW-1:0] wr, wi;
    real r_wr, r_wi; // Dideklarasikan di level modul untuk menghindari errorUnnamed Block

    // Buffer Histori (Shift Register)
    // Latency = 4 clock. Input masuk tiap 2 clock.
    // Delay = 4 / 2 = 2 sampel.
    // Index 0: Current, Index 1: Delay 1, Index 2: Delay 2 (Output Sinkron)
    reg signed [DW-1:0] hist_x0r[0:2];
    reg signed [DW-1:0] hist_x0i[0:2];
    reg signed [DW-1:0] hist_x1r[0:2];
    reg signed [DW-1:0] hist_x1i[0:2];
    reg signed [FW-1:0] hist_wr[0:2];
    reg signed [FW-1:0] hist_wi[0:2];

    // =========================================================================
    // 3. Instansiasi UUT
    // =========================================================================
    butterfly #(
        .DATA_WIDTH(DW),
        .FACTOR_WIDTH(FW),
        .FRAC_BITS(FB)
    ) uut (
        .clk(clk),
        .rst(rst),
        .in_x0(in_x0),
        .in_x1(in_x1),
        .w(w),
        .out_x0(out_x0),
        .out_x1(out_x1)
    );

    // Clock Generator (100 MHz)
    always #5 clk = (clk === 1'b0);

    // =========================================================================
    // 4. Prosedur Stimulus & CSV Logging (Streaming & Synchronized)
    // =========================================================================
    initial begin
        // Inisialisasi
        clk = 0;
        rst = 1;
        in_x0 = 0; in_x1 = 0; w = 0;
        
        for(i=0; i<3; i=i+1) begin
            hist_x0r[i] = 0; hist_x0i[i] = 0;
            hist_x1r[i] = 0; hist_x1i[i] = 0;
            hist_wr[i]  = 0; hist_wi[i]  = 0;
        end

        fd = $fopen("butterfly_dit_results.csv", "w");
        $fdisplay(fd, "sample,x0_r,x0_i,x1_r,x1_i,w_r,w_i,out0_r,out0_i,out1_r,out1_i");

        // --- SINKRONISASI RESET & COUNT ---
        repeat (5) @(posedge clk);
        @(negedge clk) rst = 0;     // Lepas reset di negedge
        @(posedge clk);             // Cycle 1: count toggles 0 -> 1 (Imag phase)
        @(posedge clk);             // Cycle 2: count toggles 1 -> 0 (Real phase)
        
        // Sekarang count internal bernilai 0, kita mulai streaming tepat di sini
        $display("Reset released and phase aligned. Starting streaming...");

        for (i = 0; i < 1002; i = i + 1) begin
            
            // A. Update Input Baru (Streaming tiap 2 clock)
            if (i < 1000) begin
                a_r = $signed($random(seed) % (5 * SCALE)); 
                a_i = $signed($random(seed) % (5 * SCALE));
                b_r = $signed($random(seed) % (5 * SCALE));
                b_i = $signed($random(seed) % (5 * SCALE));

                r_wr = ($dist_uniform(seed, -1000, 1000) / 1000.0);
                r_wi = $sqrt(1.0 - (r_wr * r_wr));
                if ($random(seed) % 2) r_wi = -r_wi;

                wr = $rtoi(r_wr * SCALE);
                wi = $rtoi(r_wi * SCALE);

                // Drive ke port
                in_x0 = {a_r, a_i};
                in_x1 = {b_r, b_i};
                w     = {wr, wi};

                // Push ke Histori (Index 0)
                hist_x0r[0] = a_r; hist_x0i[0] = a_i;
                hist_x1r[0] = b_r; hist_x1i[0] = b_i;
                hist_wr[0]  = wr;  hist_wi[0]  = wi;
            end else begin
                in_x0 = 0; in_x1 = 0; w = 0;
                hist_x0r[0] = 0; hist_x0i[0] = 0;
                hist_x1r[0] = 0; hist_x1i[0] = 0;
                hist_wr[0]  = 0; hist_wi[0]  = 0;
            end

            // B. Wait Resource Sharing Interval (2 Clock)
            repeat(2) @(posedge clk);

            // C. Logging Output (Ambil dari histori Index 2 untuk sinkronisasi latency)
            if (i >= 2) begin
                $fdisplay(fd, "%0d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", 
                    i-2, 
                    hist_x0r[2], hist_x0i[2], 
                    hist_x1r[2], hist_x1i[2], 
                    hist_wr[2],  hist_wi[2], 
                    $signed(out_x0[2*DW-1:DW]), $signed(out_x0[DW-1:0]),
                    $signed(out_x1[2*DW-1:DW]), $signed(out_x1[DW-1:0])
                );
            end

            // D. Shift History
            hist_x0r[2] = hist_x0r[1]; hist_x0r[1] = hist_x0r[0];
            hist_x0i[2] = hist_x0i[1]; hist_x0i[1] = hist_x0i[0];
            hist_x1r[2] = hist_x1r[1]; hist_x1r[1] = hist_x1r[0];
            hist_x1i[2] = hist_x1i[1]; hist_x1i[1] = hist_x1i[0];
            hist_wr[2]  = hist_wr[1];  hist_wr[1]  = hist_wr[0];
            hist_wi[2]  = hist_wi[1];  hist_wi[1]  = hist_wi[0];

            if (i % 200 == 0) $display("Progress: %0d/1000 samples...", i);
        end

        $fclose(fd);
        $display("Simulation finished. File: butterfly_dit_results.csv");
        $finish;
    end

endmodule