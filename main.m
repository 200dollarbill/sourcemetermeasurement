function Tektronix2400_Kepco_Sweep_GUI()
    % GUI for sweeping Kepco current and measuring Tektronix resistance
    
    fig = uifigure('Name', 'Kepco Sweep + Tektronix 2400 (ADLINK)', 'Position', [100, 100, 900, 600], 'Color', 'w');
    
    % --- Connection Panel ---
    pnl_conn = uipanel(fig, 'Title', 'Hardware Connection', 'Position', [20, 470, 260, 110], 'BackgroundColor', 'w', 'FontWeight', 'bold');
    
    uilabel(pnl_conn, 'Position', [10, 60, 100, 22], 'Text', 'Kepco Addr:');
    edit_kepco = uieditfield(pnl_conn, 'numeric', 'Position', [90, 60, 40, 22], 'Value', 6);
    
    uilabel(pnl_conn, 'Position', [140, 60, 100, 22], 'Text', 'Tek Addr:');
    edit_tek = uieditfield(pnl_conn, 'numeric', 'Position', [210, 60, 40, 22], 'Value', 24);
    
    btn_connect = uibutton(pnl_conn, 'Position', [10, 20, 70, 30], 'Text', 'Connect', 'ButtonPushedFcn', @connectHW);
    btn_disconnect = uibutton(pnl_conn, 'Position', [90, 20, 70, 30], 'Text', 'Disconnect', 'Enable', 'off', 'ButtonPushedFcn', @disconnectHW);
    lbl_status = uilabel(pnl_conn, 'Position', [170, 20, 80, 30], 'Text', '🔴 Offline', 'FontColor', 'r', 'FontWeight', 'bold');
    
    % --- Sweep Settings Panel ---
    pnl_sweep = uipanel(fig, 'Title', 'Sweep Settings', 'Position', [20, 250, 260, 210], 'BackgroundColor', 'w', 'FontWeight', 'bold');
    
    uilabel(pnl_sweep, 'Position', [10, 175, 100, 22], 'Text', 'Start Curr (A):');
    edit_start = uieditfield(pnl_sweep, 'numeric', 'Position', [120, 175, 120, 22], 'Value', -1.0, 'Limits', [-1.05, 1.05]);
    
    uilabel(pnl_sweep, 'Position', [10, 145, 100, 22], 'Text', 'End Curr (A):');
    edit_end = uieditfield(pnl_sweep, 'numeric', 'Position', [120, 145, 120, 22], 'Value', 1.0, 'Limits', [-1.05, 1.05]);
    
    uilabel(pnl_sweep, 'Position', [10, 115, 100, 22], 'Text', 'Step (A):');
    edit_step = uieditfield(pnl_sweep, 'numeric', 'Position', [120, 115, 120, 22], 'Value', 0.1);
    
    uilabel(pnl_sweep, 'Position', [10, 85, 100, 22], 'Text', 'Delay (s):');
    edit_delay = uieditfield(pnl_sweep, 'numeric', 'Position', [120, 85, 120, 22], 'Value', 0.2);
    
    uilabel(pnl_sweep, 'Position', [10, 55, 100, 22], 'Text', 'Filename:');
    edit_filename = uieditfield(pnl_sweep, 'text', 'Position', [120, 55, 120, 22], 'Value', 'Sweep_Data');
    
    btn_save = uibutton(pnl_sweep, 'Position', [10, 15, 230, 30], 'Text', 'Save to Excel', 'Enable', 'off', 'ButtonPushedFcn', @saveManual);
    
    % --- Measurement Control ---
    pnl_meas = uipanel(fig, 'Title', 'Measurement Control', 'Position', [20, 130, 260, 110], 'BackgroundColor', 'w', 'FontWeight', 'bold');
    btn_start = uibutton(pnl_meas, 'Position', [10, 50, 110, 30], 'Text', 'Start Sweep', 'Enable', 'off', 'ButtonPushedFcn', @startSweep);
    btn_stop = uibutton(pnl_meas, 'Position', [130, 50, 110, 30], 'Text', 'Stop / Abort', 'Enable', 'off', 'ButtonPushedFcn', @stopSweep);
    
    lbl_res = uilabel(pnl_meas, 'Position', [10, 10, 240, 30], 'Text', 'Resistance: --- \Omega', 'FontSize', 14, 'FontWeight', 'bold');
    
    % --- Axes ---
    ax = uiaxes(fig, 'Position', [300, 20, 580, 560]);
    title(ax, 'Resistance vs. Current', 'FontWeight', 'bold');
    xlabel(ax, 'Kepco Current (A)', 'FontWeight', 'bold');
    ylabel(ax, 'Tektronix Resistance (\Omega)', 'FontWeight', 'bold');
    grid(ax, 'on');
    
    % Vars
    smu = [];
    kepco = [];
    stop_flag = false;
    currData = [];
    resData = [];
    
    fig.CloseRequestFcn = @closeApp;
    
    % ==================================================
    
    function connectHW(~, ~)
        try
            lbl_status.Text = 'Connecting...'; drawnow;
            try delete(instrfind); catch; end 
            
            % Kepco Connection
            kepco = gpib('adlink', 0, edit_kepco.Value);
            kepco.Timeout = 5;
            fopen(kepco);
            
            % Tektronix Connection
            smu = gpib('adlink', 0, edit_tek.Value);
            smu.Timeout = 5;
            fopen(smu);
            
            % Setup Tektronix
            fprintf(smu, "*RST");
            pause(0.5); 
            fprintf(smu, ":SENS:FUNC 'RES'");
            fprintf(smu, ":FORM:ELEM RES");
            
            % Setup Kepco (safe state)
            fprintf(kepco, 'FUNC:MODE CURR'); 
            fprintf(kepco, 'VOLT 20.0'); 
            fprintf(kepco, 'CURR 0.0'); 
            
            lbl_status.Text = '🟢 Online';
            lbl_status.FontColor = [0.47, 0.67, 0.19];
            
            btn_connect.Enable = 'off';
            btn_disconnect.Enable = 'on';
            btn_start.Enable = 'on';
        catch ME
            uialert(fig, ['Connection failed: ' ME.message], 'Hardware Error');
            lbl_status.Text = '🔴 Offline';
        end
    end
    
    function disconnectHW(~, ~)
        stop_flag = true; % stop any running sweeps
        safeShutdown();
        
        if ~isempty(smu) && isvalid(smu)
            try fclose(smu); delete(smu); catch; end
        end
        if ~isempty(kepco) && isvalid(kepco)
            try fclose(kepco); delete(kepco); catch; end
        end
        smu = []; kepco = [];
        
        lbl_status.Text = '🔴 Offline';
        lbl_status.FontColor = 'r';
        btn_connect.Enable = 'on';
        btn_disconnect.Enable = 'off';
        btn_start.Enable = 'off';
    end
    
    function startSweep(~, ~)
        btn_start.Enable = 'off';
        btn_stop.Enable = 'on';
        btn_disconnect.Enable = 'off';
        stop_flag = false;
        
        s_I = edit_start.Value;
        e_I = edit_end.Value;
        
        % Safety limiter: max +/- 1.05A
        if s_I > 1.05
            s_I = 1.05;
            edit_start.Value = s_I;
        elseif s_I < -1.05
            s_I = -1.05;
            edit_start.Value = s_I;
        end
        
        if e_I > 1.05
            e_I = 1.05;
            edit_end.Value = e_I;
        elseif e_I < -1.05
            e_I = -1.05;
            edit_end.Value = e_I;
        end
        
        step_I = abs(edit_step.Value);
        pause_T = edit_delay.Value;
        
        if step_I == 0; step_I = 0.1; end
        
        % Generate sweep points
        if s_I < e_I
            I_steps = s_I : step_I : e_I;
            if I_steps(end) ~= e_I; I_steps(end+1) = e_I; end
        else
            I_steps = s_I : -step_I : e_I;
            if I_steps(end) ~= e_I; I_steps(end+1) = e_I; end
        end
        
        % Prepare plot
        cla(ax);
        hLine = plot(ax, nan, nan, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
        xlim(ax, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);
        
        currData = [];
        resData = [];
        btn_save.Enable = 'off';
        
        try
            % Turn on outputs
            fprintf(kepco, 'OUTP ON');
            fprintf(smu, ':OUTP ON');
            pause(0.5);
            
            for i = 1:length(I_steps)
                if stop_flag; break; end
                
                % Set Kepco Current
                target_I = I_steps(i);
                fprintf(kepco, sprintf('CURR %.3f', target_I));
                
                % Wait for settling
                pause(pause_T);
                
                % Read Tektronix Resistance
                fprintf(smu, ':READ?');
                res_str = fscanf(smu);
                res_val = str2double(res_str);
                
                % Update Plot
                currData(end+1) = target_I;
                resData(end+1) = res_val;
                
                lbl_res.Text = sprintf('Resistance: %.4f \\Omega', res_val);
                set(hLine, 'XData', currData, 'YData', resData);
                drawnow limitrate;
            end
            
        catch ME
            uialert(fig, ['Error during sweep: ', ME.message], 'Error');
        end
        
        safeShutdown();
        btn_start.Enable = 'on';
        btn_stop.Enable = 'off';
        btn_disconnect.Enable = 'on';
        
        if ~isempty(currData)
            btn_save.Enable = 'on';
        end
    end
    
    function stopSweep(~, ~)
        stop_flag = true;
    end
    
    function safeShutdown()
        % Turn off Kepco output safely
        if ~isempty(kepco) && isvalid(kepco)
            try
                fprintf(kepco, 'CURR 0.0');
                pause(0.2);
                fprintf(kepco, 'OUTP OFF');
            catch
            end
        end
        % Turn off Tektronix output safely
        if ~isempty(smu) && isvalid(smu)
            try
                fprintf(smu, ':OUTP OFF');
            catch
            end
        end
    end

    function closeApp(~, ~)
        stop_flag = true;
        safeShutdown();
        disconnectHW();
        delete(fig);
    end
    
    function saveManual(~, ~)
        if ~isempty(currData)
            % Ask user for file location and name
            defaultName = sprintf('%s.xlsx', edit_filename.Value);
            [file, path] = uiputfile('*.xlsx', 'Save Data As', defaultName);
            
            % Check if user cancelled
            if isequal(file, 0) || isequal(path, 0)
                return;
            end
            
            fullPath = fullfile(path, file);
            
            % Create table and export
            T = table(currData(:), resData(:), 'VariableNames', {'Kepco_Current_A', 'Tektronix_Resistance_Ohms'});
            try
                writetable(T, fullPath);
                uialert(fig, sprintf('Data successfully saved to:\n%s', fullPath), 'Save Complete', 'Icon', 'success');
            catch ME
                uialert(fig, ['Failed to save Excel file: ' ME.message], 'Save Error', 'Icon', 'warning');
            end
        end
    end
end
