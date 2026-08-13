import pandas as pd
import numpy as np
import os
import glob

block_map = {
    'B1': 1,
    'B2': 1,
    'B4': 1,
    'B3': 2,
    'B5': 2
}

pin_to_sensor = {
    'A': 'A', 'G': 'A',
    'B': 'B', 'H': 'B',
    'C': 'C', 'I': 'C',
    'D': 'D', 'J': 'D',
    'E': 'E', 'K': 'E',
    'F': 'F', 'L': 'F'
}

def get_file_info(filepath):
    filename = os.path.basename(filepath)
    name = filename.split('.')[0].upper() # e.g. "B1A"
    if name.startswith('B') and len(name) >= 3:
        board = name[:-1]
        pin = name[-1]
        
        board_num = int(board[1:]) if board[1:].isdigit() else 99
        block = block_map.get(board, 99)
        sensor = pin_to_sensor.get(pin, 'Z')
        
        return board_num, block, sensor, pin, board
    return 99, 99, 'Z', 'Z', 'Z'

def sort_key(filepath):
    board_num, block, sensor, pin, _ = get_file_info(filepath)
    return (board_num, sensor, pin)

def export_to_excel(records, output_path):
    df = pd.DataFrame(records)
    if df.empty:
        return
        
    # Create the Pin Group (A-F vs G-L) to separate the two pins of the same sensor on the same board
    df['PinGroup'] = df['Pin'].apply(lambda p: 'A-F' if p in ['A','B','C','D','E','F'] else 'G-L')
    df['RowName'] = 'Board ' + df['Board'].astype(str) + ' (' + df['PinGroup'] + ')'
    
    parameters = ['MR Ratio', 'Sensitivity', 'Nom Resistance', 'Max Hysteresis', 'Min Resistance', 'Max Resistance']
    sensors = ['A', 'B', 'C', 'D', 'E', 'F']
    
    with pd.ExcelWriter(output_path, engine='xlsxwriter') as writer:
        for param in parameters:
            sheet_name = param[:31] # Excel limits sheet names to 31 chars
            worksheet = writer.book.add_worksheet(sheet_name)
            writer.sheets[sheet_name] = worksheet
            
            row_idx = 0
            bold_format = writer.book.add_format({'bold': True})
            
            # Format specific parameters visually (optional but nice)
            num_format = writer.book.add_format({'num_format': '0.0000'})
            if 'Ratio' in param:
                num_format = writer.book.add_format({'num_format': '0.0000 "%"'})
            
            for block in sorted(df['Block'].unique()):
                if block == 99: continue
                
                worksheet.write(row_idx, 0, f"Sensor block {block}", bold_format)
                row_idx += 1
                
                headers = ['Sensor/Board'] + [f"Sensor {s}" for s in sensors]
                for col_idx, header in enumerate(headers):
                    worksheet.write(row_idx, col_idx, header, bold_format)
                row_idx += 1
                
                block_df = df[df['Block'] == block]
                if not block_df.empty:
                    # Pivot the data
                    pivot = block_df.pivot_table(index=['Board', 'PinGroup', 'RowName'], columns='Sensor', values=param, aggfunc='first')
                    
                    # Ensure all sensors exist in the pivot
                    for s in sensors:
                        if s not in pivot.columns:
                            pivot[s] = np.nan
                            
                    pivot = pivot[sensors] # Order columns A-F
                    pivot = pivot.sort_index() # Sort by Board then PinGroup
                    
                    for index, row_data in pivot.iterrows():
                        r_name = index[2] # 'RowName' is the 3rd level in our multi-index
                        worksheet.write(row_idx, 0, r_name)
                        for col_idx, s in enumerate(sensors):
                            val = row_data[s]
                            if pd.notna(val):
                                worksheet.write(row_idx, col_idx + 1, val, num_format)
                            else:
                                worksheet.write(row_idx, col_idx + 1, "")
                        row_idx += 1
                        
                row_idx += 2 # Spacing between blocks
                
            # Set column widths nicely
            worksheet.set_column(0, 0, 20)
            worksheet.set_column(1, len(sensors), 15)

