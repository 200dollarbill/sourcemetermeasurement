% compare_boards.m
% This script compares test points A, B, C, D across Boards 1 to 5.
% It plots the MR Ratio vs Magnetic Field for each test point and outputs
% the MR Ratio, Sensitivity, and Max Hysteresis Difference to the terminal.

test_points = {'A', 'B', 'C', 'D'};
boards = 1:5;

fprintf('======================================================\n');
fprintf('         TEST POINT COMPARISON ACROSS BOARDS          \n');
fprintf('======================================================\n\n');

for tp_idx = 1:length(test_points)
    tp = test_points{tp_idx};
    
    % Create a new figure for this test point
    figure('Name', sprintf('Test Point %s Comparison', tp), 'NumberTitle', 'off');
    hold on;
    
    fprintf('--- Test Point %s ---\n', tp);
    
    legend_entries = {};
    
    for b = boards
        filename = sprintf('Board%d/B%d%s.xlsx', b, b, tp);
        if isfile(filename)
            try
                % Read the Excel data
                T = readtable(filename);
                
                % Ensure required columns exist
                if ismember('Magnetic_Field_G', T.Properties.VariableNames)
                    H = T.Magnetic_Field_G;
                else
                    continue;
                end
                
                if ismember('Resistance_Ohms', T.Properties.VariableNames)
                    R = T.Resistance_Ohms;
                else
                    continue;
                end
                
                if ismember('Kepco_Current_A', T.Properties.VariableNames)
                    I = T.Kepco_Current_A;
                else
                    I = 1:length(R); % Fallback
                end
                
                % 1. Calculate MR Ratio
                R_min = min(R);
                R_max = max(R);
                MR_Ratio = (R_max - R_min) / R_min * 100;
                
                % Plot MR Ratio curve vs Magnetic Field
                MR_curve = (R - R_min) ./ R_min * 100;
                plot(H, MR_curve, 'LineWidth', 1.5);
                legend_entries{end+1} = sprintf('Board %d', b);
                
                % 2. Calculate Sensitivity (Ohms/G)
                H_min = min(H);
                H_max = max(H);
                Sensitivity = (R_max - R_min) / (H_max - H_min);
                
                % 3. Calculate Maximum Difference on Hysteresis
                [~, max_idx] = max(I);
                R_fwd = R(1:max_idx);
                
                % Backward sweep starts from max_idx to the end
                R_bwd_raw = R(max_idx:end);
                R_bwd = R_bwd_raw(end:-1:1); % Reverse to match forward direction
                
                % Compare up to the minimum length
                len = min(length(R_fwd), length(R_bwd));
                if len > 1
                    max_diff_R = max(abs(R_fwd(1:len) - R_bwd(1:len)));
                else
                    max_diff_R = 0; % No hysteresis loop
                end
                
                % Output results to terminal
                fprintf('Board %d (B%d%s): MR Ratio = %5.2f %%, Sensitivity = %6.2f Ohms/G, Max Hys Diff = %5.2f Ohms\n', ...
                    b, b, tp, MR_Ratio, Sensitivity, max_diff_R);
                    
            catch ME
                fprintf('Error processing %s: %s\n', filename, ME.message);
            end
        else
            % fprintf('File not found: %s\n', filename);
        end
    end
    
    if ~isempty(legend_entries)
        title(sprintf('MR Ratio vs Magnetic Field - Test Point %s', tp));
        xlabel('Magnetic Field (G)');
        ylabel('MR Ratio (%)');
        legend(legend_entries, 'Location', 'best');
        grid on;
    else
        close(gcf); % Close figure if no data was found
    end
    
    hold off;
    fprintf('\n');
end
fprintf('======================================================\n');
