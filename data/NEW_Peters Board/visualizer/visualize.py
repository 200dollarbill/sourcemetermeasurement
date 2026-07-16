import os
import glob
import pandas as pd
import matplotlib.pyplot as plt
import re
from collections import defaultdict


def main():
    # Get project root relative to this script's location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.abspath(os.path.join(script_dir, ".."))

    # Find all *_NEW.xlsx files inside Board folders
    file_pattern = os.path.join(data_dir, "Board*", "B*_NEW.xlsx")
    all_files = glob.glob(file_pattern)

    print(f"Searching: {file_pattern}")

    if not all_files:
        print("No Excel files found!")
        return

    print("Found files:")
    for f in all_files:
        print(f)

    # Data structures
    board_data = defaultdict(dict)
    test_point_data = defaultdict(dict)

    print(f"\nFound {len(all_files)} files. Reading data...\n")

    for file in all_files:
        basename = os.path.basename(file)

        # Match filenames like:
        # B1A_NEW.xlsx
        # B2B_NEW.xlsx
        # B3J_NEW.xlsx
        match = re.match(r"B(\d+)([A-Za-z0-9]+)_NEW\.xlsx$", basename)

        if not match:
            print(f"Skipping unmatched filename: {basename}")
            continue

        board = f"Board{match.group(1)}"
        test_point = match.group(2)

        print(f"Loading: {basename} -> {board}, Point {test_point}")

        try:
            df = pd.read_excel(file)

            board_data[board][test_point] = df
            test_point_data[test_point][board] = df

        except Exception as e:
            print(f"Failed to read {basename}: {e}")

    print("\nData loaded. Generating plots...\n")

    x_col = "Magnetic_Field_G"
    y_col = "Resistance_Ohms"

    # ==========================================================
    # INTRA-BOARD PLOTS
    # ==========================================================
    for board, tp_dict in sorted(board_data.items()):

        plt.figure(figsize=(10, 6))
        plt.title(f"Intra-Board Variation ({board})", fontsize=14)

        plotted = False

        for tp, df in sorted(tp_dict.items()):

            if x_col not in df.columns:
                print(f"{board}-{tp}: Missing column '{x_col}'")
                continue

            if y_col not in df.columns:
                print(f"{board}-{tp}: Missing column '{y_col}'")
                continue

            plt.plot(df[x_col], df[y_col], label=f"Point {tp}")
            plotted = True

        if plotted:
            plt.xlabel("Magnetic Field (T)")
            plt.ylabel("Resistance (Ohms)")
            plt.legend(title="Test Points")
            plt.grid(True, linestyle="--", alpha=0.7)
            plt.tight_layout()

            out_filename = f"Plot_Intra_{board}.png"
            plt.savefig(out_filename, dpi=150)
            print(f"Saved {out_filename}")

        plt.close()

    # ==========================================================
    # INTER-BOARD PLOTS
    # ==========================================================
    for tp, board_dict in sorted(test_point_data.items()):

        plt.figure(figsize=(10, 6))
        plt.title(f"Inter-Board Variation (Point {tp})", fontsize=14)

        plotted = False

        for board, df in sorted(board_dict.items()):

            if x_col not in df.columns:
                print(f"{board}-{tp}: Missing column '{x_col}'")
                continue

            if y_col not in df.columns:
                print(f"{board}-{tp}: Missing column '{y_col}'")
                continue

            plt.plot(df[x_col], df[y_col], label=board)
            plotted = True

        if plotted:
            plt.xlabel("Magnetic Field (T)")
            plt.ylabel("Resistance (Ohms)")
            plt.legend(title="Boards")
            plt.grid(True, linestyle="--", alpha=0.7)
            plt.tight_layout()

            out_filename = f"Plot_Inter_Point_{tp}.png"
            plt.savefig(out_filename, dpi=150)
            print(f"Saved {out_filename}")

        plt.close()

    print("\nAll visualizations complete!")


if __name__ == "__main__":
    main()