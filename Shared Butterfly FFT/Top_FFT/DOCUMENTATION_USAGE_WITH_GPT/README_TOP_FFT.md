# Top_FFT (Hold 2-Clock Butterfly)

Folder ini berisi paket RTL **self-contained** untuk behavioral simulation di Vivado yang fokus ke isu:

- data `x0` dan `x1` harus ditangkap dulu,
- lalu keduanya di-`hold` stabil selama 2 clock,
- baru hasil butterfly ditulis kembali ke RAM.

## File

- `top_fft_dit_hold2.v` : top module demo scheduler capture/hold/writeback.
- `butterfly_feeder.v` : feeder RAM->(x0,x1) dengan kontrol 1-bit (`sel`) dari LSB counter.
- `butterfly_dit.v` : butterfly 2-siklus.
- `dual_port_ram.v` : simple dual-port RAM (1 write, 1 sync read).
- `tb_top_fft_dit_hold2.v` : testbench behavioral.
- `check_top_fft_results.py` : checker software (PASS/FAIL + metrik error vs expected).

## Catatan penting

- Versi ini adalah **demo arsitektur hold 2-clock** (pair-by-pair), belum full multi-stage FFT 0..log2(N)-1.
- Tujuannya untuk validasi konsep timing yang dibahas di chat sebelum integrasi ke pipeline FFT lengkap.

## Jalankan cepat (opsional, Icarus)

```powershell
# Opsi 1: pindah ke folder Top_FFT dulu
cd ".\Shared Butterfly FFT\Top_FFT"
iverilog -g2012 -o simv tb_top_fft_dit_hold2.v top_fft_dit_hold2.v butterfly_feeder.v butterfly_dit.v dual_port_ram.v
vvp .\simv

# Opsi 2: tetap dari root D:\FFT\FFTs (pakai path lengkap + quote)
iverilog -g2012 -o ".\Shared Butterfly FFT\Top_FFT\simv" \
	".\Shared Butterfly FFT\Top_FFT\tb_top_fft_dit_hold2.v" \
	".\Shared Butterfly FFT\Top_FFT\top_fft_dit_hold2.v" \
	".\Shared Butterfly FFT\Top_FFT\butterfly_feeder.v" \
	".\Shared Butterfly FFT\Top_FFT\butterfly_dit.v" \
	".\Shared Butterfly FFT\Top_FFT\dual_port_ram.v"
vvp ".\Shared Butterfly FFT\Top_FFT\simv"
```

## Verifikasi software output

Setelah simulasi jalan, testbench akan membuat `top_fft_pair_results.csv`.

Jalankan checker:

```powershell
D:/FFT/FFTs/.venv/bin/python.exe .\check_top_fft_results.py --csv .\top_fft_pair_results.csv --tol 2
```

Output checker memberi:

- `PASS/FAIL`
- `max_abs_err` (LSB)
- `mse`, `rmse`
- daftar mismatch awal (`pair`, expected, actual)
