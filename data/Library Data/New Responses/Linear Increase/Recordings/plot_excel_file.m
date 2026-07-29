% =========================================================================
% MATLAB Script: Plot Data from an Excel File
% Description: Reads an Excel file and plots column data automatically.
% =========================================================================

clear; clc; close all;

% Option 1: Interactively select an Excel file (or specify filename directly)
[fileName, filePath] = uigetfile({'*.xlsx;*.xls', 'Excel Files (*.xlsx, *.xls)'}, 'Select an Excel File');

if isequal(fileName, 0)
    disp('No file selected. Operation canceled.');
    return;
end

fullPath = fullfile(filePath, fileName);
fprintf('Loading file: %s\n', fullPath);

% Read Excel file as a table (preserves column headers)
opts = detectImportOptions(fullPath);
data = readtable(fullPath, opts);

% Display first few rows in Command Window
disp('Data Preview:');
head(data)

% Extract numeric variables for plotting
numericVarNames = data.Properties.VariableNames(varfun(@isnumeric, data, 'OutputFormat', 'uniform'));

if length(numericVarNames) < 2
    error('The Excel file needs at least 2 numeric columns to plot (X and Y).');
end

% Set X and Y data (Default: Column 1 = X, Column 2 = Y)
xData = data.(numericVarNames{1});
yData = data.(numericVarNames{2});

xLabelName = numericVarNames{1};
yLabelName = numericVarNames{2};

% Create Plot
figure('Name', sprintf('Plot of %s', fileName), 'Color', 'w');

% Plot first Y column or multiple Y columns against X
if length(numericVarNames) == 2
    plot(xData, yData, '-o', 'LineWidth', 1.5, 'MarkerSize', 5, 'Color', [0 0.4470 0.7410]);
    legend(yLabelName, 'Interpreter', 'none', 'Location', 'best');
    ylabel(strrep(yLabelName, '_', ' '), 'FontWeight', 'bold');
else
    hold on;
    colors = lines(length(numericVarNames) - 1);
    for i = 2:length(numericVarNames)
        yColName = numericVarNames{i};
        plot(xData, data.(yColName), '-o', 'LineWidth', 1.5, 'MarkerSize', 4, ...
             'DisplayName', strrep(yColName, '_', ' '), 'Color', colors(i-1, :));
    end
    legend('Location', 'best');
    ylabel('Values', 'FontWeight', 'bold');
    hold off;
end

% Formatting
xlabel(strrep(xLabelName, '_', ' '), 'FontWeight', 'bold');
title(sprintf('Data Plot from %s', fileName), 'Interpreter', 'none');
grid on;
box on;
