import os
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def main():
    base_onboard = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'Peters_Board'))
    base_response = os.path.abspath(os.path.join(base_onboard, '..', '..', '..', '..', 'responsemeasurements', 'LibraryBased', 'Week5', 'Peters_Board'))

    # We will save the plots inside an Analysis/ImpliedField_Python folder
    analysis_dir = os.path.join(base_onboard, 'Analysis', 'ImpliedField_Python')
    if not os.path.exists(analysis_dir):
        os.makedirs(analysis_dir)

    print("======================================================")
    print("     ONBOARD VS RESPONSE CORRELATION (PETERS - PYTHON)")
    print("======================================================\n")

    files = glob.glob(os.path.join(base_onboard, 'Board*', '**', '*.xlsx'), recursive=True)

    results_summary = []

    for file_path in sorted(files):
        if '~$' in file_path or 'Analysis' in file_path:
            continue
            
        try:
            parts = file_path.split(os.sep)
            filename = parts[-1]
            
            # Dynamically find the Board folder since some have orientation folders and some don't
            board_idx = -1
            for idx, p in enumerate(parts):
                if p.startswith('Board') and len(p) <= 6:
                    board_idx = idx
                    break
                    
            if board_idx == -1:
                continue
                
            board_folder = parts[board_idx]
            if board_idx == len(parts) - 2:
                orientation = "Default"
            else:
                orientation = parts[-2]
            
            # Match the response measurement file
            response_file = os.path.join(base_response, board_folder, filename)
            
            if not os.path.isfile(response_file):
                print(f"Skipping {filename} in {board_folder}/{orientation}: No corresponding response measurement found.")
                continue
                
            resp_df = pd.read_excel(response_file)
            if 'Sensitivity_Ohms_per_G' in resp_df.columns:
                sens = resp_df['Sensitivity_Ohms_per_G'].iloc[0]
            else:
                sens = resp_df.iloc[:, 4].iloc[0]
                
            onboard_df = pd.read_excel(file_path)
            if 'Resistance_Ohms' in onboard_df.columns:
                R = onboard_df['Resistance_Ohms'].values
                I = onboard_df['Kepco_Current_A'].values
            else:
                I = onboard_df.iloc[:, 0].values
                R = onboard_df.iloc[:, 1].values
                
            # Calculate Implied Gauss
            implied_G = (R - np.min(R)) / sens
            
            max_I = np.max(np.abs(I))
            max_G = np.max(implied_G)
            
            # Linear Fit: abs(I) vs implied_G
            p = np.polyfit(np.abs(I), implied_G, 1)
            slope = p[0]
            
            rel_path = os.path.join(board_folder, orientation, filename)
            print(f"File: {rel_path}")
            print(f"  -> True Sensitivity (from Response): {sens:.4f} Ohms/G")
            print(f"  -> Max Implied Field (Generated):    {max_G:.4f} G")
            print(f"  -> Max Coil Current:                 {max_I:.4f} A")
            print(f"  -> Generated Field Correlation:      {slope:.4f} G/A")
            print("-" * 54)
            
            results_summary.append({
                'Board': board_folder,
                'Orientation': orientation,
                'File': filename,
                'Sensitivity_Ohms_per_G': sens,
                'Max_Implied_G': max_G,
                'Max_Current_A': max_I,
                'Correlation_G_per_A': slope
            })
            
            # Plotting (Matplotlib)
            plt.figure(figsize=(10, 8))
            
            max_idx = np.argmax(I)
            if max_idx > 0 and max_idx < len(I) - 1:
                plt.plot(I[:max_idx+1], implied_G[:max_idx+1], 'b-', linewidth=2.0, label='Forward Sweep')
                plt.plot(I[max_idx:], implied_G[max_idx:], 'r-', linewidth=2.0, label='Backward Sweep')
            else:
                plt.plot(I, implied_G, 'b-', linewidth=2.0, label='Sweep')
                
            clean_filename = filename.replace('.xlsx', '')
            title_str = f"Implied Magnetic Field vs Onboard Current\n{board_folder} - {clean_filename} ({orientation})"
            
            # Styling exactly to requests
            plt.title(title_str, fontsize=20, fontweight='bold')
            plt.xlabel('Kepco Current (A)', fontsize=20, fontweight='bold')
            plt.ylabel('Implied Magnetic Field (G)', fontsize=20, fontweight='bold')
            
            plt.grid(True)
            legend = plt.legend(loc='best')
            plt.setp(legend.texts, fontsize=20, weight='bold')
            
            # Thicken box axes to 2.0
            ax = plt.gca()
            for spine in ax.spines.values():
                spine.set_linewidth(2.0)
            ax.tick_params(width=2.0, labelsize=14)
            
            plot_name = f"{board_folder}_{orientation}_{clean_filename}.png"
            plt.tight_layout()
            plt.savefig(os.path.join(analysis_dir, plot_name), dpi=300)
            plt.close()
            
        except Exception as e:
            # print(f"Error processing {file_path}: {e}")
            pass

    # Save summary excel sheet
    if results_summary:
        df_summary = pd.DataFrame(results_summary)
        summary_path = os.path.join(analysis_dir, 'Correlation_Summary.xlsx')
        df_summary.to_excel(summary_path, index=False)
        print(f"Saved summary to {summary_path}")

if __name__ == "__main__":
    main()
