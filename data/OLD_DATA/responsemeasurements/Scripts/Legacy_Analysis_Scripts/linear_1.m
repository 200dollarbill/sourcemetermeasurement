%% nonlinearity_from_bestfit.m
% Quantifies nonlinearity (%FSO) from Resistance vs. Magnetic Field data
% for every sensor block found in the child directories of this script's
% folder, using a best-fit (linear regression) reference line, and
% visualizes the best-fit line against the actual data for each block.
%
% USAGE
%   Place this script in the parent directory. Each child directory
%   should contain the .xlsx files belonging to ONE sensor block (e.g.
%   all the board/sweep files for Block 5). The script scans every child
%   directory, and for each one:
%     - scans every .xlsx inside it
%     - combines their data into a single Resistance-vs-Field dataset
%     - fits one best-fit line to the combined set
%     - reports and plots the nonlinearity for that block in its own
%       figure
%
%   parentDir/
%     Block3/  *.xlsx
%     Block4/  *.xlsx
%     Block5/  *.xlsx
%     Block6/  *.xlsx
%
% DATA FORMAT (per file, 'Sheet1')
%   Columns are read BY POSITION (not by header name, since header text
%   can vary slightly file to file):
%     Column 1: Kepco_Current_A
%     Column 2: Resistance_Ohms      <-- used (y)
%     Column 3: Magnetic_Field_G     <-- used (x)
%     Column 4: MR_Ratio_Percent
%     Column 5: Sensitivity_Ohms_per_G
%
% NONLINEARITY DEFINITION
%   A least-squares straight line (best-fit / reference line) is fit to
%   the combined Resistance-vs-Field data for the block. The nonlinearity
%   is the largest deviation of any actual data point from that
%   reference line, expressed as a percentage of the sensor's Full Scale
%   Output (FSO):
%
%       FSO (Ohms)            = max(Resistance) - min(Resistance)
%       Nonlinearity (%FSO)   = max(|Actual - BestFit|) / FSO * 100

clear; clc; close all;

%% --- User settings ---
parentDir  = fileparts(mfilename('fullpath'));  % folder this script lives in
blockLabel = 'Sensor Block';                     % used in the plot title only
sheetName  = 'Sheet1';

%% --- Find child directories, each one treated as a sensor block ---
items = dir(parentDir);
childDirs = items([items.isdir] & ~startsWith({items.name}, '.'));

if isempty(childDirs)
    error('No child directories found in %s', parentDir);
end

results = table('Size', [0 3], 'VariableTypes', {'string', 'double', 'double'}, ...
    'VariableNames', {'Directory', 'FSO_Ohms', 'Nonlinearity_pctFSO'});

for d = 1:numel(childDirs)
    dirName = childDirs(d).name;
    dataFolder = fullfile(parentDir, dirName);

    files = dir(fullfile(dataFolder, '*.xlsx'));
    if isempty(files)
        continue;   % skip child directories with no .xlsx files
    end

    %% --- Gather and combine data from every .xlsx in this directory ---
    allR = [];      % Resistance (Ohms)
    allB = [];      % Magnetic Field (G)

    for k = 1:numel(files)
        fpath = fullfile(files(k).folder, files(k).name);
        T = readtable(fpath, 'Sheet', sheetName);

        R  = T{:, 2};   % Resistance_Ohms (2nd column)
        Bf = T{:, 3};   % Magnetic_Field_G (3rd column)

        valid = ~isnan(R) & ~isnan(Bf);
        allR = [allR; R(valid)]; %#ok<AGROW>
        allB = [allB; Bf(valid)]; %#ok<AGROW>
    end

    if isempty(allR)
        continue;
    end

    fprintf('Loaded %d points from %d file(s) in %s\n', numel(allR), numel(files), dirName);

    %% --- Best-fit reference line (least-squares linear regression) ---
    p = polyfit(allB, allR, 1);            % R = p(1)*B + p(2)
    Bline = linspace(min(allB), max(allB), 200)';
    Rline = polyval(p, Bline);
    Rfit_at_data = polyval(p, allB);

    %% --- Nonlinearity, as %FSO ---
    FSO = max(allR) - min(allR);
    deviation = allR - Rfit_at_data;
    maxDeviation = max(abs(deviation));
    nonlinearity_pctFSO = maxDeviation / FSO * 100;

    results = [results; {string(dirName), FSO, nonlinearity_pctFSO}]; %#ok<AGROW>

    fprintf('--- %s ---\n', dirName);
    fprintf('Best-fit line: R = %.6f * B + %.4f\n', p(1), p(2));
    fprintf('FSO (Ohms)                 : %.2f\n', FSO);
    fprintf('Max deviation from fit (Ohms): %.4f\n', maxDeviation);
    fprintf('Nonlinearity (%%FSO)         : %.3f %%\n', nonlinearity_pctFSO);

    %% --- Plot: actual data vs. best-fit reference line (one figure per directory) ---
    fig = figure('Color', 'w', 'Position', [80 80 900 650]);
    ax = axes(fig);
    hold(ax, 'on');

    scatter(ax, allB, allR, 'filled', 'HandleVisibility', 'off');
    fitLine = plot(ax, Bline, Rline, 'r-', 'LineWidth', 2, 'DisplayName', 'Best-fit line');

    hold(ax, 'off');
    xlabel(ax, 'Magnetic Field (G)', 'FontSize', 20, 'FontWeight', 'bold');
    ylabel(ax, 'Resistance (\Omega)', 'FontSize', 20, 'FontWeight', 'bold');
    title(ax, sprintf('%s: Resistance vs. Field, Best-Fit Reference', blockLabel), ...
        'FontSize', 20, 'FontWeight', 'bold');
    legend(ax, fitLine, 'Location', 'best', 'FontSize', 12);
    set(ax, 'FontSize', 15, 'FontWeight', 'bold');
    grid(ax, 'on');

    % Annotate the nonlinearity result directly on the plot
    annotStr = sprintf('Nonlinearity = %.3f %%FSO', nonlinearity_pctFSO);
    text(ax, 0.03, 0.95, annotStr, 'Units', 'normalized', ...
        'FontSize', 16, 'FontWeight', 'bold', 'VerticalAlignment', 'top', ...
        'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 6);

    %% --- Save figure, named after the child directory ---
    safeName = matlab.lang.makeValidName(dirName);
    exportgraphics(fig, sprintf('%s_nonlinearity.png', safeName), 'Resolution', 300);
    exportgraphics(fig, sprintf('%s_nonlinearity.pdf', safeName), 'ContentType', 'vector');
end

disp(results);