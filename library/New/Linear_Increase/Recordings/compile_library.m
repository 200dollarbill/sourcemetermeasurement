clear; clc; close all;
files = dir('*.xlsx');
all_x = [];
all_y = [];

% specific sheet name
sheetName = 'StaticData'; 

for i = 1:length(files)
    filename = files(i).name;
        if startsWith(filename, '~$') || strcmp(filename, 'Compiled_LUT_Linear.xlsx') || strcmp(filename, 'Library.xlsx')
            continue;
        end
    try
        data = readmatrix(filename, 'Sheet', sheetName);        
        x_col = 1; 
        y_col = 2;
        
        if size(data, 2) < max(x_col, y_col)
            fprintf('Not enough columns in data.\n');
            continue;
        end
        
        x = data(:, x_col);
        y = data(:, y_col);
        valid_idx = ~isnan(x) & ~isnan(y);
        x = x(valid_idx);
        y = y(valid_idx);
        all_x = [all_x; x];
        all_y = [all_y; y];
        
        fprintf('%d data points.\n', length(x));
        
    catch ME
        fprintf('Failed: %s\n', ME.message);
    end
end

if isempty(all_x)
    error('No valid data points found! Please check the sheet name and column setup.');
end


fprintf('n %d', length(all_x));

% linear regression
p = polyfit(all_x, all_y, 1);
slope = p(1);
intercept = p(2);
fprintf('');
fprintf('b: %.6f\n', slope);
fprintf('a: %.6f\n', intercept);
fprintf('f(x) = (%.6f) * x + (%.6f)\n', slope, intercept);
x_min = -2.0;
x_max = 2.0;

step_size = 0.01; % 10 mA step size
x_lut = (x_min : step_size : x_max)';
y_lut = polyval(p, x_lut); % exact unrounded fitted Y values 
% make table
lut_table = table(x_lut, y_lut, 'VariableNames', {'Input_X', 'Fitted_Output_Y'});
params_table = table(slope, intercept, 'VariableNames', {'Slope', 'Intercept'});

% save file outputname
output_file = 'Library.xlsx';
writetable(lut_table, output_file, 'Sheet', 'LUT_Data');
writetable(params_table, output_file, 'Sheet', 'Regression_Parameters');
figure('Name', 'Linear Regression Fit', 'NumberTitle', 'off');
scatter(all_x, all_y, 10, 'b', 'filled', 'MarkerFaceAlpha', 0.5);
hold on;
plot(x_lut, y_lut, 'r-', 'LineWidth', 2.5);
xlabel('Power Source Input (A)');
ylabel('Gaussmeter Measured Field (G)');
title(sprintf('Linear Regression Function : Y = %.4fX + %.4f', slope, intercept));
legend('Raw Data Points', 'Linear Regression Line', 'Location', 'best');
grid on;
