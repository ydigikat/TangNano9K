#!/usr/bin/env python3
#-------------------------------------------------------------------------------
# Jason Wilden 2025
#-------------------------------------------------------------------------------
# Split binary firmware into byte-wise hex files for BSRAM initialization
# Each BSRAM block holds one byte of each 32-bit instruction.
#-------------------------------------------------------------------------------

import sys
import os

def split_binary(bin_file):
    
    if not os.path.exists(bin_file):
        print(f"Error: {bin_file} not found")
        sys.exit(1)
    
    # Read binary file
    with open(bin_file, 'rb') as f:
        data = f.read()
    
    # Pad to 32-bit word boundary
    if len(data) % 4 != 0:
        padding = 4 - (len(data) % 4)
        data += b'\x00' * padding
        print(f"Padded binary to {len(data)} bytes")
    
    # Split into byte lanes
    b0 = []  # LSB
    b1 = []
    b2 = []
    b3 = []  # MSB
    
    for i in range(0, len(data), 4):
        b0.append(data[i])
        b1.append(data[i+1] if i+1 < len(data) else 0)
        b2.append(data[i+2] if i+2 < len(data) else 0)
        b3.append(data[i+3] if i+3 < len(data) else 0)
    
    def write_hex(filename, byte_list, target_size):
        with open(filename, 'w') as f:
            for byte_val in byte_list:
                f.write(f"{byte_val:02x}\n")
            # Pad to target size
            for _ in range(target_size - len(byte_list)):
                f.write("00\n")
        print(f"Created {filename} ({len(byte_list)} bytes, padded to {target_size})")

    target_words = 1 << 11  # 2048 for WORD_ADDRESS_WIDTH=11
    
    write_hex('firmware_b0.hex', b0,target_words)
    write_hex('firmware_b1.hex', b1,target_words)
    write_hex('firmware_b2.hex', b2,target_words)
    write_hex('firmware_b3.hex', b3,target_words)
    
    print(f"Split {len(data)} bytes into 4 hex files")
    print(f"Memory words: {len(data)//4}")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <binary_file>")
        sys.exit(1)
    
    split_binary(sys.argv[1])