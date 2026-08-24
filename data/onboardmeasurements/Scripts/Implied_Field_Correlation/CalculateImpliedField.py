import pandas as pd
import numpy as np
import os
import glob
import re
import matplotlib.pyplot as plt

def process_onboard_measurements(target_board="Peters_Board"):
    # Base directories relative to script or repo root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    
    base_onboard = os.path.join(repo_root, "data", "onboardmeasurements", target_board)
    base_response = os.path.join(repo_root, "data", "responsemeasurements", "LibraryBased", "Week5", target_board)
    
    if not os.path.exists(base_onboard):
        base_onboard = os.path.join(script_dir, "..", "..", target_board)
        base_response = os.path.join(script_dir, "..", "..", "..", "responsemeasurements", "LibraryBased", "Week5", target_board)
        
    # Directory to save the correlation plots
    analysis_dir = os.path.join(base_onboard, "Analysis", "ImpliedField")
    os.makedirs(analysis_dir, exist_ok=True)
    
    print("======================================================")
    print(f"   ONBOARD VS RESPONSE CORRELATION ({target_board.upper()})")
    print("======================================================\n")

    # Find all onboard Excel files
    onboard_files = glob.glob(os.path.join(base_onboard, 'Board*', '**', '*.xlsx'), recursive=True)
    
    results_summary = []
    
    for file in sorted(onboard_files):
        # Ignore temporary lock files and anything already in Analysis
        if '~$' in file or 'Analysis' in file:
            continue
            
        try:
            rel = os.path.relpath(file, base_onboard)
            parts = os.path.normpath(rel).split(os.sep)
            board_folder = parts[0]
            filename = parts[-1]
            orientation = parts[1] if len(parts) > 2 else 'Default'
            
            # Locate response measurement file
            response_file = os.path.join(base_response, board_folder, filename)
            
            # Fallback 1: check if orientation folder exists in response measurements
            if not os.path.isfile(response_file) and orientation != 'Default':
                cand = os.path.join(base_response, board_folder, orientation, filename)
                if os.path.isfile(cand):
                    response_file = cand
                    
            # Fallback 2: check if filename has _X or -X variants
            if not os.path.isfile(response_file):
                if '_X' in filename:
                    alt1 = os.path.join(base_response, board_folder, filename.replace('_X', ''))
                    alt2 = os.path.join(base_response, board_folder, filename.replace('_X', '-X'))
                    if os.path.isfile(alt1): response_file = alt1
                    elif os.path.isfile(alt2): response_file = alt2
                elif '-X' in filename:
                    alt1 = os.path.join(base_response, board_folder, filename.replace('-X', ''))
                    alt2 = os.path.join(base_response, board_folder, filename.replace('-X', '_X'))
                    if os.path.isfile(alt1): response_file = alt1
                    elif os.path.isfile(alt2): response_file = alt2
                    
            # Fallback 3: check if file was saved in an unexpected board folder (e.g. B4A under Board2)
            if not os.path.isfile(response_file):
                m = re.match(r'B(\d+)', filename)
                if m:
                    correct_board = f'Board{m.group(1)}'
                    cand = os.path.join(base_response, correct_board, filename)
                    if os.path.isfile(cand):
                        response_file = cand
                    elif '_X' in filename:
                        alt1 = os.path.join(base_response, correct_board, filename.replace('_X', ''))
                        if os.path.isfile(alt1): response_file = alt1
                        
            if not os.path.isfile(response_file):
                print(f"Skipping {filename} in {board_folder}/{orientation}: No corresponding response measurement found.")
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
            # Find the resistance when current is 0A to use as our 0 Gauss generated field baseline
            idx_0 = np.argmin(np.abs(I))
            R_at_0A = R.iloc[idx_0] if isinstance(R, pd.Series) else R[idx_0]
            implied_G = (R - R_at_0A) / sens
            
            # 4. Correlate Implied Gauss with the Onboard Current
            # Since magnetic field strength is proportional to current magnitude, we correlate Implied G with absolute Current (A)
            max_I = np.abs(I).max()
            max_G = implied_G.max()
            
            # Calculate the linear correlation slope (Gauss per Ampere)
            slope, intercept = np.polyfit(I, implied_G, 1)
            
            # Calculate RMSE of the linear fit
            implied_G_fit = slope * I + intercept
            rmse = np.sqrt(np.mean((implied_G - implied_G_fit)**2))
            
            # Print the results nicely
            rel_path = os.path.relpath(file, base_onboard)
            print(f"File: {rel_path}")
            print(f"  -> True Sensitivity (from Response): {sens:.4f} Ohms/G")
            print(f"  -> Max Implied Field (Generated):    {max_G:.4f} G")
            print(f"  -> Max Coil Current:                 {max_I:.4f} A")
            print(f"  -> Generated Field Correlation:      {slope:.4f} G/A")
            print(f"  -> RMSE (Fit Error):                 {rmse:.4f} G")
            print("-" * 54)
            
            results_summary.append({
                'Board': board_folder,
                'Orientation': orientation,
                'File': filename,
                'Sensitivity_Ohms_per_G': sens,
                'Max_Implied_G': max_G,
                'Max_Current_A': max_I,
                'Correlation_G_per_A': slope,
                'RMSE_G': rmse
            })
            
            # 5. Save a plot of the Implied Field vs Current
            plt.figure(figsize=(8, 5))
            
            # Split forward and backward sweep
            max_idx = np.argmax(I.values if hasattr(I, 'values') else I)
            if 0 < max_idx < len(I) - 1:
                plt.plot(I[:max_idx+1], implied_G[:max_idx+1], 'b-', linewidth=2.0, label='Forward Sweep')
                plt.plot(I[max_idx:], implied_G[max_idx:], 'r-', linewidth=2.0, label='Backward Sweep')
            else:
                plt.plot(I, implied_G, 'b-', linewidth=2.0, label='Sweep')
                
            clean_filename = filename.replace('.xlsx', '')
            plt.title(f"Implied Magnetic Field vs Onboard Current\n{board_folder} - {clean_filename} ({orientation})")
            plt.xlabel("Kepco Current (A)")
            plt.ylabel("Implied Magnetic Field (G)")
            plt.grid(True)
            plt.legend()
            
            plot_name = f"{board_folder}_{orientation}_{clean_filename}.png"
            plt.tight_layout()
            plt.savefig(os.path.join(analysis_dir, plot_name))
            plt.close()
            
        except Exception as e:
            print(f"Error processing {os.path.relpath(file, base_onboard)}: {e}")

    # Save summary excel sheet
    if results_summary:
        df_summary = pd.DataFrame(results_summary)
        summary_path = os.path.join(analysis_dir, 'Correlation_Summary.xlsx')
        df_summary.to_excel(summary_path, index=False)
        print(f"Saved summary to {summary_path}")

if __name__ == "__main__":
    process_onboard_measurements("Peters_Board")
