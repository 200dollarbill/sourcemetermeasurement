import pandas as pd
import numpy as np
import os
import glob

def process_directory(base_dir):
    # Find all Excel files recursively in the base directory
    excel_files = glob.glob(os.path.join(base_dir, '**', '*.xlsx'), recursive=True)
    
    if not excel_files:
        print("No Excel files found in the directory.")
        return

    print("======================================================")
    print("                MAXIMUM HYSTERESIS GAP")
    print("======================================================\n")

    for file in sorted(excel_files):
        # Ignore temporary lock files
        if '~$' in file:
            continue
            
        try:
            # Read the excel file
            df = pd.read_excel(file)
            
            # Extract columns flexibly
            if 'Resistance_Ohms' in df.columns:
                R = df['Resistance_Ohms'].values
            else:
                R = df.iloc[:, 1].values
                
            if 'Magnetic_Field_G' in df.columns:
                G = df['Magnetic_Field_G'].values
            else:
                G = df.iloc[:, 2].values
                
            if 'Kepco_Current_A' in df.columns:
                I = df['Kepco_Current_A'].values
            else:
                I = df.iloc[:, 0].values
                
            # To find the turning point of the hysteresis loop, we find the maximum current index
            # This splits the loop into 'forward' (up sweep) and 'backward' (down sweep)
            max_idx = np.argmax(I)
            
            # If the sweep is one-way (no loop), skip it
            if max_idx == 0 or max_idx == len(I) - 1:
                print(f"File: {os.path.relpath(file, base_dir)} - No reverse sweep detected.")
                continue

            # Forward sweep arrays
            G_fwd = G[:max_idx+1]
            R_fwd = R[:max_idx+1]
            
            # Backward sweep arrays (we reverse them so they go from min to max, just like forward)
            G_bwd = G[max_idx:][::-1]
            R_bwd = R[max_idx:][::-1]
            
            # Use numpy's interpolation to interpolate backward resistance onto forward magnetic fields
            # np.interp requires the x-coordinates (G_bwd) to be strictly increasing, which they are after reversing.
            R_bwd_aligned = np.interp(G_fwd, G_bwd, R_bwd)
            
            # Calculate the absolute difference (Hysteresis Gap) at each point
            hysteresis_gap = np.abs(R_fwd - R_bwd_aligned)
            
            # Find the maximum gap
            max_gap_idx = np.argmax(hysteresis_gap)
            max_gap_ohms = hysteresis_gap[max_gap_idx]
            max_gap_G = G_fwd[max_gap_idx]
            
            # Find the resistance values at that point
            r_fwd_val = R_fwd[max_gap_idx]
            r_bwd_val = R_bwd_aligned[max_gap_idx]
            
            # Print the results nicely
            rel_path = os.path.relpath(file, base_dir)
            print(f"File: {rel_path}")
            print(f"  -> Max Hys Gap:        {max_gap_ohms:.2f} Ohms")
            print(f"  -> Occurred at Gauss:  {max_gap_G:.4f} G")
            print(f"  -> Forward Sweep Res:  {r_fwd_val:.2f} Ohms")
            print(f"  -> Backward Sweep Res: {r_bwd_val:.2f} Ohms")
            print("-" * 54)
            
        except Exception as e:
            pass # Suppress errors for clean output if some files are malformed

if __name__ == "__main__":
    target_dir = "/mnt/Data/yep/Kuliah/Tugas/Magang Programs/MagneticStationGUI/data/responsemeasurements/Library Based/Week 5/Hsin TIngs Board"
    process_directory(target_dir)
