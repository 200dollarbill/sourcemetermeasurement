%% plot_max_hys_gap_boxplot.m
% Box-and-whiskers plot of Max Hysteresis Gap, grouped by sensor block
% type. Measurements from different boards within the same block type
% are combined into a single group.
%
% Data source: ITRI_Sensor_Response_Measurements.xlsx, 'Revised' sheet,
% "Max Hys Gap (Ohms)" tables.

clear; clc; close all;

%% --- User settings ---
filename  = 'ITRI_Sensor_Response_Measurements.xlsx';
sheetName = 'Revised';

%% --- Read Max Hys Gap values for each block (all boards combined) ---
block3 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'B36:B39');
block4 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'F36:F39');
block5 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'B43:B48');
block6 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'F43:F48');

% Drop any empty/NaN entries
block3 = block3(~isnan(block3));
block4 = block4(~isnan(block4));
block5 = block5(~isnan(block5));
block6 = block6(~isnan(block6));

%% --- Combine into one vector plus grouping labels ---
allData = [block3; block4; block5; block6];
groupLabels = [ ...
    repmat({'Block 3'}, numel(block3), 1); ...
    repmat({'Block 4'}, numel(block4), 1); ...
    repmat({'Block 5'}, numel(block5), 1); ...
    repmat({'Block 6'}, numel(block6), 1)];

%% --- Plot styling ---
blockOrder = {'Block 3', 'Block 4', 'Block 5', 'Block 6'};
colors = [0.20 0.45 0.85;   % blue
          0.90 0.50 0.05;   % orange
          0.15 0.60 0.30;   % green
          0.80 0.15 0.50];  % magenta

fig = figure('Color', 'w', 'Position', [100 100 900 650]);
ax = axes(fig);
hold(ax, 'on');

bh = boxplot(ax, allData, groupLabels, ...
    'GroupOrder', blockOrder, ...
    'Colors', colors, ...
    'Symbol', 'k+', ...
    'Widths', 0.55);

% Bold, thick box/whisker/cap borders
set(bh, 'LineWidth', 2.5);
set(findobj(ax, 'Tag', 'Median'), 'LineWidth', 3, 'Color', 'k');
set(findobj(ax, 'Tag', 'Outliers'), 'MarkerSize', 8, 'LineWidth', 1.8);

% Fill each box with a strong, solid-ish color
boxObjs = findobj(ax, 'Tag', 'Box');
% boxObjs are ordered right-to-left, so flip to match blockOrder
boxObjs = flipud(boxObjs);
for i = 1:numel(boxObjs)
    xData = get(boxObjs(i), 'XData');
    yData = get(boxObjs(i), 'YData');
    patch(ax, xData, yData, colors(i, :), ...
        'FaceAlpha', 0.55, 'EdgeColor', colors(i, :), 'LineWidth', 2.5);
end
uistack(findobj(ax, 'Tag', 'Box'), 'top');
uistack(findobj(ax, 'Tag', 'Median'), 'top');

% Overlay raw data points with slight horizontal jitter
groupNum = zeros(size(allData));
for i = 1:numel(blockOrder)
    groupNum(strcmp(groupLabels, blockOrder{i})) = i;
end
rng(1); % reproducible jitter
jitter = (rand(size(allData)) - 0.5) * 0.15;
scatter(ax, groupNum + jitter, allData, 70, [0.1 0.1 0.1], ...
    'filled', 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'w', 'LineWidth', 0.75);

hold(ax, 'off');

% Labels, title, and general styling -- large, bold, print-safe
ylabel(ax, 'Max Hysteresis Gap (\Omega)', 'FontSize', 20, 'FontWeight', 'bold');
xlabel(ax, 'Sensor Block', 'FontSize', 20, 'FontWeight', 'bold');
title(ax, 'Max Hysteresis Gap by Sensor Block Type', ...
    'FontSize', 22, 'FontWeight', 'bold');
set(ax, 'FontSize', 17, 'FontWeight', 'bold', 'LineWidth', 2, ...
    'Box', 'on', 'TickDir', 'out');
grid(ax, 'on');
ax.GridAlpha = 0.3;
ax.GridLineWidth = 1;
ax.YAxis.Exponent = 0;
ax.XAxis.FontWeight = 'bold';
ax.YAxis.FontWeight = 'bold';

%% --- Save figure: high-res PNG for slides, vector PDF for papers ---
exportgraphics(fig, 'max_hys_gap_boxplot.png', 'Resolution', 300);
exportgraphics(fig, 'max_hys_gap_boxplot.pdf', 'ContentType', 'vector');