def process_directory(base_dir):
    excel_files = glob.glob(os.path.join(base_dir, 'Board*', '**', '*.xlsx'), recursive=True)
    
    if not excel_files:
        print("No Excel files found in the directory.")
        return
        
    excel_files = sorted(excel_files, key=sort_key)

    print("======================================================")
    print("   PETERS BOARD RESPONSE MEASUREMENT FULL ANALYSIS")
    print("======================================================\n")

    records = []

    for file in excel_files:
        if '~$' in file or 'Analysis' in file or 'Summary' in file:
            continue
            
        try:
            board_num, block, sensor, pin, board_str = get_file_info(file)
            if board_num == 99:
                continue
                
            df = pd.read_excel(file)
            
            R = df['Resistance_Ohms'].values if 'Resistance_Ohms' in df.columns else df.iloc[:, 1].values
            G = df['Magnetic_Field_G'].values if 'Magnetic_Field_G' in df.columns else df.iloc[:, 2].values
            I = df['Kepco_Current_A'].values if 'Kepco_Current_A' in df.columns else df.iloc[:, 0].values
            
            if 'Sensitivity_Ohms_per_G' in df.columns:
                sens = df['Sensitivity_Ohms_per_G'].iloc[0]
            else:
                sens = df.iloc[:, 4].iloc[0]
                
            r_min, r_max = R.min(), R.max()
            g_min, g_max = G.min(), G.max()
            i_min, i_max = I.min(), I.max()
            
            mr_ratio = ((r_max - r_min) / r_min) * 100
            
            idx_g0 = np.argmin(np.abs(G))
            nominal_r = R[idx_g0]
            actual_g0 = G[idx_g0]
            
            max_idx = np.argmax(I)
            if max_idx > 0 and max_idx < len(I) - 1:
                G_fwd, R_fwd = G[:max_idx+1], R[:max_idx+1]
                G_bwd, R_bwd = G[max_idx:][::-1], R[max_idx:][::-1]
                
                R_bwd_aligned = np.interp(G_fwd, G_bwd, R_bwd)
                hysteresis_gap = np.abs(R_fwd - R_bwd_aligned)
                max_gap_idx = np.argmax(hysteresis_gap)
                max_gap_ohms = hysteresis_gap[max_gap_idx]
                max_gap_G = G_fwd[max_gap_idx]
            else:
                max_gap_ohms = 0
                max_gap_G = 0

            print(f"Board {board_num} Block {block} Sensor {sensor} Pin {pin}")
            print(f"  -> MR Ratio:       {mr_ratio:.4f} %")
            print(f"  -> Sensitivity:    {sens:.4f} Ohms/G")
            print(f"  -> Nom Res (G~0):  {nominal_r:.2f} Ohms (at {actual_g0:.4f} G)")
            print(f"  -> Max Hysteresis: {max_gap_ohms:.2f} Ohms (at {max_gap_G:.4f} G)")
            print(f"  -> Resistance:     Min = {r_min:.2f}, Max = {r_max:.2f} Ohms")
            print(f"  -> Gauss:          Min = {g_min:.2f}, Max = {g_max:.2f} G")
            print(f"  -> Current:        Min = {i_min:.2f}, Max = {i_max:.2f} A")
            print("-" * 54)
            
            records.append({
                'Board': board_num,
                'Block': block,
                'Sensor': sensor,
                'Pin': pin,
                'MR Ratio': mr_ratio,
                'Sensitivity': sens,
                'Nom Resistance': nominal_r,
                'Max Hysteresis': max_gap_ohms,
                'Min Resistance': r_min,
                'Max Resistance': r_max
            })
            
        except Exception as e:
            pass

    if records:
        out_path = os.path.join(base_dir, 'Analysis_Summary.xlsx')
        export_to_excel(records, out_path)
        print(f"\nSuccessfully saved Excel summary to: {out_path}")

if __name__ == "__main__":
    target_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'LibraryBased', 'Week5', 'Peters_Board'))
    process_directory(target_dir)
