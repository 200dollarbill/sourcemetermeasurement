import pandas as pd
import numpy as np
import os
import glob

block_map = {
    'B1': 1,
    'B2': 1,
    'B4': 1,
    'B3': 2,
    'B5': 2
}

pin_to_sensor = {
    'A': 'A', 'G': 'A',
    'B': 'B', 'H': 'B',
    'C': 'C', 'I': 'C',
    'D': 'D', 'J': 'D',
    'E': 'E', 'K': 'E',
    'F': 'F', 'L': 'F'
}

def get_file_info(filepath):
    filename = os.path.basename(filepath)
    name = filename.split('.')[0].upper() # e.g. "B1A"
    if name.startswith('B') and len(name) >= 3:
        # e.g., board="B1", pin="A"
        board = name[:-1]
        pin = name[-1]
        
        board_num = int(board[1:]) if board[1:].isdigit() else 99
        block = block_map.get(board, 99)
        sensor = pin_to_sensor.get(pin, 'Z')
        
        return board_num, block, sensor, pin, board
    return 99, 99, 'Z', 'Z', 'Z'

def sort_key(filepath):
    board_num, block, sensor, pin, _ = get_file_info(filepath)
    return (board_num, sensor, pin)

def process_directory(base_dir):
    excel_files = glob.glob(os.path.join(base_dir, 'Board*', '**', '*.xlsx'), recursive=True)
    
    if not excel_files:
        print("No Excel files found in the directory.")
        return
        
    # Sort files using our custom sort key to group by Sensor
    excel_files = sorted(excel_files, key=sort_key)

    print("======================================================")
    print("      PETERS BOARD FULL SENSOR RESPONSE ANALYSIS")
    print("======================================================\n")

    for file in excel_files:
        if '~$' in file or 'Analysis' in file:
            continue
            
        try:
            board_num, block, sensor, pin, board_str = get_file_info(file)
            if board_num == 99: # Skip unparseable files
                continue
                
            df = pd.read_excel(file)
            
            # Extract columns flexibly
            R = df['Resistance_Ohms'].values if 'Resistance_Ohms' in df.columns else df.iloc[:, 1].values
            G = df['Magnetic_Field_G'].values if 'Magnetic_Field_G' in df.columns else df.iloc[:, 2].values
            I = df['Kepco_Current_A'].values if 'Kepco_Current_A' in df.columns else df.iloc[:, 0].values
            
            if 'Sensitivity_Ohms_per_G' in df.columns:
                sens = df['Sensitivity_Ohms_per_G'].iloc[0]
            else:
                sens = df.iloc[:, 4].iloc[0]
                
            # Ranges
            r_min, r_max = R.min(), R.max()
            g_min, g_max = G.min(), G.max()
            i_min, i_max = I.min(), I.max()
            
            # MR Ratio
            mr_ratio = ((r_max - r_min) / r_min) * 100
            
            # Nominal Resistance (closest to G=0)
            idx_g0 = np.argmin(np.abs(G))
            nominal_r = R[idx_g0]
            actual_g0 = G[idx_g0]
            
            # Max Hysteresis Gap
            max_idx = np.argmax(I)
            if max_idx > 0 and max_idx < len(I) - 1:
                G_fwd = G[:max_idx+1]
                R_fwd = R[:max_idx+1]
                
                # Reverse the backward sweep so it goes in the same direction (increasing G)
                G_bwd = G[max_idx:][::-1]
                R_bwd = R[max_idx:][::-1]
                
                # Interpolate backward sweep onto forward sweep's G points
                R_bwd_aligned = np.interp(G_fwd, G_bwd, R_bwd)
                
                hysteresis_gap = np.abs(R_fwd - R_bwd_aligned)
                max_gap_idx = np.argmax(hysteresis_gap)
                max_gap_ohms = hysteresis_gap[max_gap_idx]
                max_gap_G = G_fwd[max_gap_idx]
            else:
                max_gap_ohms = 0
                max_gap_G = 0

            # Print Results
            print(f"Board {board_num} Block {block} Sensor {sensor} Pin {pin}")
            print(f"  -> MR Ratio:       {mr_ratio:.4f} %")
            print(f"  -> Sensitivity:    {sens:.4f} Ohms/G")
            print(f"  -> Nom Res (G~0):  {nominal_r:.2f} Ohms (at {actual_g0:.4f} G)")
            print(f"  -> Max Hysteresis: {max_gap_ohms:.2f} Ohms (at {max_gap_G:.4f} G)")
            print(f"  -> Resistance:     Min = {r_min:.2f}, Max = {r_max:.2f} Ohms")
            print(f"  -> Gauss:          Min = {g_min:.2f}, Max = {g_max:.2f} G")
            print(f"  -> Current:        Min = {i_min:.2f}, Max = {i_max:.2f} A")
            print("-" * 54)
            
        except Exception as e:
            # Skip corrupted/bad format files silently
            pass

if __name__ == "__main__":
    target_dir = os.path.dirname(os.path.abspath(__file__))
    process_directory(target_dir)
