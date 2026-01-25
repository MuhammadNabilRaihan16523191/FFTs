import pandas as pd
import numpy as np

def csv_to_verilog_mem(input_csv, output_mem, n_samples=8192):
    """
    Konversi CSV Oscilloscope (WaveForms) ke format Verilog Memory (.mem)
    Format: Q2.14 (16-bit signed)
    """
    print(f"Membaca file: {input_csv}...")
    
    try:
        # Membaca CSV, melewati 9 baris header metadata dari Digilent WaveForms
        df = pd.read_csv(input_csv, skiprows=9)
        
        # Ambil kolom voltase (biasanya kolom kedua)
        # Sesuai file Anda: 'Channel 1 (V)'
        voltages = df.iloc[:, 1].values
        
        # Pastikan jumlah sampel sesuai (8192)
        if len(voltages) > n_samples:
            voltages = voltages[:n_samples]
        elif len(voltages) < n_samples:
            print(f"Peringatan: Sampel hanya {len(voltages)}, melakukan zero padding...")
            voltages = np.pad(voltages, (0, n_samples - len(voltages)), 'constant')

        # --- Proses Konversi ke Q2.14 ---
        # Q2.14 artinya 14 bit di belakang koma. 
        # Range: -2.0 s/d 1.999...
        scale_factor = 2**14
        
        # Perkalian dengan scale factor dan pembulatan
        q14_data = np.round(voltages * scale_factor).astype(np.int32)
        
        # Clipping agar tetap di dalam range 16-bit signed (-32768 s/d 32767)
        q14_data = np.clip(q14_data, -32768, 32767)
        
        # Konversi ke format Hexadecimal 16-bit (unsigned representation)
        with open(output_mem, 'w') as f:
            for val in q14_data:
                # Menggunakan bitwise AND dengan 0xFFFF untuk menangani angka negatif
                hex_val = val & 0xFFFF
                f.write(f"{hex_val:04x}\n")
        
        print(f"Berhasil! File disimpan di: {output_mem}")
        print(f"Jumlah baris: {len(q14_data)}")

    except Exception as e:
        print(f"Terjadi kesalahan: {e}")

if __name__ == "__main__":
    csv_to_verilog_mem('pd1.csv', 'input_data.mem')