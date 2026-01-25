import numpy as np

# Parameter
N = 8192
LUT_SIZE = 2048
SCALE = 2**14  # Q2.14

# Generate data (hanya angka Hex, tanpa header)
k_vals = np.arange(LUT_SIZE)
sine_vals = np.sin(2 * np.pi * k_vals / N)
fixed_vals = np.round(sine_vals * SCALE).astype(int)

# Simpan sebagai .mem (Hex murni)
with open("sine_lut_8192.mem", "w") as f:
    for val in fixed_vals:
        # Konversi ke 4 digit hex (16-bit)
        f.write(f"{val & 0xFFFF:04x}\n")

print("File 'sine_lut_8192.mem' berhasil dibuat.")
