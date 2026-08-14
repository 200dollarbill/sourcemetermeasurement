% correlate_implied_field.m
% This script correlates the onboard measurements with the true sensitivity 
% derived from the response measurements. It calculates the Implied Magnetic 
% Field (Gauss) and finds the linear correlation (Gauss per Ampere) generated 
% by the onboard coil.

% Determine script directory reliably
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end

% Define base directories relative to this script's location
base_onboard = fullfile(script_dir, '..', '..', 'Peters_Board'); 
base_response = fullfile(script_dir, '..', '..', '..', 'responsemeasurements', 'LibraryBased', 'Week5', 'Peters_Board');

% Fallback checks if script is run from different working directories (e.g. repo root or Peters_Board folder)
if ~exist(base_onboard, 'dir')
    if exist(fullfile(pwd, 'data', 'onboardmeasurements', 'Peters_Board'), 'dir')
        base_onboard = fullfile(pwd, 'data', 'onboardmeasurements', 'Peters_Board');
        base_response = fullfile(pwd, 'data', 'responsemeasurements', 'LibraryBased', 'Week5', 'Peters_Board');
    elseif exist(fullfile(pwd, 'Peters_Board'), 'dir')
        base_onboard = fullfile(pwd, 'Peters_Board');
        base_response = fullfile(pwd, '..', '..', 'responsemeasurements', 'LibraryBased', 'Week5', 'Peters_Board');
    elseif exist(fullfile(pwd, '..', 'Peters_Board'), 'dir')
        base_onboard = fullfile(pwd, '..', 'Peters_Board');
        base_response = fullfile(pwd, '..', '..', '..', 'responsemeasurements', 'LibraryBased', 'Week5', 'Peters_Board');
    end
end

% Create directory to save the correlation plots
analysis_dir = fullfile(base_onboard, 'Analysis', 'ImpliedField');
if ~exist(analysis_dir, 'dir')
    mkdir(analysis_dir);
end

fprintf('======================================================\n');
fprintf('         ONBOARD VS RESPONSE CORRELATION (PETERS)\n');
fprintf('======================================================\n\n');

% Find all onboard Excel files in all subdirectories of Board*
files = dir(fullfile(base_onboard, 'Board*', '**', '*.xlsx'));

% Initialize results cell array for Excel summary
results_summary = {};

