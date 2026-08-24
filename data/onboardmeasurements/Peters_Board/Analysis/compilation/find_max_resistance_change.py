import os
import glob
import numpy as np
import pandas as pd


def main():
    # All onboard measurement files live in the same directory as this script.
    base_dir = os.path.dirname(os.path.abspath(__file__))
    xlsx_files = sorted(glob.glob(os.path.join(base_dir, '*.xlsx')))

    output_name = 'MaxResistanceChange_Summary.xlsx'
    output_path = os.path.join(base_dir, output_name)

    results = []
    skipped = []

    for filepath in xlsx_files:
        filename = os.path.basename(filepath)

        # Skip Excel lock files, and skip any previous output from this
        # script (or other scripts in this pipeline) that might be sitting
        # in the same folder.
        if filename.startswith('~$'):
            continue
        if filename == output_name:
            continue
        if filename.startswith('CorrelatedField_') or filename.startswith('MaxResistanceChange_'):
            continue

        try:
            df = pd.read_excel(filepath)

            # Use the first two columns positionally (Kepco_Current_A,
            # Resistance_Ohms) rather than relying on exact header names,
            # in case of naming differences between files.
            I = df.iloc[:, 0].to_numpy(dtype=float)
            R = df.iloc[:, 1].to_numpy(dtype=float)

            # Nominal resistance = resistance at (or nearest to) zero current
            idx0 = int(np.argmin(np.abs(I)))
            R_nominal = R[idx0]

            # Resistance change relative to nominal, at every point
            delta_R = R - R_nominal

            # Point with the largest magnitude of change (relative to nominal)
            idx_max = int(np.argmax(np.abs(delta_R)))

            # Peak-to-peak change: max resistance minus min resistance across
            # the whole sweep, independent of the nominal reference point.
            # This can be bigger than Max_Abs_Delta_R_Ohms if the sensor
            # responds asymmetrically on either side of nominal (e.g. swings
            # further in the negative-current direction than the positive).
            R_max = R.max()
            R_min = R.min()
            peak_to_peak_delta_R = R_max - R_min

            results.append({
                'Filename': filename,
                'R_Nominal_Ohms': R_nominal,
                'Current_At_Max_A': I[idx_max],
                'Resistance_At_Max_Ohms': R[idx_max],
                'Max_Delta_R_Ohms': delta_R[idx_max],
                'Max_Abs_Delta_R_Ohms': abs(delta_R[idx_max]),
                'Peak_To_Peak_Delta_R_Ohms': peak_to_peak_delta_R,
            })

            print(f'[PROCESSED] {filename} -> max |ΔR| = {abs(delta_R[idx_max]):.4f} Ohms '
                  f'at I = {I[idx_max]:.4f} A (ΔR = {delta_R[idx_max]:+.4f} Ohms), '
                  f'peak-to-peak ΔR = {peak_to_peak_delta_R:.4f} Ohms')

        except Exception as e:
            skipped.append(filename)
            print(f'[SKIPPED] {filename} -> error while processing: {e}')

    if results:
        # Sort alphabetically by filename
        out_df = pd.DataFrame(results).sort_values('Filename', ascending=True)
        out_df.to_excel(output_path, index=False)
        print(f'\nSaved summary to: {output_path}')
    else:
        print('\nNo files were processed; no summary file was created.')

    print('\n===== Summary =====')
    print(f'Processed ({len(results)}):')
    for r in results:
        print(f"  - {r['Filename']}")
    print(f'Skipped ({len(skipped)}):')
    for s in skipped:
        print(f'  - {s}')


if __name__ == '__main__':
    main()
