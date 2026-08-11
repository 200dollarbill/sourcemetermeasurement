import zipfile
import xml.etree.ElementTree as ET
import sys

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
            pass # No shared strings
            
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
                    
                    # Ensure alignment based on cell reference (e.g., "A1", "B1")
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

filename = sys.argv[1]
data = read_xlsx(filename)
for row in data[:20]:
    print(row)
