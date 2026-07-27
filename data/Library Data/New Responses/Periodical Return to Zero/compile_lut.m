% compile_lut.m
% This script reads all .xlsx files in the current folder,
% extracts data from the "StaticData" sheet,
% compiles them together, performs a linear regression,
% and saves a single Look-Up Table (LUT) to an Excel file.

% Clear workspace and command window
clear; clc; close all;

% Find all Excel files in the current directory
files = dir('*.xlsx');

% Variables to hold all aggregated data
all_x = [];
all_y = [];

% Specify the sheet name to read from
sheetName = 'StaticData'; % change if the exact capitalization is different

disp(['Starting to process files in ', pwd]);

for i = 1:length(files)
    filename = files(i).name;
    
    % Skip temporary open files (~$) and our output file
    if startsWith(filename, '~$') || strcmp(filename, 'Compiled_LUT_Linear.xlsx')
        continue;
    end
    
    fprintf('Processing %s... ', filename);
    
    try
        % Read the numeric data from the sheet.
        % readmatrix automatically handles headers by returning NaN for text,
        % or skipping text if it's the first row.
        data = readmatrix(filename, 'Sheet', sheetName);
        
        % Check if data is empty
        if isempty(data)
            fprintf('Sheet "%s" is empty or not found.\n', sheetName);
            continue;
        end
        
        % ASSUMPTION: Column 1 is X (Input), Column 2 is Y (Sensor Output)
        % If your data is in different columns, change the indices below:
        x_col = 1; 
        y_col = 2;
        
        if size(data, 2) < max(x_col, y_col)
            fprintf('Not enough columns in data.\n');
            continue;
        end
        
        x = data(:, x_col);
        y = data(:, y_col);
        
        % Clean data (remove rows with NaN values if there were headers)
        valid_idx = ~isnan(x) & ~isnan(y);
        x = x(valid_idx);
        y = y(valid_idx);
        
        % Append to aggregate
        all_x = [all_x; x];
        all_y = [all_y; y];
        
        fprintf('Added %d data points.\n', length(x));
        
    catch ME
        fprintf('Failed: %s\n', ME.message);
    end
end

if isempty(all_x)
    error('No valid data points found! Please check the sheet name and column setup.');
end

disp('--- Compilation Complete ---');
fprintf('Total data points collected: %d\n', length(all_x));

% --- PERFORM LINEAR REGRESSION ---
% polyfit(x, y, 1) fits a 1st degree polynomial (a line): y = mx + c
p = polyfit(all_x, all_y, 1);
slope = p(1);
intercept = p(2);

fprintf('\nLinear Regression Result:\n');
fprintf('Slope (m): %.6f\n', slope);
fprintf('Intercept (c): %.6f\n', intercept);
fprintf('Equation: Y = (%.6f) * X + (%.6f)\n', slope, intercept);

% --- GENERATE LOOK-UP TABLE (LUT) ---
% Find the minimum and maximum X values from all the data
x_min = min(all_x);
x_max = max(all_x);

% Define how many points you want in your LUT (e.g., 1000 steps)
num_steps = 1000;
x_lut = linspace(x_min, x_max, num_steps)';
y_lut = polyval(p, x_lut); % Calculate theoretical Y for every LUT X step

% Prepare data to write to Excel
lut_table = table(x_lut, y_lut, 'VariableNames', {'Input_X', 'Fitted_Output_Y'});
params_table = table(slope, intercept, 'VariableNames', {'Slope', 'Intercept'});

% Write to output Excel file
output_file = 'Compiled_LUT_Linear.xlsx';
writetable(lut_table, output_file, 'Sheet', 'LUT_Data');
writetable(params_table, output_file, 'Sheet', 'Regression_Parameters');

fprintf('\nSuccess! Saved Look-Up Table and Parameters to: %s\n', output_file);

% --- PLOT RESULT FOR VISUAL VERIFICATION ---
figure('Name', 'Linear Regression Fit', 'NumberTitle', 'off');
% Scatter plot the raw data (transparent dots so dense areas show up darker)
scatter(all_x, all_y, 10, 'b', 'filled', 'MarkerFaceAlpha', 0.05);
hold on;
% Plot the regression line on top
plot(x_lut, y_lut, 'r-', 'LineWidth', 2.5);
xlabel('Sensor Input');
ylabel('Sensor Output');
title(sprintf('Aggregated Data Fit: Y = %.4fX + %.4f', slope, intercept));
legend('Raw Data Points', 'Linear Regression Line', 'Location', 'best');
grid on;
