import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def calculate_rmse(y_true, y_pred):
    return np.sqrt(np.mean((y_true - y_pred)**2))

def main():
    board_folder = "Board1"
    filename = "B1A.xlsx"
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

    # 3. Calculate Math
    # Math for Resistance
    p_R = np.polyfit(on_I, on_R, 1)
    fit_line_R = np.polyval(p_R, on_I)
    rmse_R = calculate_rmse(on_R, fit_line_R)

    # Math for Gauss
    idx_0 = np.argmin(np.abs(on_I))
    implied_G = (on_R - on_R[idx_0]) / sens
    p_G = np.polyfit(on_I, implied_G, 1)
    fit_line_G = np.polyval(p_G, on_I)
    rmse_G = calculate_rmse(implied_G, fit_line_G)

    # ==========================================
    # PLOTTING THE INFOGRAPHIC
    # ==========================================
    fig, axs = plt.subplots(1, 2, figsize=(14, 7), facecolor=(0.94, 0.94, 0.94))
    fig.suptitle('Understanding Errors: Resistance vs Magnetic Field', fontsize=20, fontweight='bold', y=1.05)

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

    # --- PANEL 1: RMSE of Resistance ---
    axs[0].plot(on_I, on_R, 'm-', linewidth=2.5, label='Raw Sensor Data (Ohms)')
    axs[0].plot(on_I, fit_line_R, 'k--', linewidth=2.5, label='Ideal Linear Fit')
    style_ax(axs[0], '1. Resistance Error (Ohms)', 'Kepco Current (A)', 'Resistance (Ohms)')
    
    text_R = (
        f"Raw Hardware Noise & Hysteresis\n"
        f"------------------------------\n"
        f"RMSE = {rmse_R:.3f} Ohms\n\n"
        f"(This is hardware-dependent.\n"
        f"A 5Ω error is huge for a 50Ω sensor,\n"
        f"but tiny for a 5000Ω sensor.)"
    )
    axs[0].text(0.05, 0.95, text_R, transform=axs[0].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)
    axs[0].legend(loc='lower right')

    # --- PANEL 2: RMSE of Gauss ---
    axs[1].plot(on_I, implied_G, 'b-', linewidth=2.5, label='Implied Field Data (Gauss)')
    axs[1].plot(on_I, fit_line_G, 'r--', linewidth=2.5, label='Ideal Linear Fit')
    style_ax(axs[1], '2. Magnetic Field Error (Gauss)', 'Kepco Current (A)', 'Implied Magnetic Field (Gauss)')
    
    text_G = (
        f"Normalized Physical Uncertainty\n"
        f"------------------------------\n"
        f"RMSE = {rmse_G:.4f} Gauss\n\n"
        f"(This standardizes all sensors.\n"
        f"It tells us the true physical resolution\n"
        f"limit of the sensor array in Gauss.)"
    )
    axs[1].text(0.05, 0.95, text_G, transform=axs[1].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)
    axs[1].legend(loc='lower right')

    plt.tight_layout()
    
    output_path = os.path.join(base_dir, 'RMSE_Visualization.png')
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor=fig.get_facecolor())
    print(f"Visualization saved successfully to: {output_path}")

if __name__ == "__main__":
    main()
