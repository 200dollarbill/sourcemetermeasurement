%% plot_max_hys_gap_boxplot.m
% Visualizes Max Hysteresis Gap and Sensitivity together to help judge
% which sensor block performs best overall.
%
% Produces 3 figures:
%   1) Scatter: Sensitivity vs. Max Hys Gap, colored by block
%      (shows the raw trade-off between gain and hysteresis error)
%   2) Boxplot: Hysteresis Field Error (G) = Max Hys Gap / Sensitivity,
%      grouped by block (a single, fair figure-of-merit per block --
%      lower is better)
%   3) Combined scatter: Sensitivity vs. Max Hys Gap, colored by block,
%      with marker size scaled to the Hysteresis Field Error (G) so both
%      axes and the derived metric are visible at once
%   4) Bar chart: Average Nominal Resistance per block, with error bars
%      (std dev)
%   5) Boxplot + scatter: Nominal Resistance variation per block
%
% Measurements from different boards within the same block type are
% combined/paired point-by-point (each row is one board/magnet sweep).
%
% Data source: ITRI_Sensor_Response_Measurements.xlsx, 'Revised' sheet.

clear; clc; close all;

%% --- User settings ---
filename  = 'ITRI_Sensor_Response_Measurements.xlsx';
sheetName = 'Revised';

%% --- Read paired Sensitivity (Ohm/G) and Max Hys Gap (Ohm) per block ---
% Each row within a block is one board/magnet measurement, and the two
% tables share the same row order, so row i in Sensitivity pairs with
% row i in Max Hys Gap for that block.
sens.block3 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'H3:H6');
sens.block4 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'I3:I6');
sens.block5 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'J3:J8');
sens.block6 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'K3:K8');

hys.block3 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'B36:B39');
hys.block4 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'F36:F39');
hys.block5 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'B43:B48');
hys.block6 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'F43:F48');

blockOrder = {'Block 3', 'Block 4', 'Block 5', 'Block 6'};
fields = {'block3', 'block4', 'block5', 'block6'};

% Drop any empty/NaN rows (keeping sensitivity/hysGap paired)
for i = 1:numel(fields)
    f = fields{i};
    valid = ~isnan(sens.(f)) & ~isnan(hys.(f));
    sens.(f) = sens.(f)(valid);
    hys.(f)  = hys.(f)(valid);
end

%% --- Derived metric: Hysteresis Field Error (G) = Max Hys Gap / Sensitivity ---
% Dividing out the sensitivity (Ohm/G) converts the raw resistance
% ambiguity (Ohm) into an equivalent magnetic-field ambiguity (Gauss),
% which is a fair way to compare blocks that have very different gain.
ratio = struct();
for i = 1:numel(fields)
    f = fields{i};
    ratio.(f) = hys.(f) ./ sens.(f);
end

%% --- Common styling ---
colors = [0.20 0.45 0.85;   % Block 3 - blue
          0.90 0.50 0.05;   % Block 4 - orange
          0.15 0.60 0.30;   % Block 5 - green
          0.80 0.15 0.50];  % Block 6 - magenta
markers = {'o', 's', 'd', '^'};

