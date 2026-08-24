%% correlate_field.m
%
% Reads onboard sensor measurement files (e.g. B1A.xlsx, B2A.xlsx, ...)
% located in the same directory as this script. Each measurement file
% must contain (at least) the first two columns:
%   Kepco_Current_A   Resistance_Ohms
%
% For each measurement file, looks for a calibration file of the SAME
% NAME inside a subfolder called "Calibration" (e.g. Calibration/B1A.xlsx).
% The calibration file must contain a column named:
%   Sensitivity_Ohms_per_G
%
% The correlated magnetic field is computed as:
%   R_nominal = Resistance at Kepco_Current_A = 0 (interpolated)
%   dR        = Resistance_Ohms - R_nominal
%   G         = dR / Sensitivity_Ohms_per_G
%
% For each processed measurement file, this script:
%   1) Plots Onboard Resistance (R) vs Correlated Field (G) and saves
%      it as a .fig file with the same base name as the input file.
%   2) Writes an output spreadsheet named CorrelatedField_<name>.xlsx
%      containing the original data plus the computed field.
%
% Measurement files with no matching calibration file are skipped.
% A summary of processed/skipped files is printed to the terminal.

clear; clc; close all;

%% ---- Configuration ----
scriptDir  = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
calibDir   = fullfile(scriptDir, 'Calibration');

figBgColor  = [0.9608, 0.9608, 0.9608];
axBgColor   = [1, 1, 1];
lineWidth   = 2;
fontSize    = 22;

%% ---- Discover onboard measurement files ----
allFiles = dir(fullfile(scriptDir, '*.xlsx'));

% Exclude files that are actually previous script outputs, and exclude
% any files that live inside the Calibration folder (dir with a
% non-recursive pattern on scriptDir already excludes subfolders, but
% guard anyway in case scriptDir == calibDir edge cases).
measurementFiles = {};
for k = 1:numel(allFiles)
    fname = allFiles(k).name;
    if startsWith(fname, 'CorrelatedField_')
        continue
    end
    measurementFiles{end+1} = fname; %#ok<AGROW>
end

processedFiles = {};
skippedFiles   = {};

fprintf('Found %d candidate measurement file(s) in %s\n\n', ...
    numel(measurementFiles), scriptDir);

%% ---- Process each measurement file ----
for k = 1:numel(measurementFiles)
    fname   = measurementFiles{k};
    [~, baseName, ~] = fileparts(fname);
    measPath  = fullfile(scriptDir, fname);
    calibPath = fullfile(calibDir, fname);

    if ~isfile(calibPath)
        fprintf('[SKIPPED] %s -> no matching calibration file in Calibration/\n', fname);
        skippedFiles{end+1} = fname; %#ok<AGROW>
        continue
    end

    try
        % ---- Read onboard measurement data (first two columns only) ----
        % NOTE: Range is pinned to A:B on purpose. Some files have stray
        % values sitting in far-right columns with blank headers (e.g. a
        % leftover cell in column F or G). That extends the sheet's used
        % range and confuses MATLAB's automatic header detection, which
        % can cause it to discard ALL real header names (including ones
        % we need) and fall back to generic Var1, Var2, ... names.
        % Restricting the range avoids that entirely.
        measTable = readtable(measPath, 'Range', 'A:B', 'VariableNamingRule', 'preserve');
        I = measTable.(measTable.Properties.VariableNames{1});
        R = measTable.(measTable.Properties.VariableNames{2});
        I = double(I);
        R = double(R);

        % ---- Read calibration sensitivity ----
        % Same reasoning as above: pin the range to A:E so a stray value
        % in F/G with a blank header can't break header auto-detection.
        calibTable = readtable(calibPath, 'Range', 'A:E', 'VariableNamingRule', 'preserve');
        if ~ismember('Sensitivity_Ohms_per_G', calibTable.Properties.VariableNames)
            fprintf('[SKIPPED] %s -> calibration file has no "Sensitivity_Ohms_per_G" column\n', fname);
            skippedFiles{end+1} = fname; %#ok<AGROW>
            continue
        end
        sensVals = double(calibTable.Sensitivity_Ohms_per_G);
        sensVals = sensVals(~isnan(sensVals));
        if isempty(sensVals)
            fprintf('[SKIPPED] %s -> "Sensitivity_Ohms_per_G" column is empty\n', fname);
            skippedFiles{end+1} = fname; %#ok<AGROW>
            continue
        end
        sensitivity = sensVals(1); % Ohms per Gauss (assumed constant per file)

        % ---- Compute nominal resistance at I = 0 (interpolated) ----
        [Isort, sortIdx] = sort(I);
        Rsort = R(sortIdx);
        if any(I == 0)
            R_nominal = mean(R(I == 0));
        else
            R_nominal = interp1(Isort, Rsort, 0, 'linear', 'extrap');
        end

        % ---- Correlate resistance change to magnetic field ----
        dR = R - R_nominal;
        G  = dR / sensitivity;

        % ---- Plot Onboard Resistance (R) vs Correlated Field (G) ----
        fig = figure('Color', figBgColor);
        ax = axes('Parent', fig);
        plot(ax, G, R, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
        set(ax, 'Color', axBgColor, 'FontSize', fontSize);
        xlabel(ax, 'Correlated Field (G)', 'FontSize', fontSize, 'FontWeight', 'bold');
        ylabel(ax, 'Onboard Resistance (\Omega)', 'FontSize', fontSize, 'FontWeight', 'bold');
        title(ax, strrep(baseName, '_', '\_'));

        figSavePath = fullfile(scriptDir, [baseName '.fig']);
        savefig(fig, figSavePath);
        close(fig);

        % ---- Write correlated field output spreadsheet ----
        outTable = table(I, R, dR, G, ...
            'VariableNames', {'Kepco_Current_A', 'Resistance_Ohms', ...
                               'Delta_Resistance_Ohms', 'Correlated_Field_G'});
        outPath = fullfile(scriptDir, ['CorrelatedField_' baseName '.xlsx']);
        writetable(outTable, outPath);

        fprintf('[PROCESSED] %s -> %s, %s (sensitivity = %.6g Ohms/G)\n', ...
            fname, [baseName '.fig'], ['CorrelatedField_' baseName '.xlsx'], sensitivity);
        processedFiles{end+1} = fname; %#ok<AGROW>

    catch ME
        fprintf('[SKIPPED] %s -> error while processing: %s\n', fname, ME.message);
        skippedFiles{end+1} = fname; %#ok<AGROW>
    end
end

%% ---- Summary ----
fprintf('\n===== Summary =====\n');
fprintf('Processed (%d):\n', numel(processedFiles));
for k = 1:numel(processedFiles)
    fprintf('  - %s\n', processedFiles{k});
end
fprintf('Skipped (%d):\n', numel(skippedFiles));
for k = 1:numel(skippedFiles)
    fprintf('  - %s\n', skippedFiles{k});
end