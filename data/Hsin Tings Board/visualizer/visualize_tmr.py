import os
import glob
import pandas as pd
import matplotlib.pyplot as plt
import re
from collections import defaultdict

def main():
    # Set the data directory to the current directory
    data_dir = "."

    # 1. Find all Excel files recursively in Board folders
    file_pattern = os.path.join(data_dir, "Board*", "Board*_*.xlsx")
    all_files = glob.glob(file_pattern)
    
    if not all_files:
        print("No Excel files found! Please make sure you run this in the data directory.")
        return

    # Data structures to organize our DataFrames
    board_data = defaultdict(dict)       # board_data[board][test_point] = df
    test_point_data = defaultdict(dict)  # test_point_data[test_point][board] = df

    print(f"Found {len(all_files)} files. Reading data...")

    for file in all_files:
        basename = os.path.basename(file)
        # Parse names like "Board1_A.xlsx" -> "Board1", "A"
        match = re.match(r"(Board\d+)_([A-Za-z0-9]+)\.xlsx", basename)
        if match:
            board = match.group(1)
            test_point = match.group(2)
            
            # Read the data
            df = pd.read_excel(file)
            
            # Store it in our dictionaries
            board_data[board][test_point] = df
            test_point_data[test_point][board] = df
            
    print("Data loaded. Generating plots...")

    # Define which columns to plot. 
    # From earlier inspection, we have 'Kepco_Current_A', 'Resistance_Ohms', 'Magnetic_Field_T'
    x_col = 'Magnetic_Field_T'
    y_col = 'Resistance_Ohms'

    # --- INTRA-BOARD VISUALIZATION ---
    # One plot per Board, overlaying all Test Points on that board.
    for board, tp_dict in board_data.items():
        plt.figure(figsize=(10, 6))
        plt.title(f"Intra-Board Variation (All points on {board})", fontsize=14)
        
        for tp, df in sorted(tp_dict.items()):
            if x_col in df.columns and y_col in df.columns:
                plt.plot(df[x_col], df[y_col], label=f"Point {tp}")
                
        plt.xlabel("Magnetic Field (T)", fontsize=12)
        plt.ylabel("Resistance (Ohms)", fontsize=12)
        plt.legend(title="Test Points")
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        out_filename = f"Plot_Intra_{board}.png"
        plt.savefig(out_filename, dpi=150)
        plt.close()
        print(f"Saved {out_filename}")

    # --- INTER-BOARD VISUALIZATION ---
    # One plot per Test Point, overlaying that specific point across all Boards.
    for tp, board_dict in test_point_data.items():
        plt.figure(figsize=(10, 6))
        plt.title(f"Inter-Board Variation (Test Point {tp} across all boards)", fontsize=14)
        
        for board, df in sorted(board_dict.items()):
            if x_col in df.columns and y_col in df.columns:
                plt.plot(df[x_col], df[y_col], label=board)
                
        plt.xlabel("Magnetic Field (T)", fontsize=12)
        plt.ylabel("Resistance (Ohms)", fontsize=12)
        plt.legend(title="Boards")
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        out_filename = f"Plot_Inter_Point_{tp}.png"
        plt.savefig(out_filename, dpi=150)
        plt.close()
        print(f"Saved {out_filename}")
        
    print("All visualizations complete!")

if __name__ == "__main__":
    main()