%% ================= FIGURE 1: Sensitivity vs. Max Hys Gap =================
fig1 = figure('Color', 'w', 'Position', [80 80 900 650]);
ax1 = axes(fig1);
hold(ax1, 'on');
h = gobjects(1, numel(fields));
for i = 1:numel(fields)
    f = fields{i};
    h(i) = scatter(ax1, sens.(f), hys.(f), 130, colors(i, :), markers{i}, ...
        'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
end
hold(ax1, 'off');
xlabel(ax1, 'Sensitivity (\Omega/G)', 'FontSize', 20, 'FontWeight', 'bold');
ylabel(ax1, 'Max Hysteresis Gap (\Omega)', 'FontSize', 20, 'FontWeight', 'bold');
title(ax1, 'Sensitivity vs. Max Hysteresis Gap', 'FontSize', 22, 'FontWeight', 'bold');
legend(ax1, h, blockOrder, 'Location', 'northwest', 'FontSize', 15, 'Box', 'off');
applyAxesStyle(ax1);
exportgraphics(fig1, 'fig1_sensitivity_vs_hysgap.png', 'Resolution', 300);
exportgraphics(fig1, 'fig1_sensitivity_vs_hysgap.pdf', 'ContentType', 'vector');

%% ============ FIGURE 2: Boxplot of Hysteresis Field Error (G) ============
allRatio = [ratio.block3; ratio.block4; ratio.block5; ratio.block6];
groupLabels = [ ...
    repmat({'Block 3'}, numel(ratio.block3), 1); ...
    repmat({'Block 4'}, numel(ratio.block4), 1); ...
    repmat({'Block 5'}, numel(ratio.block5), 1); ...
    repmat({'Block 6'}, numel(ratio.block6), 1)];

fig2 = figure('Color', 'w', 'Position', [80 80 900 650]);
ax2 = axes(fig2);
hold(ax2, 'on');

bh = boxplot(ax2, allRatio, groupLabels, ...
    'GroupOrder', blockOrder, ...
    'Colors', colors, ...
    'Symbol', 'k+', ...
    'Widths', 0.55);
set(bh, 'LineWidth', 2.5);
set(findobj(ax2, 'Tag', 'Median'), 'LineWidth', 3, 'Color', 'k');
set(findobj(ax2, 'Tag', 'Outliers'), 'MarkerSize', 8, 'LineWidth', 1.8);

boxObjs = flipud(findobj(ax2, 'Tag', 'Box'));
for i = 1:numel(boxObjs)
    xData = get(boxObjs(i), 'XData');
    yData = get(boxObjs(i), 'YData');
    patch(ax2, xData, yData, colors(i, :), ...
        'FaceAlpha', 0.55, 'EdgeColor', colors(i, :), 'LineWidth', 2.5);
end
uistack(findobj(ax2, 'Tag', 'Box'), 'top');
uistack(findobj(ax2, 'Tag', 'Median'), 'top');

groupNum = zeros(size(allRatio));
for i = 1:numel(blockOrder)
    groupNum(strcmp(groupLabels, blockOrder{i})) = i;
end
rng(1);
jitter = (rand(size(allRatio)) - 0.5) * 0.15;
scatter(ax2, groupNum + jitter, allRatio, 70, [0.1 0.1 0.1], ...
    'filled', 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'w', 'LineWidth', 0.75);
hold(ax2, 'off');

xlabel(ax2, 'Sensor Block', 'FontSize', 20, 'FontWeight', 'bold');
ylabel(ax2, 'Hysteresis Field Error (G)', 'FontSize', 20, 'FontWeight', 'bold');
title(ax2, 'Hysteresis Field Error by Sensor Block (Lower = Better)', ...
    'FontSize', 20, 'FontWeight', 'bold');
applyAxesStyle(ax2);
exportgraphics(fig2, 'fig2_hys_field_error_boxplot.png', 'Resolution', 300);
exportgraphics(fig2, 'fig2_hys_field_error_boxplot.pdf', 'ContentType', 'vector');

%% ===== FIGURE 3: Combined scatter, marker size = Hysteresis Field Error =====
fig3 = figure('Color', 'w', 'Position', [80 80 950 700]);
ax3 = axes(fig3);
hold(ax3, 'on');
h3 = gobjects(1, numel(fields));
for i = 1:numel(fields)
    f = fields{i};
    % Scale marker area to the field-error ratio so worse (larger error)
    % points draw bigger bubbles.
    sizes = 60 + 12 * ratio.(f);
    h3(i) = scatter(ax3, sens.(f), hys.(f), sizes, colors(i, :), markers{i}, ...
        'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'MarkerFaceAlpha', 0.75);
end
hold(ax3, 'off');
xlabel(ax3, 'Sensitivity (\Omega/G)', 'FontSize', 20, 'FontWeight', 'bold');
ylabel(ax3, 'Max Hysteresis Gap (\Omega)', 'FontSize', 20, 'FontWeight', 'bold');
title(ax3, {'Sensitivity vs. Max Hysteresis Gap', ...
    '(marker size \propto Hysteresis Field Error, G)'}, ...
    'FontSize', 20, 'FontWeight', 'bold');
legend(ax3, h3, blockOrder, 'Location', 'northwest', 'FontSize', 15, 'Box', 'off');
applyAxesStyle(ax3);
exportgraphics(fig3, 'fig3_combined_bubble.png', 'Resolution', 300);
exportgraphics(fig3, 'fig3_combined_bubble.pdf', 'ContentType', 'vector');

%% --- Read Nominal Resistance values per block (all boards combined) ---
nomRes.block3 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'H16:H19');
nomRes.block4 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'I16:I19');
nomRes.block5 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'J16:J21');
nomRes.block6 = readmatrix(filename, 'Sheet', sheetName, 'Range', 'K16:K21');
for i = 1:numel(fields)
    f = fields{i};
    nomRes.(f) = nomRes.(f)(~isnan(nomRes.(f)));
end

%% ============ FIGURE 4: Average Nominal Resistance (bar + error bars) ============
nomMean = zeros(1, numel(fields));
nomStd  = zeros(1, numel(fields));
for i = 1:numel(fields)
    f = fields{i};
    nomMean(i) = mean(nomRes.(f));
    nomStd(i)  = std(nomRes.(f));
end

