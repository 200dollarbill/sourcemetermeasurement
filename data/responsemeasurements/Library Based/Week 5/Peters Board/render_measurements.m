%% render_measurements.m
% Generates bar charts for Sensor Block 1 (Averaged) and Sensor Block 2
clear; clc; close all;

%% Data definition
pins = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'};
x = 1:length(pins);

% --- Block 1 Data (Average of Board 1 & 2) ---
B1_Nom = [72406.07 50600.22 60122.515 54798.035 46545.42999999999 52790.229999999996 43902.47 52804.185 70502.585 58716.04 45953.475 44895.17];
B1_Hys = [53.54000000000087 7.065000000002328 9.630000000001019 11.93999999999869 89.00499999999738 37.625 4.669999999998254 8.11000000000422 15.684999999997672 19.91500000000451 75.19999999999709 5.915000000004511];
B1_Sens = [65.44365641685083 17.863046785958655 65.53990471775147 48.0909847889375 67.88311874605475 12.999775548945905 16.96107626493452 30.323936345156774 81.73764522266666 67.1880053462713 65.1145211692371 6.5889598796388515];
B1_MR = [7.199547294176336 3.4805446611865882 10.342197879110747 9.060506646880174 15.957728764001466 2.2471221470761304 4.372796725649383 6.236001471574307 10.36424771986513 11.854232773337579 15.523822308145181 1.4094987856553503];

% --- Block 2 Data (Board 3) ---
B2_Nom = [69610.8 77140.23 69131.22 67675.02 51807.0 72576.59 63199.48 68933.51 70801.87 66508.31 53014.18 84445.83];
B2_Hys = [26.420000000012806 18.739999999990687 12.0 25.630000000004657 69.9800000000032 16.270000000004075 13.090000000003783 24.44999999999709 29.0 23.04000000000815 152.9300000000003 25.529999999998836];
B2_Sens = [73.57743789180142 50.316769174096926 54.19511506620597 75.34520643297736 85.2731823050187 20.506561165485355 25.14529287861363 37.95945709463887 59.550631194164545 72.57839507479575 95.35641614153549 79.03221943070159];
B2_MR = [11.491719284470578 6.951229527358984 8.412038188958183 12.135217198443083 18.399471195624756 2.956014362029668 4.186436105244475 5.831842842552776 9.04933762185258 11.884692193651414 20.29258127119952 10.117934767832022];

%% Common Styling
color_b1 = [0.20 0.45 0.85]; % Blue for Block 1
color_b2 = [0.90 0.50 0.05]; % Orange for Block 2

%% Plotting Function
function createBarChart(x, data, blockName, paramName, yLabelText, pins, barColor)
    fig = figure('Color', 'w', 'Position', [80 80 1000 600]);
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
