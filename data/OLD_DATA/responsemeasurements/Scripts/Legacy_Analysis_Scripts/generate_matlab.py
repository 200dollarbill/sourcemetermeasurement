import csv

csv_file = '/mnt/Data/yep/Kuliah/Tugas/Magang Programs/MagneticStationGUI/data/responsemeasurements/Library Based/Week 5/Peters Board/Sensor_Measurements_Analysis.csv'

block1_data = {'MR': [], 'Sens': [], 'Hys': [], 'Nom': []}
block2_data = {'MR': [], 'Sens': [], 'Hys': [], 'Nom': []}
pins = ['A', 'B', 'C', 'D', 'E', 'F']

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
            mr_avg = row[3]
            sens_avg = row[6]
            hys_avg = row[9]
            nom_avg = row[12]
            
            block1_data['MR'].append(float(mr_avg) if mr_avg else float('nan'))
            block1_data['Sens'].append(float(sens_avg) if sens_avg else float('nan'))
            block1_data['Hys'].append(float(hys_avg) if hys_avg else float('nan'))
            block1_data['Nom'].append(float(nom_avg) if nom_avg else float('nan'))
            
        if current_block == 2 and row[0] in pins:
            mr3 = row[1]
            sens3 = row[2]
            hys3 = row[3]
            nom3 = row[4]
            block2_data['MR'].append(float(mr3) if mr3 else float('nan'))
            block2_data['Sens'].append(float(sens3) if sens3 else float('nan'))
            block2_data['Hys'].append(float(hys3) if hys3 else float('nan'))
            block2_data['Nom'].append(float(nom3) if nom3 else float('nan'))

def format_matlab_array(data_list):
    row_str = ' '.join([str(v) if not v != v else 'NaN' for v in data_list])
    return f"[{row_str}]"

matlab_script = f"""%% render_measurements.m
% Generates bar charts for Sensor Block 1 (Averaged) and Sensor Block 2
clear; clc; close all;

%% Data definition
pins = {{'A', 'B', 'C', 'D', 'E', 'F'}};
x = 1:length(pins);

% --- Block 1 Data (Average of Board 1 & 2, and Average of Pins A&G, etc) ---
B1_Nom = {format_matlab_array(block1_data['Nom'])};
B1_Hys = {format_matlab_array(block1_data['Hys'])};
B1_Sens = {format_matlab_array(block1_data['Sens'])};
B1_MR = {format_matlab_array(block1_data['MR'])};

% --- Block 2 Data (Board 3, Average of Pins A&G, etc) ---
B2_Nom = {format_matlab_array(block2_data['Nom'])};
B2_Hys = {format_matlab_array(block2_data['Hys'])};
B2_Sens = {format_matlab_array(block2_data['Sens'])};
B2_MR = {format_matlab_array(block2_data['MR'])};

%% Common Styling
color_b1 = [0.20 0.45 0.85]; % Blue for Block 1
color_b2 = [0.90 0.50 0.05]; % Orange for Block 2

%% Plotting Function
function createBarChart(x, data, blockName, paramName, yLabelText, pins, barColor)
    fig = figure('Color', [0.96, 0.96, 0.96], 'Position', [80 80 1000 600]);
    ax = axes(fig);
    hold(ax, 'on');
    
    % Draw bar chart with translucent faces and 2pt thick edges
    barObj = bar(ax, x, data, 0.6, ...
        'FaceColor', barColor, 'FaceAlpha', 0.65, ...
        'EdgeColor', barColor, 'LineWidth', 2);
    
    hold(ax, 'off');
    
    set(ax, 'XTick', x, 'XTickLabel', pins);
    xlim(ax, [0.4, length(pins) + 0.6]);
    
    xlabel(ax, 'Pins', 'FontSize', 20, 'FontWeight', 'bold');
    ylabel(ax, yLabelText, 'FontSize', 20, 'FontWeight', 'bold');
    title(ax, [blockName ' - ' paramName], 'FontSize', 22, 'FontWeight', 'bold');
    
    % Apply Axes Style (Size 20 bold font, no X grid, Y grid on, 2pt thick box)
    set(ax, 'FontSize', 20, 'FontWeight', 'bold', 'LineWidth', 2, ...
        'Box', 'on', 'TickDir', 'out', 'XGrid', 'off', 'YGrid', 'on');
    ax.GridAlpha = 0.3;
    ax.GridLineWidth = 1;
    ax.YAxis.Exponent = 0;
    ax.XAxis.FontWeight = 'bold';
    ax.YAxis.FontWeight = 'bold';
    
    % Save figure
    cleanName = strrep([blockName '_' paramName], ' ', '_');
    savefig(fig, [cleanName '.fig']);
end

%% Generate Figures
createBarChart(x, B1_Nom, 'Sensor Block 1', 'Nominal Resistance', 'Nominal Resistance (\Omega)', pins, color_b1);
createBarChart(x, B2_Nom, 'Sensor Block 2', 'Nominal Resistance', 'Nominal Resistance (\Omega)', pins, color_b2);

createBarChart(x, B1_Hys, 'Sensor Block 1', 'Max Hysteresis Difference', 'Max Hysteresis (\Omega)', pins, color_b1);
createBarChart(x, B2_Hys, 'Sensor Block 2', 'Max Hysteresis Difference', 'Max Hysteresis (\Omega)', pins, color_b2);

createBarChart(x, B1_Sens, 'Sensor Block 1', 'Sensitivity', 'Sensitivity (\Omega/G)', pins, color_b1);
createBarChart(x, B2_Sens, 'Sensor Block 2', 'Sensitivity', 'Sensitivity (\Omega/G)', pins, color_b2);

createBarChart(x, B1_MR, 'Sensor Block 1', 'MR Ratio', 'MR Ratio (%)', pins, color_b1);
createBarChart(x, B2_MR, 'Sensor Block 2', 'MR Ratio', 'MR Ratio (%)', pins, color_b2);
"""

out_file = '/mnt/Data/yep/Kuliah/Tugas/Magang Programs/MagneticStationGUI/data/responsemeasurements/Library Based/Week 5/Peters Board/render_measurements.m'
with open(out_file, 'w') as f:
    f.write(matlab_script)

print(f"Successfully overwrote {out_file} with updated pins A-F.")
