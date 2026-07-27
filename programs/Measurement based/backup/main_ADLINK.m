function Tektronix2400_GUI_ADLINK()
    % Tektronix 2400 Resistance Measurement GUI (ADLINK Version)
    % Initializes the device via ADLINK GPIB (address 24), reads resistance, and plots it.
    
    % Create UI Figure
    fig = uifigure('Name', 'Tektronix 2400 Resistance (ADLINK)', 'Position', [100, 100, 800, 500], 'Color', 'w');
    
    % Connection Panel
    pnl_conn = uipanel(fig, 'Title', 'Connection (ADLINK)', 'Position', [20, 380, 220, 100], 'BackgroundColor', 'w', 'FontWeight', 'bold');
    btn_connect = uibutton(pnl_conn, 'Position', [10, 40, 95, 30], 'Text', 'Connect', 'ButtonPushedFcn', @connectHW);
    btn_disconnect = uibutton(pnl_conn, 'Position', [115, 40, 95, 30], 'Text', 'Disconnect', 'Enable', 'off', 'ButtonPushedFcn', @disconnectHW);
    lbl_status = uilabel(pnl_conn, 'Position', [10, 10, 200, 25], 'Text', '🔴 Disconnected', 'FontColor', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    % Measurement Panel
    pnl_meas = uipanel(fig, 'Title', 'Measurement Control', 'Position', [20, 260, 220, 110], 'BackgroundColor', 'w', 'FontWeight', 'bold');
    btn_start = uibutton(pnl_meas, 'Position', [10, 50, 90, 30], 'Text', 'Start', 'Enable', 'off', 'ButtonPushedFcn', @startMeasurement);
    btn_stop = uibutton(pnl_meas, 'Position', [110, 50, 90, 30], 'Text', 'Stop', 'Enable', 'off', 'ButtonPushedFcn', @stopMeasurement);
    
    lbl_res = uilabel(pnl_meas, 'Position', [10, 10, 200, 30], 'Text', 'Resistance: --- \Omega', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Plot Axes
    ax = uiaxes(fig, 'Position', [260, 20, 520, 450]);
    title(ax, 'Resistance over Time', 'FontWeight', 'bold');
    xlabel(ax, 'Time (s)', 'FontWeight', 'bold');
    ylabel(ax, 'Resistance (\Omega)', 'FontWeight', 'bold');
    grid(ax, 'on');
    
    % Application Variables
    smu = [];
    appTimer = [];
    timeData = [];
    resData = [];
    startTime = 0;
    
    % Make sure we clean up hardware connections when the user closes the window
    fig.CloseRequestFcn = @closeApp;
    
    % ==========================================
    % Callback Functions
    % ==========================================
    
    function connectHW(~, ~)
        try
            lbl_status.Text = 'Connecting...'; drawnow;
            
            % If a previous connection exists, clean it up
            try delete(instrfind); catch; end 
            
            % Create ADLINK GPIB object for the SourceMeter
            smu = gpib('adlink', 0, 24);
            smu.Timeout = 5;
            
            % Open connection
            fopen(smu);
            
            % Reset instrument and configure for resistance measurement
            fprintf(smu, "*RST");
            pause(1); 
            
            fprintf(smu, ":SENS:FUNC 'RES'");
            fprintf(smu, ":FORM:ELEM RES");
            
            lbl_status.Text = '🟢 Connected';
            lbl_status.FontColor = [0.47, 0.67, 0.19];
            
            btn_connect.Enable = 'off';
            btn_disconnect.Enable = 'on';
            btn_start.Enable = 'on';
        catch ME
            uialert(fig, ['Connection failed: ' ME.message], 'Hardware Error');
            lbl_status.Text = '🔴 Disconnected';
            lbl_status.FontColor = 'r';
        end
    end
    
    function disconnectHW(~, ~)
        % Ensure measurement is stopped
        stopMeasurement();
        
        % Release the instrument connection
        if ~isempty(smu) && isvalid(smu)
            try
                fclose(smu);
                delete(smu);
            catch
            end
        end
        smu = [];
        
        lbl_status.Text = '🔴 Disconnected';
        lbl_status.FontColor = 'r';
        btn_connect.Enable = 'on';
        btn_disconnect.Enable = 'off';
        btn_start.Enable = 'off';
    end
    
    function startMeasurement(~, ~)
        btn_start.Enable = 'off';
        btn_stop.Enable = 'on';
        
        % Reset plotting data
        timeData = [];
        resData = [];
        cla(ax); % Clear axes
        startTime = tic;
        
        % Turn on output for measurement
        if ~isempty(smu) && isvalid(smu)
            try fprintf(smu, ':OUTP ON'); catch; end
        end
        
        % Set up a timer to query the instrument every 0.5 seconds
        appTimer = timer('ExecutionMode', 'fixedRate', 'Period', 0.5, 'TimerFcn', @readSensor);
        start(appTimer);
    end
    
    function stopMeasurement(~, ~)
        btn_start.Enable = 'on';
        btn_stop.Enable = 'off';
        
        % Stop the polling timer
        if ~isempty(appTimer)
            stop(appTimer);
            delete(appTimer);
            appTimer = [];
        end
        
        % Turn off the output for safety
        if ~isempty(smu) && isvalid(smu)
            try fprintf(smu, ':OUTP OFF'); catch; end
        end
    end
    
    function readSensor(~, ~)
        if ~isempty(smu) && isvalid(smu)
            try
                % Trigger and acquire resistance reading
                fprintf(smu, ":READ?");
                res_str = fscanf(smu);
                res_val = str2double(res_str);
                
                % Update arrays
                t = toc(startTime);
                timeData(end+1) = t;
                resData(end+1) = res_val;
                
                % Update GUI label and Plot
                lbl_res.Text = sprintf('Resistance: %.4f \\Omega', res_val);
                plot(ax, timeData, resData, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
            catch ME
                % Fail silently on temporary timeout, or log the error
                disp(['Read error: ', ME.message]);
            end
        end
    end
    
    function closeApp(~, ~)
        stopMeasurement(); % Stop any running timers
        
        % Release the instrument connection
        if ~isempty(smu) && isvalid(smu)
            try
                fclose(smu);
                delete(smu);
                clear smu;
            catch
            end
        end
        
        % Close the window
        delete(fig);
    end
end
