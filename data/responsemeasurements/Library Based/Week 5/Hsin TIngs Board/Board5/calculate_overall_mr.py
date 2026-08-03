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
                
            # Calculate overall MR Ratio = ((Max - Min) / Min) * 100
            r_max = R.max()
            r_min = R.min()
            mr_ratio = ((r_max - r_min) / r_min) * 100
            
            # Get Sensitivity value (it's constant across the column in the generated data)
            sensitivity_val = Sens.iloc[0]
            
            # Print the results nicely
            # Get relative file path for cleaner output
            rel_path = os.path.relpath(file, base_dir)
            print(f"File: {rel_path}")
            print(f"  -> MR Ratio:    {mr_ratio:.4f} %")
            print(f"  -> Sensitivity: {sensitivity_val:.4f} Ohms/G")
            print("-" * 54)
            
        except Exception as e:
            print(f"Error processing {os.path.relpath(file, base_dir)}: {e}")
            print("-" * 54)

if __name__ == "__main__":
    target_dir = "/mnt/Data/yep/Kuliah/Tugas/Magang Programs/MagneticStationGUI/data/responsemeasurements/Library Based/Week 5"
    process_directory(target_dir)
