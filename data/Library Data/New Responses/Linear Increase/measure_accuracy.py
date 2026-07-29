import pandas as pd
import numpy as np
import glob
import os

def analyze_directory():
    # Find all Excel files not containing 'Library' in their name
    excel_files = [f for f in glob.glob('*.xlsx') if 'Library' not in f]
    
    if not excel_files:
        print("No measurement Excel files found.")
        return

    all_errors = []
    total_steps = 0

    print(f"Analyzing {len(excel_files)} files in {os.getcwd()}...")

    for f in excel_files:
        try:
            # Read the TimeData sheet
            df = pd.read_excel(f, sheet_name='TimeData')
            
            # Find unique current values and sort them to get the step progression
            unique_curr = df['Kepco_Current_A'].unique()
            sorted_curr = np.sort(unique_curr)
            diffs = np.diff(sorted_curr)
            
            # Filter out any major jumps (like return-to-zero) to isolate the ~0.01A steps
            # Since the user noted the timestep is 0.01mA (likely referring to the 10mA/0.01A step)
            step_diffs = diffs[(diffs > 0.005) & (diffs < 0.015)]
            
            if len(step_diffs) > 0:
                # Calculate absolute error against the theoretical 0.01A step
                errors = np.abs(step_diffs - 0.01)
                all_errors.extend(errors)
                total_steps += len(step_diffs)
                print(f" - {f}: {len(step_diffs)} steps, average error {np.mean(errors):.6f} A")
            else:
                print(f" - {f}: No valid 0.01A steps found.")
        except Exception as e:
            print(f" - {f}: Error processing file -> {e}")

    if all_errors:
        overall_avg_error = np.mean(all_errors)
        print(f"\n--- Summary ---")
        print(f"Total steps analyzed: {total_steps}")
        print(f"Overall average Kepco current error: {overall_avg_error:.6f} A ({overall_avg_error * 1000:.3f} mA)")
    else:
        print("\nNo step errors could be calculated.")

if __name__ == "__main__":
    analyze_directory()
