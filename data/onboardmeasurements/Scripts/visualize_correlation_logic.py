import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def main():
    # We will pick a single, specific measurement to visualize the logic.
    # Let's use Peter's Board 1, Sensor B1A as our example.
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
        
    resp_R = resp_df['Resistance_Ohms'].values if 'Resistance_Ohms' in resp_df.columns else resp_df.iloc[:, 1].values
    resp_G = resp_df['Magnetic_Field_G'].values if 'Magnetic_Field_G' in resp_df.columns else resp_df.iloc[:, 2].values

    # 2. Read Onboard Data
    onboard_df = pd.read_excel(onboard_file)
    if 'Resistance_Ohms' in onboard_df.columns:
        on_R = onboard_df['Resistance_Ohms'].values
        on_I = onboard_df['Kepco_Current_A'].values
    else:
        on_I = onboard_df.iloc[:, 0].values
        on_R = onboard_df.iloc[:, 1].values

    # 3. Calculate Implied Gauss and Correlation
    idx_0 = np.argmin(np.abs(on_I))
    implied_G = (on_R - on_R[idx_0]) / sens
    p = np.polyfit(on_I, implied_G, 1)
    slope = p[0]

    # ==========================================
    # PLOTTING THE INFOGRAPHIC
    # ==========================================
    fig, axs = plt.subplots(1, 3, figsize=(18, 6), facecolor=(0.94, 0.94, 0.94))
    fig.suptitle('How the Correlation (m) is Calculated', fontsize=24, fontweight='bold', y=1.05)

    # Styling function
    def style_ax(ax, title, xlabel, ylabel):
        ax.set_facecolor((0.94, 0.94, 0.94))
        ax.set_title(title, fontsize=16, fontweight='bold', pad=15)
        ax.set_xlabel(xlabel, fontsize=14, fontweight='bold')
        ax.set_ylabel(ylabel, fontsize=14, fontweight='bold')
        ax.grid(True, linestyle='--', alpha=0.7)
        for spine in ax.spines.values():
            spine.set_linewidth(2.0)
        ax.tick_params(width=2.0, labelsize=12)

    # --- PANEL 1: Calibration (Response Measurement) ---
    axs[0].plot(resp_G, resp_R, 'k-', linewidth=2.5)
    style_ax(axs[0], 'Step 1: Measured sensor response', 'Magnetic Field from Helmholtz coil (G)', 'Resistance (Ohms)')
    
    # Add a math box for Panel 1
    props = dict(boxstyle='round', facecolor='wheat', alpha=0.9)
    axs[0].text(0.05, 0.95, f"Obtain true Sensitivity:\n = {sens:.2f} Ohms/G", 
                transform=axs[0].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)

    # --- PANEL 2: Raw Trace Test (Onboard Measurement) ---
    axs[1].plot(on_I, on_R, 'm-', linewidth=2.5)
    style_ax(axs[1], 'Step 2: Onboard measurement', 'Power Amplifier Current (A)', 'Resistance (Ohms)')
    
    # Add a math box for Panel 2
    axs[1].text(0.05, 0.95, "Current sweeps through trace underneath\nthe sensor, causing Resistance to change.", 
                transform=axs[1].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)

    # --- PANEL 3: Implied Correlation (The Result) ---
    axs[2].plot(on_I, implied_G, 'b-', linewidth=2.5, label='Sweep Data')
    
    # Plot the line of best fit to visualize 'm'
    fit_line = np.poly1d(p)
    axs[2].plot(on_I, fit_line(on_I), 'r--', linewidth=3.0, label=f'Best Fit Line')
    
    style_ax(axs[2], 'Step 3: Implied Field', 'Power Amplifier Current (A)', 'Implied Magnetic Field (G)')
    
    # Add a math box for Panel 3
    final_text = (
        "Implied Field = Δ Resistance / Sensitivity\n"
        f"Best fit line (red) & implied field (blue)\n"
        f"gives the corellation m = {slope:.3f} in G/A"
    )
    axs[2].text(0.05, 0.95, final_text, 
                transform=axs[2].transAxes, fontsize=12, fontweight='bold',
                verticalalignment='top', bbox=props)
    axs[2].legend(loc='lower right', fontsize=12)

    plt.tight_layout()
    
    output_path = os.path.join(base_dir, 'Logic_Visualization.png')
    plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor=fig.get_facecolor())
    print(f"Visualization saved successfully to: {output_path}")

if __name__ == "__main__":
    main()