for i = 1:length(files)
    file_path = fullfile(files(i).folder, files(i).name);
    
    % Ignore temporary lock files and anything already inside Analysis
    if contains(file_path, '~$') || contains(file_path, 'Analysis')
        continue;
    end
    
    try
        % Extract folder parts from the absolute path dynamically
        parts = strsplit(file_path, filesep);
        filename = parts{end};
        
        board_idx = -1;
        for j = 1:length(parts)
            if startsWith(parts{j}, 'Board') && length(parts{j}) <= 6
                board_idx = j;
                break;
            end
        end
        
        if board_idx == -1
            continue;
        end
        
        board_folder = parts{board_idx};
        if board_idx == length(parts) - 1
            orientation = 'Default';
        else
            orientation = parts{board_idx + 1};
        end
        
        % Locate the exact same board and test point in the response measurements
        % For Peters Board, response measurements don't use the orientation folder
        response_file = fullfile(base_response, board_folder, filename);
        
        if ~isfile(response_file)
            fprintf('Skipping %s in %s/%s: No corresponding response measurement found.\n', filename, board_folder, orientation);
            continue;
        end
        
        % 1. Read Response Measurement for the true Sensitivity
        opts = detectImportOptions(response_file);
        resp_df = readtable(response_file, opts);
        
        % Extract Sensitivity (Ohms/G)
        if ismember('Sensitivity_Ohms_per_G', resp_df.Properties.VariableNames)
            sens = resp_df.Sensitivity_Ohms_per_G(1);
        else
            sens = resp_df{1, 5}; % fallback to 5th column
        end
        
        % 2. Read Onboard Measurement
        opts_onboard = detectImportOptions(file_path);
        onboard_df = readtable(file_path, opts_onboard);
        
        if ismember('Resistance_Ohms', onboard_df.Properties.VariableNames)
            R = onboard_df.Resistance_Ohms;
            I = onboard_df.Kepco_Current_A;
        else
            I = onboard_df{:, 1};
            R = onboard_df{:, 2};
        end
        
        % 3. Calculate Implied Gauss
        % We assume the lowest resistance point correlates to the ~0 Gauss field baseline
        implied_G = (R - min(R)) / sens;
        
        % 4. Correlate Implied Gauss with the Onboard Current
        max_I = max(abs(I));
        max_G = max(implied_G);
        
        % Calculate the linear correlation slope (Gauss per Ampere)
        p = polyfit(abs(I), implied_G, 1);
        slope = p(1);
        
        % Print the results nicely
        rel_path = fullfile(board_folder, orientation, filename);
        fprintf('File: %s\n', rel_path);
        fprintf('  -> True Sensitivity (from Response): %.4f Ohms/G\n', sens);
        fprintf('  -> Max Implied Field (Generated):    %.4f G\n', max_G);
        fprintf('  -> Max Coil Current:                 %.4f A\n', max_I);
        fprintf('  -> Generated Field Correlation:      %.4f G/A\n', slope);
        fprintf('------------------------------------------------------\n');
        
        % Add to summary
        results_summary(end+1, :) = {board_folder, orientation, filename, sens, max_G, max_I, slope};
        
        % 5. Save a plot of the Implied Field vs Current
        fig = figure('Visible', 'off'); % Do not spam screen
        set(fig, 'Units', 'normalized', 'Position', [0.2 0.2 0.4500 0.400]);
        
        % Split forward and backward sweep
        [~, max_idx] = max(I);
        if max_idx > 1 && max_idx < length(I)
            plot(I(1:max_idx), implied_G(1:max_idx), 'b-', 'LineWidth', 2.0, 'DisplayName', 'Forward Sweep');
            hold on;
            plot(I(max_idx:end), implied_G(max_idx:end), 'r-', 'LineWidth', 2.0, 'DisplayName', 'Backward Sweep');
            hold off;
        else
            plot(I, implied_G, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Sweep');
        end
        
        % Clean up the title for display
        clean_filename = strrep(filename, '.xlsx', '');
        title_str = sprintf('Implied Magnetic Field vs Onboard Current\n%s - %s (%s)', board_folder, clean_filename, orientation);
        title(title_str, 'Interpreter', 'none', 'FontSize', 20, 'FontWeight', 'bold');
        
        xlabel('Kepco Current (A)', 'FontSize', 20, 'FontWeight', 'bold');
        ylabel('Implied Magnetic Field (G)', 'FontSize', 20, 'FontWeight', 'bold');
        
        ax = gca;
        ax.LineWidth = 2.0;
        ax.Box = 'on';
        
        lgd = legend('Location', 'best');
        lgd.FontSize = 20;
        lgd.FontWeight = 'bold';
        grid on;
        
        plot_name = sprintf('%s_%s_%s.fig', board_folder, orientation, clean_filename);
        
        % Set figure visible right before saving so it opens visibly for the user
        set(fig, 'Visible', 'on');
        savefig(fig, fullfile(analysis_dir, plot_name));
        close(fig);
        
    catch ME
        fprintf('Error processing %s: %s\n', file_path, ME.message);
    end
end

% Save summary to Excel
if ~isempty(results_summary)
    T = cell2table(results_summary, 'VariableNames', {'Board', 'Orientation', 'File', 'Sensitivity_Ohms_per_G', 'Max_Implied_G', 'Max_Current_A', 'Correlation_G_per_A'});
    summary_path = fullfile(analysis_dir, 'Correlation_Summary.xlsx');
    writetable(T, summary_path);
    fprintf('Saved summary to %s\n', summary_path);
end
