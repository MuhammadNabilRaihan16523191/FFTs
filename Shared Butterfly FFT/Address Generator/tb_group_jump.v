`timescale 1ns/1ps

module tb_group_jump;

    // =========================================================================
    // 1. Parameter & Sinyal
    // =========================================================================
    parameter ADDR_WIDTH = 13;
    
    reg  [ADDR_WIDTH-1:0]          prev_addr;
    reg  [$clog2(ADDR_WIDTH)-1:0]  stage;
    wire                           jump;

    // =========================================================================
    // 2. Instansiasi Unit Under Test (UUT)
    // =========================================================================
    group_jump #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .prev_addr(prev_addr),
        .stage(stage),
        .jump(jump)
    );

    // =========================================================================
    // 3. Prosedur Stimulus
    // =========================================================================
    integer i;

    initial begin
        $display("=====================================================");
        $display("   MEMULAI VERIFIKASI GROUP JUMP (KONDISI JUMP MAX)");
        $display("=====================================================");
        $display("Stage | prev_addr (Hex) | Jump Output");
        $display("-----------------------------------------------------");

        // Set prev_addr ke semua 1 (F_FFF untuk 13-bit)
        // Hal ini akan mengaktifkan semua bit pada jump_array internal
        prev_addr = {ADDR_WIDTH{1'b1}};

        // Loop untuk mengganti stage dari 0 sampai 12
        for (i = 0; i < ADDR_WIDTH; i = i + 1) begin
            stage = i;
            
            // Tunggu sebentar agar logika kombinasional merambat
            #10;
            
            // Tampilkan hasil
            $display("%d     | %h             | %b", stage, prev_addr, jump);
            
            // Verifikasi: Jika prev_addr semua 1, jump harus selalu 1
            if (jump !== 1'b1) begin
                $display("ERROR: Jump harus bernilai 1 pada stage %d ketika prev_addr all 1s!", stage);
            end
        end

        $display("-----------------------------------------------------");
        $display("VERIFIKASI SELESAI");
        $display("=====================================================");
        $finish;
    end

endmodule