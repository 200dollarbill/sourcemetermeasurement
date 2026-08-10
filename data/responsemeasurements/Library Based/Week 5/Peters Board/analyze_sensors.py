import zipfile
import xml.etree.ElementTree as ET
import sys
import glob
import os
import csv
import math

def read_xlsx(filename):
    with zipfile.ZipFile(filename, 'r') as z:
        shared_strings = []
        try:
            with z.open('xl/sharedStrings.xml') as f:
                tree = ET.parse(f)
                root = tree.getroot()
                ns = {'ns': root.tag.split('}')[0].strip('{')} if '}' in root.tag else {}
                if not ns:
                    ns = {'ns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
                for si in root.findall('ns:si', ns):
                    t = si.find('ns:t', ns)
                    if t is not None:
                        shared_strings.append(t.text)
                    else:
                        shared_strings.append('')
        except KeyError:
            pass
            
        with z.open('xl/worksheets/sheet1.xml') as f:
            tree = ET.parse(f)
            root = tree.getroot()
            ns = {'ns': root.tag.split('}')[0].strip('{')} if '}' in root.tag else {}
            if not ns:
                ns = {'ns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
            sheet_data = root.find('ns:sheetData', ns)
            
            rows = []
            for row in sheet_data.findall('ns:row', ns):
                row_data = []
                for c in row.findall('ns:c', ns):
                    v = c.find('ns:v', ns)
                    val = v.text if v is not None else ''
                    t = c.get('t')
                    if t == 's' and val:
                        val = shared_strings[int(val)]
                    
                    r = c.get('r')
                    if r:
                        col_str = ''.join(filter(str.isalpha, r))
                        col_idx = 0
                        for char in col_str:
                            col_idx = col_idx * 26 + (ord(char.upper()) - ord('A')) + 1
                        col_idx -= 1
                        while len(row_data) < col_idx:
                            row_data.append('')
                            
                    row_data.append(val)
                rows.append(row_data)
            return rows

def process_file(filename):
    try:
        data = read_xlsx(filename)
    except Exception as e:
        print(f"Error reading {filename}: {e}")
        return None

    if len(data) < 2:
        return None

    header = data[0]
    
    try:
        res_idx = header.index('Resistance_Ohms')
        mag_idx = header.index('Magnetic_Field_G')
        mr_idx = header.index('MR_Ratio_Percent')
        sens_idx = header.index('Sensitivity_Ohms_per_G')
    except ValueError:
        return None

    mr_ratios = []
    sensitivities = []
    res_mag = []
    
    for row in data[1:]:
        if not row or len(row) <= max(res_idx, mag_idx, mr_idx, sens_idx): continue
        try:
            res = float(row[res_idx])
            mag = float(row[mag_idx])
            mr = float(row[mr_idx])
            sens = float(row[sens_idx])
            mr_ratios.append(mr)
            sensitivities.append(abs(sens))
            res_mag.append((mag, res))
        except ValueError:
            continue

    if not res_mag:
        return None

    overall_mr = max(mr_ratios)
    sensitivity = max(sensitivities) # Assuming we take max sensitivity or max absolute sensitivity

    # Find nominal resistance closest to 0G
    closest_0g = min(res_mag, key=lambda x: abs(x[0]))
    nominal_res = closest_0g[1]

    # Hysteresis
    # Since sweeps might not perfectly align, let's round magnetic field to 1 decimal place to group
    # or find max difference for identical fields
    field_to_res = {}
    for mag, res in res_mag:
        rounded_mag = round(mag, 1)
        if rounded_mag not in field_to_res:
            field_to_res[rounded_mag] = []
        field_to_res[rounded_mag].append(res)
        
    max_hysteresis = 0
    for mag, res_list in field_to_res.items():
        if len(res_list) > 1:
            diff = max(res_list) - min(res_list)
            if diff > max_hysteresis:
                max_hysteresis = diff

    return {
        'overall_mr': overall_mr,
        'sensitivity': sensitivity,
        'max_hysteresis': max_hysteresis,
        'nominal_res': nominal_res
    }

base_dir = '/mnt/Data/yep/Kuliah/Tugas/Magang Programs/MagneticStationGUI/data/responsemeasurements/Library Based/Week 5/Peters Board'
boards = ['Board1', 'Board2', 'Board3']
pins = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L']

results = {}

for board in boards:
    board_dir = os.path.join(base_dir, board)
    results[board] = {}
    for pin in pins:
        # Search for exact match B1A.xlsx, B2A.xlsx, etc.
        # Note some files are B1F-Meas.xlsx, B2H-X.xlsx, etc., but we'll focus on the standard ones or grab them all?
        # User specified B1A means Board1 Pin A. So search for {B[123]}{pin}.xlsx
        b_prefix = 'B' + board[-1]
        pattern = os.path.join(board_dir, f"{b_prefix}{pin}*.xlsx")
        files = glob.glob(pattern)
        if not files:
            continue
        # If multiple, take the first one or process all? Let's take the first one or exactly matching
        target_file = None
        for f in files:
            fname = os.path.basename(f)
            if fname == f"{b_prefix}{pin}.xlsx":
                target_file = f
                break
        if not target_file:
            target_file = files[0]
            
        res = process_file(target_file)
        if res:
            results[board][pin] = res

# Prepare CSV output
csv_file = os.path.join(base_dir, 'Sensor_Measurements_Analysis.csv')
with open(csv_file, 'w', newline='') as f:
    writer = csv.writer(f)
    
    # Block 1 (Board 1 & 2)
    writer.writerow(['--- SENSOR BLOCK 1 (Board 1 & Board 2) ---'])
    writer.writerow(['Pin', 'Board 1 Overall MR (%)', 'Board 2 Overall MR (%)', 'Average Overall MR (%)',
                     'Board 1 Sensitivity (Ohms/G)', 'Board 2 Sensitivity (Ohms/G)', 'Average Sensitivity (Ohms/G)',
                     'Board 1 Max Hysteresis (Ohms)', 'Board 2 Max Hysteresis (Ohms)', 'Average Max Hysteresis (Ohms)',
                     'Board 1 Nominal Res (Ohms)', 'Board 2 Nominal Res (Ohms)', 'Average Nominal Res (Ohms)'])
                     
    b1_totals = {'mr': 0, 'sens': 0, 'hyst': 0, 'nom': 0, 'count': 0}
    b2_totals = {'mr': 0, 'sens': 0, 'hyst': 0, 'nom': 0, 'count': 0}
    
    for pin in pins:
        b1_res = results['Board1'].get(pin)
        b2_res = results['Board2'].get(pin)
        
        row = [pin]
        mr1, sens1, hyst1, nom1 = '', '', '', ''
        mr2, sens2, hyst2, nom2 = '', '', '', ''
        mr_avg, sens_avg, hyst_avg, nom_avg = '', '', '', ''
        
        if b1_res:
            mr1 = b1_res['overall_mr']
            sens1 = b1_res['sensitivity']
            hyst1 = b1_res['max_hysteresis']
            nom1 = b1_res['nominal_res']
            b1_totals['mr'] += mr1
            b1_totals['sens'] += sens1
            b1_totals['hyst'] += hyst1
            b1_totals['nom'] += nom1
            b1_totals['count'] += 1
            
        if b2_res:
            mr2 = b2_res['overall_mr']
            sens2 = b2_res['sensitivity']
            hyst2 = b2_res['max_hysteresis']
            nom2 = b2_res['nominal_res']
            b2_totals['mr'] += mr2
            b2_totals['sens'] += sens2
            b2_totals['hyst'] += hyst2
            b2_totals['nom'] += nom2
            b2_totals['count'] += 1
            
        if b1_res and b2_res:
            mr_avg = (mr1 + mr2) / 2
            sens_avg = (sens1 + sens2) / 2
            hyst_avg = (hyst1 + hyst2) / 2
            nom_avg = (nom1 + nom2) / 2
        elif b1_res:
            mr_avg, sens_avg, hyst_avg, nom_avg = mr1, sens1, hyst1, nom1
        elif b2_res:
            mr_avg, sens_avg, hyst_avg, nom_avg = mr2, sens2, hyst2, nom2
            
        row.extend([mr1, mr2, mr_avg, sens1, sens2, sens_avg, hyst1, hyst2, hyst_avg, nom1, nom2, nom_avg])
        writer.writerow(row)
        
    writer.writerow([])
    # Overall Block 1 Averages
    b1_avg_mr = b1_totals['mr'] / b1_totals['count'] if b1_totals['count'] else 0
    b1_avg_sens = b1_totals['sens'] / b1_totals['count'] if b1_totals['count'] else 0
    b1_avg_hyst = b1_totals['hyst'] / b1_totals['count'] if b1_totals['count'] else 0
    b1_avg_nom = b1_totals['nom'] / b1_totals['count'] if b1_totals['count'] else 0
    
    b2_avg_mr = b2_totals['mr'] / b2_totals['count'] if b2_totals['count'] else 0
    b2_avg_sens = b2_totals['sens'] / b2_totals['count'] if b2_totals['count'] else 0
    b2_avg_hyst = b2_totals['hyst'] / b2_totals['count'] if b2_totals['count'] else 0
    b2_avg_nom = b2_totals['nom'] / b2_totals['count'] if b2_totals['count'] else 0
    
    total_count = b1_totals['count'] + b2_totals['count']
    block1_avg_mr = (b1_totals['mr'] + b2_totals['mr']) / total_count if total_count else 0
    block1_avg_sens = (b1_totals['sens'] + b2_totals['sens']) / total_count if total_count else 0
    block1_avg_hyst = (b1_totals['hyst'] + b2_totals['hyst']) / total_count if total_count else 0
    block1_avg_nom = (b1_totals['nom'] + b2_totals['nom']) / total_count if total_count else 0
    
    writer.writerow(['OVERALL BLOCK 1 AVERAGE', '', '', block1_avg_mr, '', '', block1_avg_sens, '', '', block1_avg_hyst, '', '', block1_avg_nom])
    writer.writerow([])
    
    # Block 2 (Board 3)
    writer.writerow(['--- SENSOR BLOCK 2 (Board 3) ---'])
    writer.writerow(['Pin', 'Board 3 Overall MR (%)', 'Board 3 Sensitivity (Ohms/G)', 'Board 3 Max Hysteresis (Ohms)', 'Board 3 Nominal Res (Ohms)'])
    
    b3_totals = {'mr': 0, 'sens': 0, 'hyst': 0, 'nom': 0, 'count': 0}
    for pin in pins:
        b3_res = results['Board3'].get(pin)
        row = [pin]
        if b3_res:
            mr3 = b3_res['overall_mr']
            sens3 = b3_res['sensitivity']
            hyst3 = b3_res['max_hysteresis']
            nom3 = b3_res['nominal_res']
            b3_totals['mr'] += mr3
            b3_totals['sens'] += sens3
            b3_totals['hyst'] += hyst3
            b3_totals['nom'] += nom3
            b3_totals['count'] += 1
            row.extend([mr3, sens3, hyst3, nom3])
        else:
            row.extend(['', '', '', ''])
        writer.writerow(row)
        
    writer.writerow([])
    block2_avg_mr = b3_totals['mr'] / b3_totals['count'] if b3_totals['count'] else 0
    block2_avg_sens = b3_totals['sens'] / b3_totals['count'] if b3_totals['count'] else 0
    block2_avg_hyst = b3_totals['hyst'] / b3_totals['count'] if b3_totals['count'] else 0
    block2_avg_nom = b3_totals['nom'] / b3_totals['count'] if b3_totals['count'] else 0
    writer.writerow(['OVERALL BLOCK 2 AVERAGE', block2_avg_mr, block2_avg_sens, block2_avg_hyst, block2_avg_nom])

print("CSV generated successfully.")
