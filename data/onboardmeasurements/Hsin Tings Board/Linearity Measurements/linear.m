%% rmse_from_bestfit.m
% Quantifies the Root Mean Square Error (RMSE) from Resistance vs. Magnetic Field data
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
%     - reports and plots the RMSE for that block in its own figure
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
% RMSE DEFINITION
%   A least-squares straight line (best-fit / reference line) is fit to
%   the combined Resistance-vs-Field data for the block. The RMSE is the 
%   standard deviation of the residuals (the differences between the actual 
%   data points and the reference line):
%
%       RMSE (Ohms) = sqrt(mean((Actual - BestFit).^2))

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
    'VariableNames', {'Directory', 'FSO_Ohms', 'RMSE_Ohms'});

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

    %% --- RMSE Calculation ---
    FSO = max(allR) - min(allR);
    deviation = allR - Rfit_at_data;
    
    % Calculate Root Mean Square Error
    rmse = sqrt(mean(deviation.^2));

    results = [results; {string(dirName), FSO, rmse}]; %#ok<AGROW>

    fprintf('--- %s ---\n', dirName);
    fprintf('Best-fit line: R = %.6f * B + %.4f\n', p(1), p(2));
    fprintf('FSO (Ohms)                 : %.2f\n', FSO);
    fprintf('RMSE (Ohms)                : %.4f\n', rmse);

    %% --- Plot: actual data vs. best-fit reference line (one figure per directory) ---
    % Updated the 'Color' property to [0.94 0.94 0.94]
    fig = figure('Color', [0.94, 0.94, 0.94], 'Position', [80 80 900 650]);
    ax = axes(fig);
    hold(ax, 'on');

    scatter(ax, allB, allR, 'filled', 'HandleVisibility', 'off');
    fitLine = plot(ax, Bline, Rline, 'r-', 'LineWidth', 2, 'DisplayName', 'Best-fit line');

    hold(ax, 'off');
    xlabel(ax, 'Magnetic Field (G)', 'FontSize', 20, 'FontWeight', 'bold');
    ylabel(ax, 'Resistance (Ohms)', 'FontSize', 20, 'FontWeight', 'bold');
    title(ax, sprintf('Sensor Response RMSE', blockLabel), ...
        'FontSize', 20, 'FontWeight', 'bold');
    legend(ax, fitLine, 'Location', 'best', 'FontSize', 12);
    set(ax, 'FontSize', 15, 'FontWeight', 'bold');
    grid(ax, 'on');

    % Annotate the RMSE result directly on the plot
    annotStr = sprintf('RMSE = %.4f Ohms', rmse);
    text(ax, 0.03, 0.95, annotStr, 'Units', 'normalized', ...
        'FontSize', 16, 'FontWeight', 'bold', 'VerticalAlignment', 'top', ...
        'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 6);

    %% --- Save figure, named after the child directory ---
    safeName = matlab.lang.makeValidName(dirName);
    savefig(fig, sprintf('%s_rmse.fig', safeName));
end

disp(results);