fig4 = figure('Color', 'w', 'Position', [80 80 900 650]);
ax4 = axes(fig4);
hold(ax4, 'on');
for i = 1:numel(fields)
    barObj = bar(ax4, i, nomMean(i), 0.6, ...
        'FaceColor', colors(i, :), 'FaceAlpha', 0.75, ...
        'EdgeColor', colors(i, :), 'LineWidth', 2.5);
end
errorbar(ax4, 1:numel(fields), nomMean, nomStd, 'k', ...
    'LineStyle', 'none', 'LineWidth', 2.5, 'CapSize', 18);
hold(ax4, 'off');
set(ax4, 'XTick', 1:numel(fields), 'XTickLabel', blockOrder);
xlim(ax4, [0.5, numel(fields) + 0.5]);
xlabel(ax4, 'Sensor Block', 'FontSize', 20, 'FontWeight', 'bold');
ylabel(ax4, 'Average Nominal Resistance (\Omega)', 'FontSize', 20, 'FontWeight', 'bold');
title(ax4, 'Average Nominal Resistance by Sensor Block', ...
    'FontSize', 22, 'FontWeight', 'bold');
applyAxesStyle(ax4);
exportgraphics(fig4, 'fig4_avg_nominal_resistance_bar.png', 'Resolution', 300);
exportgraphics(fig4, 'fig4_avg_nominal_resistance_bar.pdf', 'ContentType', 'vector');

%% ======== FIGURE 5: Nominal Resistance variation (box + scatter) ========
allNomRes = [nomRes.block3; nomRes.block4; nomRes.block5; nomRes.block6];
nomGroupLabels = [ ...
    repmat({'Block 3'}, numel(nomRes.block3), 1); ...
    repmat({'Block 4'}, numel(nomRes.block4), 1); ...
    repmat({'Block 5'}, numel(nomRes.block5), 1); ...
    repmat({'Block 6'}, numel(nomRes.block6), 1)];

fig5 = figure('Color', 'w', 'Position', [80 80 900 650]);
ax5 = axes(fig5);
hold(ax5, 'on');

bh5 = boxplot(ax5, allNomRes, nomGroupLabels, ...
    'GroupOrder', blockOrder, ...
    'Colors', colors, ...
    'Symbol', 'k+', ...
    'Widths', 0.55);
set(bh5, 'LineWidth', 2.5);
set(findobj(ax5, 'Tag', 'Median'), 'LineWidth', 3, 'Color', 'k');
set(findobj(ax5, 'Tag', 'Outliers'), 'MarkerSize', 8, 'LineWidth', 1.8);

boxObjs5 = flipud(findobj(ax5, 'Tag', 'Box'));
for i = 1:numel(boxObjs5)
    xData = get(boxObjs5(i), 'XData');
    yData = get(boxObjs5(i), 'YData');
    patch(ax5, xData, yData, colors(i, :), ...
        'FaceAlpha', 0.55, 'EdgeColor', colors(i, :), 'LineWidth', 2.5);
end
uistack(findobj(ax5, 'Tag', 'Box'), 'top');
uistack(findobj(ax5, 'Tag', 'Median'), 'top');

nomGroupNum = zeros(size(allNomRes));
for i = 1:numel(blockOrder)
    nomGroupNum(strcmp(nomGroupLabels, blockOrder{i})) = i;
end
rng(1);
nomJitter = (rand(size(allNomRes)) - 0.5) * 0.15;
scatter(ax5, nomGroupNum + nomJitter, allNomRes, 70, [0.1 0.1 0.1], ...
    'filled', 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'w', 'LineWidth', 0.75);
hold(ax5, 'off');

xlabel(ax5, 'Sensor Block', 'FontSize', 20, 'FontWeight', 'bold');
ylabel(ax5, 'Nominal Resistance (\Omega)', 'FontSize', 20, 'FontWeight', 'bold');
title(ax5, 'Nominal Resistance Variation by Sensor Block', ...
    'FontSize', 20, 'FontWeight', 'bold');
applyAxesStyle(ax5);
exportgraphics(fig5, 'fig5_nominal_resistance_boxscatter.png', 'Resolution', 300);
exportgraphics(fig5, 'fig5_nominal_resistance_boxscatter.pdf', 'ContentType', 'vector');

%% --- Local helper: shared big-font / bold-border axes style ---
function applyAxesStyle(ax)
    set(ax, 'FontSize', 17, 'FontWeight', 'bold', 'LineWidth', 2, ...
        'Box', 'on', 'TickDir', 'out');
    grid(ax, 'on');
    ax.GridAlpha = 0.3;
    ax.GridLineWidth = 1;
    ax.YAxis.Exponent = 0;
    ax.XAxis.FontWeight = 'bold';
    ax.YAxis.FontWeight = 'bold';
end