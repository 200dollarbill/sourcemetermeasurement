import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def main():
    board_folder = "Board4"
    filename = "B4B.xlsx"
    orientation = "PointYOutToIn"
    
    # Paths to the two respective files
    base_dir = os.path.dirname(os.path.abspath(__file__))
    onboard_file = os.path.abspath(os.path.join(base_dir, '..', 'Peters_Board', board_folder, orientation, filename))
    response_file = os.path.abspath(os.path.join(base_dir, '..', '..', 'responsemeasurements', 'LibraryBased', 'Week5', 'Peters_Board', board_folder, filename))

    if not os.path.exists(onboard_file) or not os.path.exists(response_file):
        print("Could not find the specific files for visualization. Please check paths.")
        return

    # 1. Read Response (Calibration) Data
    resp_df = pd.read_excel(response_file)
    if 'Sensitivity_Ohms_per_G' in resp_df.columns:
        sens = resp_df['Sensitivity_Ohms_per_G'].iloc[0]
    else:
        sens = resp_df.iloc[:, 4].iloc[0]
        
    # 2. Read Onboard Data
    onboard_df = pd.read_excel(onboard_file)
    if 'Resistance_Ohms' in onboard_df.columns:
        on_R = onboard_df['Resistance_Ohms'].values
        on_I = onboard_df['Kepco_Current_A'].values
    else:
        on_I = onboard_df.iloc[:, 0].values
        on_R = onboard_df.iloc[:, 1].values

    # 3. Math (Gauss)
    idx_0 = np.argmin(np.abs(on_I))
    implied_G = (on_R - on_R[idx_0]) / sens
    p_G = np.polyfit(on_I, implied_G, 1)
    fit_line_G = np.polyval(p_G, on_I)
    
    # Residuals (Errors)
    errors = implied_G - fit_line_G
    rmse_G = np.sqrt(np.mean(errors**2))

    # ==========================================
    # PLOTTING THE INFOGRAPHIC
    # ==========================================
    fig, axs = plt.subplots(1, 3, figsize=(18, 6), facecolor=(0.94, 0.94, 0.94))
    fig.suptitle('Step-by-Step: Calculating Magnetic Field RMSE', fontsize=24, fontweight='bold', y=1.05)

    def style_ax(ax, title, xlabel, ylabel):
        ax.set_facecolor((0.94, 0.94, 0.94))
        ax.set_title(title, fontsize=16, fontweight='bold', pad=15)
        ax.set_xlabel(xlabel, fontsize=14, fontweight='bold')
        ax.set_ylabel(ylabel, fontsize=14, fontweight='bold')
        ax.grid(True, linestyle='--', alpha=0.7)
        for spine in ax.spines.values():
            spine.set_linewidth(2.0)
        ax.tick_params(width=2.0, labelsize=12)

    props = dict(boxstyle='round', facecolor='wheat', alpha=0.9)

    # --- PANEL 1: Implied Field Data ---
    axs[0].plot(on_I, implied_G, 'b-', linewidth=2.5)
    style_ax(axs[0], 'Step 1: Convert to Magnetic Field (G)', 'Input Current (A)', 'Implied Field (Gauss)')
    axs[0].text(0.05, 0.95, "Convert raw resistance to Gauss\nusing the obtained sensitivity.", 
                transform=axs[0].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)

    # --- PANEL 2: Best Fit Line ---
    axs[1].plot(on_I, implied_G, 'b-', linewidth=2.5, alpha=0.5, label='Implied Field')
    axs[1].plot(on_I, fit_line_G, 'k--', linewidth=3.0, label='Ideal Linear Fit')
    style_ax(axs[1], 'Step 2: Create Ideal Line', 'Input Current (A)', 'Implied Field (Gauss)')
    axs[1].text(0.05, 0.95, "Calculate the 'Line of Best Fit'\nto find the linearity.", 
                transform=axs[1].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)
    axs[1].legend(loc='lower right')

    # --- PANEL 3: Calculating Error (Residuals) ---
    axs[2].axhline(0, color='k', linewidth=2.0, linestyle='--')
    axs[2].plot(on_I, errors, 'g-', linewidth=2.5, label='Error (Raw - Ideal)')
    axs[2].fill_between(on_I, errors, 0, color='green', alpha=0.2)
    style_ax(axs[2], 'Step 3: Count the Error (RMSE)', 'Input Current (A)', 'Error Magnitude (Gauss)')
    
    text_rmse = (
        f"1. Measure distance from ideal (Error)\n"
        f"2. Square them to remove negatives\n"
        f"3. Find the Mean, then Square Root\n\n"
        f"Final RMSE = {rmse_G:.4f} Gauss"
    )
    axs[2].text(0.05, 0.95, text_rmse, transform=axs[2].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)
    axs[2].legend(loc='lower right')

    plt.tight_layout()
    
    output_path = os.path.join(base_dir, 'RMSE_Gauss_Step_by_Step_Visualization.png')
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor=fig.get_facecolor())
    print(f"Visualization saved successfully to: {output_path}")

if __name__ == "__main__":
    main()
