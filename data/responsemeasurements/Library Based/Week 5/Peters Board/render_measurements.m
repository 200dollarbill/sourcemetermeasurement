%% render_measurements.m
% Generates bar charts for Sensor Block 1 (Averaged) and Sensor Block 2
clear; clc; close all;

%% Data definition
pins = {'A', 'B', 'C', 'D', 'E', 'F'};
x = 1:length(pins);

% --- Block 1 Data (Average of Board 1 & 2, and Average of Pins A&G, etc) ---
B1_Nom = [58154.270000000004 51702.2025 65312.55 56757.0375 46249.4525 48842.7];
B1_Hys = [29.104999999999563 7.587500000003274 12.657499999999345 15.9275000000016 82.10249999999724 21.770000000002256];
B1_Sens = [41.202366340892674 24.093491565557713 73.63877497020907 57.6394950676044 66.4988199576459 9.794367714292378];
B1_MR = [5.78617200991286 4.8582730663804465 10.35322279948794 10.457369710108877 15.740775536073322 1.8283104663657403];

% --- Block 2 Data (Board 3, Average of Pins A&G, etc) ---
B2_Nom = [66405.14 73036.87 69966.545 67091.66500000001 52410.59 78511.20999999999];
B2_Hys = [19.755000000008295 21.594999999993888 20.5 24.335000000006403 111.45500000000175 20.900000000001455];
B2_Sens = [49.36136538520753 44.1381131343679 56.872873130185255 73.96180075388656 90.31479922327709 49.76939029809347];
B2_MR = [7.839077694857527 6.39153618495588 8.730687905405382 12.009954696047249 19.34602623341214 6.536974564930845];

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
