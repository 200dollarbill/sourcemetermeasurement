import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def main():
    board_folder = "Board3"
    filename = "B3C.xlsx"
    orientation = "PointYOutToIn"
    
    # Paths to the two respective files
    base_dir = os.path.dirname(os.path.abspath(__file__))
    onboard_file = os.path.abspath(os.path.join(base_dir, '..', 'Hsin_Tings_Board', board_folder, orientation, filename))

    if not os.path.exists(onboard_file):
        print("Could not find the specific file for visualization. Please check paths.")
        return

    # 1. Read Onboard Data
    onboard_df = pd.read_excel(onboard_file)
    if 'Resistance_Ohms' in onboard_df.columns:
        on_R = onboard_df['Resistance_Ohms'].values
        on_I = onboard_df['Kepco_Current_A'].values
    else:
        on_I = onboard_df.iloc[:, 0].values
        on_R = onboard_df.iloc[:, 1].values

    # 2. Math
    p_R = np.polyfit(on_I, on_R, 1)
    fit_line_R = np.polyval(p_R, on_I)
    
    # Residuals (Errors)
    errors = on_R - fit_line_R
    rmse_R = np.sqrt(np.mean(errors**2))

    # ==========================================
    # PLOTTING THE INFOGRAPHIC
    # ==========================================
    fig, axs = plt.subplots(1, 3, figsize=(18, 6), facecolor=(0.94, 0.94, 0.94))
    fig.suptitle('Step-by-Step: Calculating Resistance RMSE', fontsize=24, fontweight='bold', y=1.05)

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

    # --- PANEL 1: Raw Data ---
    axs[0].plot(on_I, on_R, 'm-', linewidth=2.5)
    style_ax(axs[0], 'Step 1: Onboard Measurements', 'Input Current (A)', 'Resistance (Ohms)')
    axs[0].text(0.05, 0.95, "Record the raw resistance sweep.", 
                transform=axs[0].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)

    # --- PANEL 2: Best Fit Line ---
    axs[1].plot(on_I, on_R, 'm-', linewidth=2.5, alpha=0.5, label='Raw Data')
    axs[1].plot(on_I, fit_line_R, 'k--', linewidth=3.0, label='Ideal Linear Fit')
    style_ax(axs[1], 'Step 2: Create Ideal Line', 'Input Current (A)', 'Resistance (Ohms)')
    axs[1].text(0.05, 0.95, "Calculate the 'Line of Best Fit'\nto find the linearity", 
                transform=axs[1].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)
    axs[1].legend(loc='lower right')

    # --- PANEL 3: Calculating Error (Residuals) ---
    # Plot the residuals as a bar/stem or line chart around 0
    axs[2].axhline(0, color='k', linewidth=2.0, linestyle='--')
    axs[2].plot(on_I, errors, 'r-', linewidth=2.5, label='Error (Raw - Ideal)')
    axs[2].fill_between(on_I, errors, 0, color='red', alpha=0.2)
    style_ax(axs[2], 'Step 3: Count the Error (RMSE)', 'Input Current (A)', 'Error Magnitude (Ohms)')
    
    text_rmse = (
        f"1. Measure distance from ideal (Error)\n"
        f"2. Square them to remove negatives\n"
        f"3. Find the Mean, then Square Root\n\n"
        f"Final RMSE = {rmse_R:.3f} Ohms"
    )
    axs[2].text(0.05, 0.95, text_rmse, transform=axs[2].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)
    axs[2].legend(loc='lower right')

    plt.tight_layout()
    
    output_path = os.path.join(base_dir, 'RMSE_Step_by_Step_Visualization.png')
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor=fig.get_facecolor())
    print(f"Visualization saved successfully to: {output_path}")

if __name__ == "__main__":
    main()
