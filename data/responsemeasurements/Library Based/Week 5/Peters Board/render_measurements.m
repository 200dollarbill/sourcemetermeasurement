%% render_measurements.m
% Generates box plot style charts for Sensor Block 1 and Sensor Block 2
clear; clc; close all;

%% Data definition
pins = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'};

% --- Block 1 Data (Rows: Boards 1&2, Columns: Pins A-L) ---
B1_Nom = [[38450.84 40439.41 43453.8 44905.09 41802.77 38470.98 36670.73 43902.35 42710.15 47740.06 41658.43 35383.07];
[106361.3 60761.03 76791.23 64690.98 51288.09 67109.48 51134.21 61706.02 98295.02 69692.02 50248.52 54407.27]];
B1_Hys = [[5.279999999998836 5.540000000000873 7.560000000004948 9.700000000004366 71.66999999999825 9.94999999999709 0.0 6.630000000004657 4.669999999998254 21.540000000000873 53.56999999999971 3.2000000000043656];
[101.80000000000291 8.590000000003783 11.69999999999709 14.179999999993015 106.33999999999651 65.30000000000291 9.339999999996508 9.590000000003783 26.69999999999709 18.29000000000815 96.82999999999447 8.630000000004657]];
B1_Sens = [[5.647181165083381 9.02104485281461 18.050847589962718 28.07705976307444 52.29807802618812 3.8270457901679866 21.49492102980698 29.023638770722677 17.013887306305115 36.5103504343287 51.58928323396383 2.931282006370532];
[125.24013166861828 26.705048719102702 113.02896184554022 68.10490981480055 83.46815946592136 22.172505307723824 12.427231500062058 31.62423391959087 146.4614031390282 97.86566025821391 78.63975910451036 10.246637752907171]];
B1_MR = [[1.5262155891889706 2.3268915515687385 4.375639550997288 6.6597859130255666 13.710611524326138 1.0310560434243252 6.2078424545995725 7.048166837952084 4.195260571485152 8.201756812867323 13.588769983128406 0.8579781723222685];
[12.872878999163701 4.6341977708044375 16.308756207224206 11.461227380734783 18.204846003676792 3.463188250727936 2.537750996699195 5.423836105196529 16.53323486824511 15.506708733807834 17.458874633161955 1.961019398988432]];

% --- Block 2 Data (Rows: Board 3, Columns: Pins A-L) ---
B2_Nom = [[69610.8 77140.23 69131.22 67675.02 51807.0 72576.59 63199.48 68933.51 70801.87 66508.31 53014.18 84445.83]];
B2_Hys = [[26.420000000012806 18.739999999990687 12.0 25.630000000004657 69.9800000000032 16.270000000004075 13.090000000003783 24.44999999999709 29.0 23.04000000000815 152.9300000000003 25.529999999998836]];
B2_Sens = [[73.57743789180142 50.316769174096926 54.19511506620597 75.34520643297736 85.2731823050187 20.506561165485355 25.14529287861363 37.95945709463887 59.550631194164545 72.57839507479575 95.35641614153549 79.03221943070159]];
B2_MR = [[11.491719284470578 6.951229527358984 8.412038188958183 12.135217198443083 18.399471195624756 2.956014362029668 4.186436105244475 5.831842842552776 9.04933762185258 11.884692193651414 20.29258127119952 10.117934767832022]];

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
