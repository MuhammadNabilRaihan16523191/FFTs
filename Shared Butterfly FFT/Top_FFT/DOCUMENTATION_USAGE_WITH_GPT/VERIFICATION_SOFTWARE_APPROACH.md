# Verification Software Approach untuk Project FFT

Dokumen ini menjawab: **cara tahu desain RTL berhasil** dan **pendekatan software** yang bisa dipakai lintas folder.

## 1) Definisi "berhasil"

Untuk desain FFT fixed-point, dianggap berhasil jika:

- Tidak ada error sintaks/elaborasi di simulator.
- State machine selesai normal (`done=1` / `$finish` tercapai).
- Untuk test terarah (directed), output cocok dengan ekspektasi matematis.
- Untuk test random, error terhadap **golden software FFT** berada di bawah ambang (mis. MSE kecil / SNR cukup).
- Addressing benar (tidak ada overwrite/skip), terutama di modul generator alamat.

## 2) Pendekatan software (golden reference)

Gunakan alur ini:

1. Siapkan input real/complex dalam format float (Python).
2. Hitung referensi dengan `numpy.fft.fft`.
3. Quantize ke Q-format yang sama dengan RTL (contoh Q2.14).
4. Ambil output RTL (CSV/log/memory dump).
5. Bandingkan sample-by-sample:
   - absolute error real/imag
   - MSE
   - SNR
   - max error

Jika metrik lolos threshold yang disepakati, blok dinyatakan valid.

## 3) Mapping per folder (apa yang dicek)

### Address Generator

Folder: [Shared Butterfly FFT/Address Generator](Shared%20Butterfly%20FFT/Address%20Generator)

- Verifikasi `rd_addr`, `wr_addr`, `k` mengikuti pola stage DIT.
- Software checker sederhana:
  - generate pasangan indeks butterfly per stage secara Python,
  - cocokkan dengan log testbench.

### Butterfly

Folder: [Shared Butterfly FFT/Butterfly](Shared%20Butterfly%20FFT/Butterfly)

- Directed test untuk beberapa vektor kecil (mis. `w=1+0j`, `w=0-1j`, dll).
- Cocokkan hasil dengan rumus kompleks:
  - `y0 = x0 + x1*w`
  - `y1 = x0 - x1*w`
- Karena fixed-point, bandingkan dengan toleransi 1..2 LSB.

### Twiddle Factor

Folder: [Shared Butterfly FFT/Twiddle Factor](Shared%20Butterfly%20FFT/Twiddle%20Factor)

- Cek `w_gen` terhadap sinus/cosinus software.
- Cek properti magnitudo: `|W_k| ~ 1` (dalam toleransi quantization).

### Top_FFT

Folder: [Shared Butterfly FFT/Top_FFT](Shared%20Butterfly%20FFT/Top_FFT)

- Cek alur feeder + hold 2-clock:
  - sample pertama masuk `x0`
  - sample kedua masuk `x1`
  - `x0/x1` stabil selama 2 clock butterfly
  - writeback ke dua alamat pair
- Sudah tersedia VCD untuk observasi timing.

### Integration FFT DIT / DIF

Folder:
- [Shared Butterfly FFT/Integration FFT DIT](Shared%20Butterfly%20FFT/Integration%20FFT%20DIT)
- [Shared Butterfly FFT/Integration FFT DIF](Shared%20Butterfly%20FFT/Integration%20FFT%20DIF)

- Ini level end-to-end.
- Jalankan input known pattern:
  - impulse -> output datar
  - single tone -> puncak di bin tertentu
  - constant DC -> puncak di bin-0
- Bandingkan seluruh spektrum dengan `numpy.fft` setelah alignment skala/bit-growth.

## 4) Script/software yang sudah ada di repo

- Konversi CSV ke `.mem`: [Shared Butterfly FFT/Integration FFT DIT/csv_to_mem.py](Shared%20Butterfly%20FFT/Integration%20FFT%20DIT/csv_to_mem.py)
- Generator LUT sinus: [Shared Butterfly FFT/Twiddle Factor/sine_LUT_gen.py](Shared%20Butterfly%20FFT/Twiddle%20Factor/sine_LUT_gen.py)

Artinya pendekatan software **sudah ada pondasinya**; tinggal ditambah checker pembanding output RTL vs golden FFT.

## 5) Kriteria cepat (praktis)

Minimal checklist harian:

- `compile/elaborate` bersih
- testbench selesai (`done=1`)
- 3 test pattern lolos (impulse, tone, dc)
- max error <= target LSB

Kalau semua lolos, desain layak lanjut ke integrasi/sintesis.
