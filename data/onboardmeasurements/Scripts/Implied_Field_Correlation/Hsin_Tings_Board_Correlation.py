import pandas as pd
import numpy as np
import os
import glob
import matplotlib.pyplot as plt

def process_onboard_measurements():
    # Base directories for both measurements
    base_onboard = "data/onboardmeasurements/Hsin_Tings_Board"
    base_response = "data/responsemeasurements/LibraryBased/Week5/Hsin_Tings_Board"
    
    # Directory to save the correlation plots
    analysis_dir = os.path.join(base_onboard, "Analysis", "ImpliedField")
    os.makedirs(analysis_dir, exist_ok=True)
    
    print("======================================================")
    print("         ONBOARD VS RESPONSE CORRELATION")
    print("======================================================\n")

    # Find all onboard Excel files
    onboard_files = glob.glob(os.path.join(base_onboard, 'Board*', '**', '*.xlsx'), recursive=True)
    
    for file in sorted(onboard_files):
        # Ignore temporary lock files and anything already in Analysis
        if '~$' in file or 'Analysis' in file:
            continue
            
        try:
            # Parse board and point from the file path
            # e.g., .../Board1/PointX/B1A.xlsx
            parts = os.path.normpath(file).split(os.sep)
            filename = parts[-1]
            orientation = parts[-2]
            board_folder = parts[-3]
            
            # Locate the exact same board and test point in the response measurements
            response_file = os.path.join(base_response, board_folder, filename)
            
            if not os.path.isfile(response_file):
                # Try finding it if the user moved things slightly
                print(f"Skipping {filename} in {board_folder}/{orientation}: No corresponding response measurement found at {response_file}.")
                continue
                
            # 1. Read Response Measurement for the true Sensitivity
            resp_df = pd.read_excel(response_file)
            
            # Extract Sensitivity (Ohms/G)
            if 'Sensitivity_Ohms_per_G' in resp_df.columns:
                sens = resp_df['Sensitivity_Ohms_per_G'].iloc[0]
            else:
                sens = resp_df.iloc[:, 4].iloc[0]
                
            # 2. Read Onboard Measurement
            onboard_df = pd.read_excel(file)
            
            if 'Resistance_Ohms' in onboard_df.columns:
                R = onboard_df['Resistance_Ohms']
                I = onboard_df['Kepco_Current_A']
            else:
                I = onboard_df.iloc[:, 0]
                R = onboard_df.iloc[:, 1]
                
            # 3. Calculate Implied Gauss
            # We assume the lowest resistance point correlates to the ~0 Gauss field baseline
            implied_G = (R - R.min()) / sens
            
            # 4. Correlate Implied Gauss with the Onboard Current
            # Since magnetic field strength is proportional to current magnitude, we correlate Implied G with absolute Current (A)
            max_I = np.abs(I).max()
            max_G = implied_G.max()
            
            # Calculate the linear correlation slope (Gauss per Ampere)
            slope, intercept = np.polyfit(I, implied_G, 1)
            
            # Print the results nicely
            rel_path = os.path.relpath(file, base_onboard)
            print(f"File: {rel_path}")
            print(f"  -> True Sensitivity (from Response): {sens:.4f} Ohms/G")
            print(f"  -> Max Implied Field (Generated):    {max_G:.4f} G")
            print(f"  -> Max Coil Current:                 {max_I:.4f} A")
            print(f"  -> Generated Field Correlation:      {slope:.4f} G/A")
            print("-" * 54)
            
            # 5. Save a plot of the Implied Field vs Current
            plt.figure(figsize=(8, 5))
            plt.plot(I, implied_G, 'bo-', markersize=4, label='Implied Field vs Current')
            plt.title(f"Implied Magnetic Field vs Onboard Current\n{board_folder} - {filename[:-5]} ({orientation})")
            plt.xlabel("Kepco Current (A)")
            plt.ylabel("Implied Magnetic Field (G)")
            plt.grid(True)
            plt.legend()
            
            plot_name = f"{board_folder}_{orientation}_{filename[:-5]}.png"
            plt.tight_layout()
            plt.savefig(os.path.join(analysis_dir, plot_name))
            plt.close()
            
        except Exception as e:
            print(f"Error processing {os.path.relpath(file, base_onboard)}: {e}")

if __name__ == "__main__":
    process_onboard_measurements()
