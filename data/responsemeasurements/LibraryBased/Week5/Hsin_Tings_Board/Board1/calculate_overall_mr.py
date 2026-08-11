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
    print("                OVERALL MR RATIO & SENSITIVITY")
    print("======================================================\n")

    for file in sorted(excel_files):
        # Ignore any 'bad measurements' or 'library' files if needed, but the prompt says 'all the excel files'
        if '~$' in file: # skip temporary lock files
            continue
            
        try:
            # Read the excel file
            df = pd.read_excel(file)
            
            # Column B is Resistance_Ohms, Column E is Sensitivity_Ohms_per_G
            if 'Resistance_Ohms' in df.columns:
                R = df['Resistance_Ohms']
            else:
                R = df.iloc[:, 1] # fallback to Column B
                
            if 'Sensitivity_Ohms_per_G' in df.columns:
                Sens = df['Sensitivity_Ohms_per_G']
            else:
                Sens = df.iloc[:, 4] # fallback to Column E
                
            if 'Magnetic_Field_G' in df.columns:
                G = df['Magnetic_Field_G']
            else:
                G = df.iloc[:, 2] # fallback to Column C
                
            if 'Kepco_Current_A' in df.columns:
                I = df['Kepco_Current_A']
            else:
                I = df.iloc[:, 0] # fallback to Column A
                
            # Calculate overall MR Ratio = ((Max - Min) / Min) * 100
            r_max = R.max()
            r_min = R.min()
            mr_ratio = ((r_max - r_min) / r_min) * 100
            
            g_max = G.max()
            g_min = G.min()
            
            i_max = I.max()
            i_min = I.min()
            
            # Get Sensitivity value (it's constant across the column in the generated data)
            sensitivity_val = Sens.iloc[0]
            
            # Find nominal resistance (Resistance at Gauss ~ 0)
            idx_g0 = G.abs().idxmin()
            nominal_r = R.iloc[idx_g0]
            actual_g0 = G.iloc[idx_g0]
            
            # Print the results nicely
            # Get relative file path for cleaner output
            rel_path = os.path.relpath(file, base_dir)
            print(f"File: {rel_path}")
            print(f"  -> MR Ratio:    {mr_ratio:.4f} %")
            print(f"  -> Sensitivity: {sensitivity_val:.4f} Ohms/G")
            print(f"  -> Resistance:  Min = {r_min:.2f}, Max = {r_max:.2f} Ohms")
            print(f"  -> Nom Res (G=0): {nominal_r:.2f} Ohms (at {actual_g0:.4f} G)")
            print(f"  -> Gauss:       Min = {g_min:.2f}, Max = {g_max:.2f} G")
            print(f"  -> Current:     Min = {i_min:.2f}, Max = {i_max:.2f} A")
            print("-" * 54)
            
        except Exception as e:
            print(f"Error processing {os.path.relpath(file, base_dir)}: {e}")
            print("-" * 54)

if __name__ == "__main__":
    target_dir = "/mnt/Data/yep/Kuliah/Tugas/Magang Programs/MagneticStationGUI/data/responsemeasurements/Library Based/Week 5/Hsin TIngs Board"
    process_directory(target_dir)
