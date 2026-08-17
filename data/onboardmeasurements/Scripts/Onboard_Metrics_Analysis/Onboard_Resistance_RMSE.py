import os
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def process_rmse(board_name):
    print(f"\n======================================================")
    print(f"      RESISTANCE RMSE ANALYSIS: {board_name} (ONBOARD)")
    print(f"======================================================")
    
    # Path to the data
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', board_name))
    
    if not os.path.exists(base_dir):
        print(f"Directory not found: {base_dir}")
        return

    # Output directory for plots and excel
    out_dir = os.path.join(base_dir, 'Analysis', 'Resistance_RMSE_Python')
    os.makedirs(out_dir, exist_ok=True)

    files = glob.glob(os.path.join(base_dir, 'Board*', '**', '*.xlsx'), recursive=True)
    
    results = []

    for file_path in sorted(files):
        if '~$' in file_path or 'Analysis' in file_path or 'Summary' in file_path:
            continue
            
        try:
            parts = os.path.normpath(file_path).split(os.sep)
            filename = parts[-1]
            
            # Extract board and orientation cleanly
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

            df = pd.read_excel(file_path)
            
            # For onboard measurements, we correlate Resistance against Current (A)
            if 'Kepco_Current_A' in df.columns and 'Resistance_Ohms' in df.columns:
                I = df['Kepco_Current_A'].values
                R = df['Resistance_Ohms'].values
            else:
                I = df.iloc[:, 0].values
                R = df.iloc[:, 1].values
                
            # Filter NaNs
            valid = ~np.isnan(I) & ~np.isnan(R)
            I = I[valid]
            R = R[valid]
            
            if len(I) == 0:
                continue

            # Linear Fit: Current vs Resistance
            p = np.polyfit(I, R, 1)
            slope = p[0]
            intercept = p[1]
            
            # Calculate RMSE
            R_fit = slope * I + intercept
            rmse = np.sqrt(np.mean((R - R_fit)**2))
            
            # Calculate Full Scale Output (FSO)
            fso = np.max(R) - np.min(R)
            
            rel_path = os.path.join(board_folder, orientation, filename)
            print(f"File: {rel_path}")
            print(f"  -> Resistance Slope (Ohms/A): {slope:.4f}")
            print(f"  -> Resistance FSO:            {fso:.4f} Ohms")
            print(f"  -> RMSE (Fit Error):          {rmse:.4f} Ohms")
            print("-" * 54)
            
            results.append({
                'Board': board_folder,
                'Orientation': orientation,
                'File': filename,
                'Slope_Ohms_per_A': slope,
                'FSO_Ohms': fso,
                'RMSE_Ohms': rmse
            })
            
            # Generate styled plot
            plt.figure(figsize=(10, 8))
            
            plt.scatter(I, R, c='b', label='Actual Data', s=20)
            
            # Plot the line
            I_line = np.linspace(np.min(I), np.max(I), 100)
            R_line = slope * I_line + intercept
            plt.plot(I_line, R_line, 'r-', linewidth=2.0, label='Best-fit line')
            
            title_str = f"Sensor Response RMSE (Onboard)\n{board_folder} - {filename[:-5]} ({orientation})"
            plt.title(title_str, fontsize=20, fontweight='bold')
            plt.xlabel('Kepco Current (A)', fontsize=20, fontweight='bold')
            plt.ylabel('Resistance (Ohms)', fontsize=20, fontweight='bold')
            
            # Text box for RMSE
            plt.text(0.05, 0.95, f'RMSE = {rmse:.4f} Ohms', transform=plt.gca().transAxes,
                     fontsize=16, fontweight='bold', verticalalignment='top',
                     bbox=dict(facecolor='white', edgecolor='black', boxstyle='round,pad=0.5'))
                     
            plt.grid(True)
            legend = plt.legend(loc='lower right')
            plt.setp(legend.texts, fontsize=16, weight='bold')
            
            ax = plt.gca()
            for spine in ax.spines.values():
                spine.set_linewidth(2.0)
            ax.tick_params(width=2.0, labelsize=14)
            
            plot_name = f"{board_folder}_{orientation}_{filename[:-5]}_rmse.png"
            plt.tight_layout()
            plt.savefig(os.path.join(out_dir, plot_name), dpi=300)
            plt.close()
            
        except Exception as e:
            # print(f"Error processing {file_path}: {e}")
            pass

    if results:
        df_summary = pd.DataFrame(results)
        summary_path = os.path.join(out_dir, 'Onboard_Resistance_RMSE_Summary.xlsx')
        df_summary.to_excel(summary_path, index=False)
        print(f"\nSaved summary to: {summary_path}")

def main():
    # Process both boards
    process_rmse("Peters_Board")
    process_rmse("Hsin_Tings_Board")

if __name__ == "__main__":
    main()
