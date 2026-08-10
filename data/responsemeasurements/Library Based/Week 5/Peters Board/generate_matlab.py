import csv

csv_file = '/mnt/Data/yep/Kuliah/Tugas/Magang Programs/MagneticStationGUI/data/responsemeasurements/Library Based/Week 5/Peters Board/Sensor_Measurements_Analysis.csv'

block1_data = {'MR': [], 'Sens': [], 'Hys': [], 'Nom': []}
block2_data = {'MR': [], 'Sens': [], 'Hys': [], 'Nom': []}
pins = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L']

current_block = 0
with open(csv_file, 'r') as f:
    reader = csv.reader(f)
    for row in reader:
        if not row: continue
        if 'BLOCK 1' in row[0]:
            current_block = 1
            continue
        if 'BLOCK 2' in row[0]:
            current_block = 2
            continue
        
        if current_block == 1 and row[0] in pins:
            mr1 = row[1]; mr2 = row[2]
            sens1 = row[4]; sens2 = row[5]
            hys1 = row[7]; hys2 = row[8]
            nom1 = row[10]; nom2 = row[11]
            block1_data['MR'].append([float(mr1) if mr1 else float('nan'), float(mr2) if mr2 else float('nan')])
            block1_data['Sens'].append([float(sens1) if sens1 else float('nan'), float(sens2) if sens2 else float('nan')])
            block1_data['Hys'].append([float(hys1) if hys1 else float('nan'), float(hys2) if hys2 else float('nan')])
            block1_data['Nom'].append([float(nom1) if nom1 else float('nan'), float(nom2) if nom2 else float('nan')])
            
        if current_block == 2 and row[0] in pins:
            mr3 = row[1]
            sens3 = row[2]
            hys3 = row[3]
            nom3 = row[4]
            block2_data['MR'].append([float(mr3) if mr3 else float('nan')])
            block2_data['Sens'].append([float(sens3) if sens3 else float('nan')])
            block2_data['Hys'].append([float(hys3) if hys3 else float('nan')])
            block2_data['Nom'].append([float(nom3) if nom3 else float('nan')])

def format_matlab_array(data_list):
    num_boards = len(data_list[0])
    lines = []
    for board_idx in range(num_boards):
        row_str = ' '.join([str(p[board_idx]) if not p[board_idx] != p[board_idx] else 'NaN' for p in data_list])
        lines.append(f"[{row_str}]")
    return "[" + ";\n".join(lines) + "]"

matlab_script = f"""%% render_measurements.m
% Generates box plot style charts for Sensor Block 1 and Sensor Block 2
clear; clc; close all;

%% Data definition
pins = {{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'}};

% --- Block 1 Data (Rows: Boards 1&2, Columns: Pins A-L) ---
B1_Nom = {format_matlab_array(block1_data['Nom'])};
B1_Hys = {format_matlab_array(block1_data['Hys'])};
B1_Sens = {format_matlab_array(block1_data['Sens'])};
B1_MR = {format_matlab_array(block1_data['MR'])};

% --- Block 2 Data (Rows: Board 3, Columns: Pins A-L) ---
B2_Nom = {format_matlab_array(block2_data['Nom'])};
B2_Hys = {format_matlab_array(block2_data['Hys'])};
B2_Sens = {format_matlab_array(block2_data['Sens'])};
B2_MR = {format_matlab_array(block2_data['MR'])};

% Duplicate the row for Block 2 so boxplot draws a flat line for each pin instead of failing.
B2_Nom = [B2_Nom; B2_Nom];
B2_Hys = [B2_Hys; B2_Hys];
B2_Sens = [B2_Sens; B2_Sens];
B2_MR = [B2_MR; B2_MR];

%% Common Styling
color_b1 = [0.20 0.45 0.85]; % Blue for Block 1
color_b2 = [0.90 0.50 0.05]; % Orange for Block 2

%% Plotting Function
function createBoxPlot(data, blockName, paramName, yLabelText, pins, boxColor)
    fig = figure('Color', 'w', 'Position', [80 80 1000 600]);
    ax = axes(fig);
    hold(ax, 'on');
    
    bh = boxplot(ax, data, ...
        'Labels', pins, ...
        'Colors', boxColor, ...
        'Symbol', 'k+', ...
        'Widths', 0.55);
    
    % 2pt thick boxes requested
    set(bh, 'LineWidth', 2);
    set(findobj(ax, 'Tag', 'Median'), 'LineWidth', 3, 'Color', 'k');
    set(findobj(ax, 'Tag', 'Outliers'), 'MarkerSize', 8, 'LineWidth', 1.8);
    
    boxObjs = flipud(findobj(ax, 'Tag', 'Box'));
    for i = 1:numel(boxObjs)
        xData = get(boxObjs(i), 'XData');
        yData = get(boxObjs(i), 'YData');
        patch(ax, xData, yData, boxColor, ...
            'FaceAlpha', 0.55, 'EdgeColor', boxColor, 'LineWidth', 2);
    end
    uistack(findobj(ax, 'Tag', 'Box'), 'top');
    uistack(findobj(ax, 'Tag', 'Median'), 'top');
    hold(ax, 'off');
    
    xlabel(ax, 'Pins', 'FontSize', 20, 'FontWeight', 'bold');
    ylabel(ax, yLabelText, 'FontSize', 20, 'FontWeight', 'bold');
    title(ax, [blockName ' - ' paramName], 'FontSize', 22, 'FontWeight', 'bold');
    
    % Apply Axes Style (Size 20 bold font, no X grid, Y grid on)
    set(ax, 'FontSize', 20, 'FontWeight', 'bold', 'LineWidth', 2, ...
        'Box', 'on', 'TickDir', 'out', 'XGrid', 'off', 'YGrid', 'on');
    ax.GridAlpha = 0.3;
    ax.GridLineWidth = 1;
    ax.YAxis.Exponent = 0;
    ax.XAxis.FontWeight = 'bold';
    ax.YAxis.FontWeight = 'bold';
end

%% Generate Figures
createBoxPlot(B1_Nom, 'Sensor Block 1', 'Nominal Resistance', 'Nominal Resistance (\Omega)', pins, color_b1);
createBoxPlot(B2_Nom, 'Sensor Block 2', 'Nominal Resistance', 'Nominal Resistance (\Omega)', pins, color_b2);

createBoxPlot(B1_Hys, 'Sensor Block 1', 'Max Hysteresis Difference', 'Max Hysteresis (\Omega)', pins, color_b1);
createBoxPlot(B2_Hys, 'Sensor Block 2', 'Max Hysteresis Difference', 'Max Hysteresis (\Omega)', pins, color_b2);

createBoxPlot(B1_Sens, 'Sensor Block 1', 'Sensitivity', 'Sensitivity (\Omega/G)', pins, color_b1);
createBoxPlot(B2_Sens, 'Sensor Block 2', 'Sensitivity', 'Sensitivity (\Omega/G)', pins, color_b2);

createBoxPlot(B1_MR, 'Sensor Block 1', 'MR Ratio', 'MR Ratio (%)', pins, color_b1);
createBoxPlot(B2_MR, 'Sensor Block 2', 'MR Ratio', 'MR Ratio (%)', pins, color_b2);
"""

out_file = '/mnt/Data/yep/Kuliah/Tugas/Magang Programs/MagneticStationGUI/data/responsemeasurements/Library Based/Week 5/Peters Board/render_measurements.m'
with open(out_file, 'w') as f:
    f.write(matlab_script)

print(f"Successfully wrote {out_file}")
