% ====================================================
% Magnetic Field Measurement & Control Assignment
% ====================================================
% clear; clc; close all;
instrreset; 

%% 1. User Parameters
start_I = -1.0;             % Starting current (A) 
end_I = 1.0;              % Ending current (A)
step_size = 0.01;          % Current step size (A, positive value)
settle_time = 0.12;         % Settling time per step (s)

% Real-time plot setting
enable_realtime = true;    % Enable real-time dynamic plotting (true/false)

%% 2. Hardware Initialization
kepco_addr = 6;
gm_addr = 18;

disp('Initializing hardware connection...');
try
    delete(instrfind); 
    kepco = gpib('adlink', 0, kepco_addr);
    gm = gpib('adlink', 0, gm_addr);
    
    fopen(kepco);
    fopen(gm);
    
    % Gaussmeter setup
    fprintf(gm, 'RANGE 2');  
    fprintf(gm, 'RDGMODE 1,1,1,1,1'); 
    
    % Power Amplifier setup
    fprintf(kepco, 'FUNC:MODE CURR'); 
    fprintf(kepco, 'VOLT 20.0'); 
    fprintf(kepco, 'CURR 0.0'); 
    fprintf(kepco, 'OUTP ON');
    disp('Hardware connected successfully.');
catch ME
    error(['Connection failed: ', ME.message]);
end

%% 3. Pre-Measurement Setup
% Auto-correct step direction to allow scanning from positive to negative
actual_step = sign(end_I - start_I) * abs(step_size);
if actual_step == 0
    I_steps = start_I;
else
    I_steps = start_I : actual_step : end_I;
end
num_steps = length(I_steps);

% Pre-allocate arrays
time_data = zeros(1, num_steps);
B_data = zeros(1, num_steps);

disp('Moving to starting current and stabilizing...');
fprintf(kepco, sprintf('CURR %.3f', start_I));
pause(1.5); % Physical waiting time, ignored in the final time vector

% Set up real-time plot
if enable_realtime
    fig_rt = figure('Name', 'Real-time H-I Sweep', 'Color', 'w');
    ax_rt = axes('Parent', fig_rt);
    h_rt = plot(ax_rt, nan, nan, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
    grid(ax_rt, 'on');
    title(ax_rt, 'Real-time H-I Curve', 'FontWeight', 'bold');
    xlabel(ax_rt, 'Input Current (A)');
    ylabel(ax_rt, 'Magnetic Field (Gauss)');
    
    margin_I = abs(end_I - start_I) * 0.1;
    if margin_I == 0; margin_I = 0.1; end
    xlim(ax_rt, [min(start_I, end_I) - margin_I, max(start_I, end_I) + margin_I]);
end

%% 4. Measurement & Data Logging
disp('Measurement started.');
startTime = tic; 

for i = 1:num_steps
    fprintf(kepco, sprintf('CURR %.3f', I_steps(i)));
    pause(settle_time); 
    
    time_data(i) = toc(startTime);
    
    fprintf(gm, 'RDGFIELD?'); 
    B_data(i) = str2double(fscanf(gm));
    
    if enable_realtime
        set(h_rt, 'XData', I_steps(1:i), 'YData', B_data(1:i));
        drawnow; 
    end
end

% Shift time vector so the first point is exactly 0.0 seconds
time_data = time_data - time_data(1);

% Safe Shutdown
fprintf(kepco, 'CURR 0.0'); 
pause(0.2); 
fprintf(kepco, 'OUTP OFF');
fclose(kepco); 
fclose(gm);
disp('Measurement complete. Hardware closed.');

%% 5. Data Logging (Auto-increment filename)
base_filename = 'Magnetic_Field_Data';
file_idx = 0;

while true
    if file_idx == 0
        csv_filename = sprintf('%s.csv', base_filename);
        fig_filename = sprintf('%s.fig', base_filename);
    else
        csv_filename = sprintf('%s(%d).csv', base_filename, file_idx);
        fig_filename = sprintf('%s(%d).fig', base_filename, file_idx);
    end
    
    if ~isfile(csv_filename) && ~isfile(fig_filename)
        break; 
    end
    file_idx = file_idx + 1;
end

dataTable = table(time_data', I_steps', B_data', ...
    'VariableNames', {'Timestamp_s', 'InputCurrent_A', 'MagneticField_G'});
writetable(dataTable, csv_filename);
disp(['Data saved to: ', csv_filename]);

%% 6. Data Visualization
fig_final = figure('Name', 'Final Measurement Results', 'Color', 'w', 'Position', [100, 100, 800, 900]);

t_margin = max(time_data) * 0.05;
if t_margin == 0; t_margin = 1; end
I_margin = (max(I_steps) - min(I_steps)) * 0.1;
if I_margin == 0; I_margin = 0.1; end
B_range = max(B_data) - min(B_data);
if B_range == 0; B_margin = 0.1; else; B_margin = B_range * 0.1; end

% Plot 1: Input current vs. time
subplot(3, 1, 1);
plot(time_data, I_steps, '-b', 'LineWidth', 1.5);
grid on;
title('Input Current vs. Time', 'FontWeight', 'bold');
xlabel('Time (s)'); ylabel('Current (A)');
xlim([-t_margin, max(time_data) + t_margin]);
ylim([min(I_steps) - I_margin, max(I_steps) + I_margin]);
legend('Input Current', 'Location', 'best');

% Plot 2: Magnetic field vs. time
subplot(3, 1, 2);
plot(time_data, B_data, '-r', 'LineWidth', 1.5);
grid on;
title('Magnetic Field vs. Time', 'FontWeight', 'bold');
xlabel('Time (s)'); ylabel('Magnetic Field (Gauss)');
xlim([-t_margin, max(time_data) + t_margin]);
ylim([min(B_data) - B_margin, max(B_data) + B_margin]);
legend('Measured H-Field', 'Location', 'best');

% Plot 3: Magnetic field vs input current
ax3 = subplot(3, 1, 3);
plot(ax3, I_steps, B_data, '-k', 'LineWidth', 1.5);
grid(ax3, 'on');
title(ax3, 'Magnetic Field vs. Input Current', 'FontWeight', 'bold');
xlabel(ax3, 'Input Current (A)'); ylabel(ax3, 'Magnetic Field (Gauss)');
xlim(ax3, [min(I_steps) - I_margin, max(I_steps) + I_margin]);
ylim(ax3, [min(B_data) - B_margin, max(B_data) + B_margin]);
legend(ax3, 'H-I Curve', 'Location', 'best');

savefig(fig_final, fig_filename);
disp(['Figure saved to: ', fig_filename]);