%% redraw_sweep_direction.m
%
% Reads onboard sensor measurement files (e.g. B1A.xlsx, B2A.xlsx, ...)
% located in the same directory as this script. Each measurement file
% must contain (at least) the first two columns:
%   Kepco_Current_A   Resistance_Ohms
%
% For each measurement file, this script plots Resistance vs Current
% with NO markers, and colors the line by sweep direction:
%   - Forward sweep  (current increasing, negative -> positive) : BLUE
%   - Backward sweep (current decreasing, positive -> negative) : RED
%
% X-axis: Onboard Current (A)
% Y-axis: Measured Resistance (Ohms)
%
% Each plot is saved as a .fig file (same base name as the input file,
% with a _Sweep suffix so it doesn't collide with other scripts' output
% in this same folder).

clear; clc; close all;

%% ---- Configuration ----
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

figBgColor  = [0.9608, 0.9608, 0.9608];
axBgColor   = [1, 1, 1];
lineWidth   = 2;
fontSize    = 22;

forwardColor  = [0, 0, 1]; % blue
backwardColor = [1, 0, 0]; % red

%% ---- Discover onboard measurement files ----
allFiles = dir(fullfile(scriptDir, '*.xlsx'));

measurementFiles = {};
for k = 1:numel(allFiles)
    fname = allFiles(k).name;
    if startsWith(fname, '~$')
        continue
    end
    if startsWith(fname, 'CorrelatedField_') || startsWith(fname, 'MaxResistanceChange_')
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
    fname = measurementFiles{k};
    [~, baseName, ~] = fileparts(fname);
    measPath = fullfile(scriptDir, fname);

    try
        % ---- Read onboard measurement data (first two columns only) ----
        measTable = readtable(measPath, 'Range', 'A:B', 'VariableNamingRule', 'preserve');
        I = double(measTable.(measTable.Properties.VariableNames{1}));
        R = double(measTable.(measTable.Properties.VariableNames{2}));

        if numel(I) < 2
            fprintf('[SKIPPED] %s -> not enough data points\n', fname);
            skippedFiles{end+1} = fname; %#ok<AGROW>
            continue
        end

        % ---- Determine sweep direction at each step ----
        % direction(n) describes the segment from point n to point n+1:
        %   +1 = forward (current increasing)
        %   -1 = backward (current decreasing)
        %    0 = no change
        d = diff(I);
        direction = sign(d);

        % ---- Plot, coloring each contiguous run by its direction ----
        fig = figure('Color', figBgColor);
        ax = axes('Parent', fig);
        hold(ax, 'on');

        legendAdded = struct('forward', false, 'backward', false);

        segStart = 1;
        for n = 1:numel(direction)
            % Detect end of a contiguous same-direction run (or end of data)
            isLastStep = (n == numel(direction));
            directionChanges = ~isLastStep && (direction(n+1) ~= direction(n)) && (direction(n+1) ~= 0);

            if isLastStep || directionChanges
                segEnd = n + 1; % include the point at the end of this run
                segIdx = segStart:segEnd;

                if direction(n) > 0
                    color = forwardColor;
                    if ~legendAdded.forward
                        dispName = 'Forward Sweep';
                        legendAdded.forward = true;
                    else
                        dispName = '';
                    end
                elseif direction(n) < 0
                    color = backwardColor;
                    if ~legendAdded.backward
                        dispName = 'Backward Sweep';
                        legendAdded.backward = true;
                    else
                        dispName = '';
                    end
                else
                    % No change in current across this step; carry forward
                    % the previous segment's color by skipping a distinct
                    % plot call (rare edge case, e.g. repeated readings).
                    color = forwardColor;
                    dispName = '';
                end

                if isempty(dispName)
                    plot(ax, I(segIdx), R(segIdx), '-', 'Color', color, ...
                        'LineWidth', lineWidth, 'HandleVisibility', 'off');
                else
                    plot(ax, I(segIdx), R(segIdx), '-', 'Color', color, ...
                        'LineWidth', lineWidth, 'DisplayName', dispName);
                end

                segStart = n + 1;
            end
        end

        hold(ax, 'off');
        set(ax, 'Color', axBgColor, 'FontSize', fontSize);
        xlabel(ax, 'Onboard Current (A)', 'FontSize', fontSize, 'FontWeight', 'bold');
        ylabel(ax, 'Measured Resistance (Ohms)', 'FontSize', fontSize, 'FontWeight', 'bold');
        title(ax, strrep(baseName, '_', '\_'));
        legend(ax, 'Location', 'best');

        figSavePath = fullfile(scriptDir, [baseName '_Sweep.fig']);
        savefig(fig, figSavePath);
        close(fig);

        fprintf('[PROCESSED] %s -> %s\n', fname, [baseName '_Sweep.fig']);
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