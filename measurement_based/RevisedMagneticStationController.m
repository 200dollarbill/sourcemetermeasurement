classdef RevisedMagneticStationController < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        TabGroup2                      matlab.ui.container.TabGroup
        Tab2_2                         matlab.ui.container.Tab
        ConnectionPanel                matlab.ui.container.Panel
        StatusLabel                    matlab.ui.control.Label
        DisconnectButton               matlab.ui.control.Button
        ConnectButton                  matlab.ui.control.Button
        Label                          matlab.ui.control.Label
        SupplyAddrEditField_2          matlab.ui.control.NumericEditField
        SupplyAddrEditFieldLabel_2     matlab.ui.control.Label
        GaussmeterAddrEditFieldLabel   matlab.ui.control.Label
        DropDown                       matlab.ui.control.DropDown
        GaussmeterAddrEditField        matlab.ui.control.NumericEditField
        SupplyAddrEditField            matlab.ui.control.NumericEditField
        SupplyAddrEditFieldLabel       matlab.ui.control.Label
        Tab                            matlab.ui.container.Tab
        ButtonGroup                    matlab.ui.container.ButtonGroup
        NormalButton                   matlab.ui.control.RadioButton
        ReturntoZeroButton             matlab.ui.control.RadioButton
        ControlPanel_2                 matlab.ui.container.Panel
        RealTimePlotCheckBox           matlab.ui.control.CheckBox
        PlotButton                     matlab.ui.control.Button
        ResistanceOhmsLabel            matlab.ui.control.Label
        StopButton                     matlab.ui.control.Button
        StartButton                    matlab.ui.control.Button
        HysteresisCheckBox             matlab.ui.control.CheckBox
        DelaypercyclesEditField        matlab.ui.control.EditField
        DelaypercyclesEditFieldLabel   matlab.ui.control.Label
        CyclecountEditField            matlab.ui.control.EditField
        CyclecountEditFieldLabel       matlab.ui.control.Label
        TimetofinishLabel              matlab.ui.control.Label
        SettingsPanel                  matlab.ui.container.Panel
        MeasuretimesEditField          matlab.ui.control.NumericEditField
        MeasuretimesEditFieldLabel     matlab.ui.control.Label
        StartCurrentAEditField_3       matlab.ui.control.NumericEditField
        StartCurrentAEditFieldLabel_3  matlab.ui.control.Label
        StartCurrentAEditField_2       matlab.ui.control.NumericEditField
        StartCurrentAEditFieldLabel_2  matlab.ui.control.Label
        FilenameEditField_2            matlab.ui.control.EditField
        FilenameEditField_2Label       matlab.ui.control.Label
        SteptimesEditField             matlab.ui.control.NumericEditField
        SteptimesEditFieldLabel        matlab.ui.control.Label
        SavetoExcelButton              matlab.ui.control.Button
        StepsizeAEditField             matlab.ui.control.NumericEditField
        StepsizeAEditFieldLabel        matlab.ui.control.Label
        SupplyAddrEditField_4          matlab.ui.control.NumericEditField
        SupplyAddrEditFieldLabel_3     matlab.ui.control.Label
        StartCurrentAEditField         matlab.ui.control.NumericEditField
        StartCurrentAEditFieldLabel    matlab.ui.control.Label
        TabGroup                       matlab.ui.container.TabGroup
        OhmsATab                       matlab.ui.container.Tab
        UIAxes                         matlab.ui.control.UIAxes
        OhmsGTab                       matlab.ui.container.Tab
        UIAxes2                        matlab.ui.control.UIAxes
        GATab                          matlab.ui.container.Tab
        UIAxes_2                       matlab.ui.control.UIAxes
        AsTab                          matlab.ui.container.Tab
        UIAxes_3                       matlab.ui.control.UIAxes
        GsTab                          matlab.ui.container.Tab
        UIAxes_4                       matlab.ui.control.UIAxes
    end

    % Non-UI properties for hardware handles and sweep data
    properties (Access = private)
        Kepco
        SMU
        Gaussmeter
        StopFlag = false
        CurrData = []
        MeasuredCurrData = [] 
        ResData = []
        FieldData = []
        TimeData = []
        TimeCurrData = []
        TimeFieldData = []
        hLine1
        hLine2
        hLine3
        hLine4
        hLine5
        ticStart
    end

    % Callbacks that handle component events
    methods (Access = private)
        
        function recordTimePoint(app)
            t = toc(app.ticStart);
            app.TimeData(end+1) = t;
            
            if ~isempty(app.Kepco)
                fprintf(app.Kepco, 'MEAS:CURR?');
                c_val = str2double(fscanf(app.Kepco));
                app.TimeCurrData(end+1) = c_val;
            else
                app.TimeCurrData(end+1) = 0;
            end
            
            if ~isempty(app.Gaussmeter)
                fprintf(app.Gaussmeter, 'RDGFIELD?');
                f_val = str2double(fscanf(app.Gaussmeter));
                app.TimeFieldData(end+1) = f_val;
            else
                app.TimeFieldData(end+1) = NaN;
            end
            
            if app.RealTimePlotCheckBox.Value
                set(app.hLine4, 'XData', app.TimeData, 'YData', app.TimeCurrData);
                if ~isempty(app.Gaussmeter)
                    set(app.hLine5, 'XData', app.TimeData, 'YData', app.TimeFieldData);
                end
            end
            drawnow limitrate;
        end
        
        function updateStaticPlots(app)
            if app.RealTimePlotCheckBox.Value
                if ~isempty(app.ResData) && length(app.ResData) == length(app.FieldData) && ~isempty(app.FieldData)
                    set(app.hLine2, 'XData', app.FieldData, 'YData', app.ResData);
                elseif isempty(app.ResData) && length(app.CurrData) == length(app.FieldData) && ~isempty(app.FieldData)
                    set(app.hLine1, 'XData', app.CurrData, 'YData', app.FieldData);
                    set(app.hLine2, 'XData', app.CurrData, 'YData', app.FieldData);
                end

                if length(app.CurrData) == length(app.FieldData) && ~isempty(app.FieldData)
                    set(app.hLine3, 'XData', app.CurrData, 'YData', app.FieldData);
                end
                
                if ~isempty(app.ResData) && length(app.CurrData) == length(app.ResData)
                    set(app.hLine1, 'XData', app.CurrData, 'YData', app.ResData);
                end
            end
        end

        % Button pushed function: SavetoExcelButton
        function SavetoExcelButtonPushed(app, event)
            if ~isempty(app.CurrData)
                defaultName = sprintf('%s.xlsx', app.FilenameEditField_2.Value);
                [file, path] = uiputfile('*.xlsx', 'Save Data As', defaultName);
                if isequal(file, 0) || isequal(path, 0)
                    return;
                end

                fullPath = fullfile(path, file);

                % table creation for static data
                if length(app.ResData) == length(app.CurrData) && length(app.FieldData) == length(app.CurrData)
                    R = app.ResData(:);
                    H = app.FieldData(:);
                    R_min = min(R);
                    MR_Ratio_Percent = (R - R_min) ./ R_min * 100;
                    
                    if length(R) > 1 && length(H) > 1
                        total_sensitivity = (max(R) - min(R)) / (max(H) - min(H));
                        Sensitivity_Ohms_per_G = repmat(total_sensitivity, size(R));
                        Sensitivity_Ohms_per_G(~isfinite(Sensitivity_Ohms_per_G)) = 0;
                    else
                        Sensitivity_Ohms_per_G = zeros(size(R));
                    end
                    
                    T = table(app.CurrData(:), R, H, MR_Ratio_Percent, Sensitivity_Ohms_per_G, ...
                        'VariableNames', {'Kepco_Current_A', 'Resistance_Ohms', 'Magnetic_Field_G', 'MR_Ratio_Percent', 'Sensitivity_Ohms_per_G'});
                elseif length(app.ResData) == length(app.CurrData)
                    R = app.ResData(:);
                    R_min = min(R);
                    MR_Ratio_Percent = (R - R_min) ./ R_min * 100;
                    
                    T = table(app.CurrData(:), R, MR_Ratio_Percent, ...
                        'VariableNames', {'Kepco_Current_A', 'Resistance_Ohms', 'MR_Ratio_Percent'});
                elseif length(app.FieldData) == length(app.CurrData)
                    T = table(app.CurrData(:), app.FieldData(:), ...
                        'VariableNames', {'Kepco_Current_A', 'Magnetic_Field_G'});
                else
                    T = table(app.CurrData(:), 'VariableNames', {'Kepco_Current_A'});
                end
                
                % Time-based data sheet
                TimeTable = table(app.TimeData(:), app.TimeCurrData(:), app.TimeFieldData(:), ...
                    'VariableNames', {'Time_s', 'Kepco_Current_A', 'Magnetic_Field_G'});

                try
                    writetable(T, fullPath, 'Sheet', 'StaticData');
                    writetable(TimeTable, fullPath, 'Sheet', 'TimeData');
                    uialert(app.UIFigure, sprintf('Data successfully saved to:\n%s', fullPath), 'Save Complete', 'Icon', 'success');
                catch ME
                    uialert(app.UIFigure, ['Failed to save Excel file: ' ME.message], 'Save Error', 'Icon', 'warning');
                end
            end
        end

        % Value changed function: DropDown
        function DropDownValueChanged(app, event)
            value = app.DropDown.Value;
        end

        % Clicked callback: DropDown
        function DropDownClicked(app, event)
            item = event.InteractionInformation.Item;
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            app.StartButton.Enable = 'off';
            app.StopButton.Enable = 'on';
            app.DisconnectButton.Enable = 'off';
            app.PlotButton.Enable = 'off';
            app.StopFlag = false;
            s_I = app.StartCurrentAEditField.Value;
            e_I = app.SupplyAddrEditField_4.Value;

            % Read max and min current limits
            max_I = app.StartCurrentAEditField_2.Value;
            min_I = app.StartCurrentAEditField_3.Value;

            if max_I < min_I
                temp = max_I; max_I = min_I; min_I = temp;
            end

            % current check max limits
            if s_I > max_I
                s_I = max_I;
                app.StartCurrentAEditField.Value = s_I;
            elseif s_I < min_I
                s_I = min_I;
                app.StartCurrentAEditField.Value = s_I;
            end
            if e_I > max_I
                e_I = max_I;
                app.SupplyAddrEditField_4.Value = e_I;
            elseif e_I < min_I
                e_I = min_I;
                app.SupplyAddrEditField_4.Value = e_I;
            end
            
            step_I = abs(app.StepsizeAEditField.Value);
            step_T = app.SteptimesEditField.Value;
            meas_T = app.MeasuretimesEditField.Value;
            
            cycles = str2double(app.CyclecountEditField.Value);
            if isnan(cycles) || cycles < 1; cycles = 1; end
            delay_cycle = str2double(app.DelaypercyclesEditField.Value);
            if isnan(delay_cycle) || delay_cycle < 0; delay_cycle = 0; end
            isRTZ = app.ReturntoZeroButton.Value;
            
            if step_I == 0; step_I = 0.1; end
            % sweep points
            if s_I < e_I
                I_steps = s_I : step_I : e_I;
                if I_steps(end) ~= e_I; I_steps(end+1) = e_I; end
            else
                I_steps = s_I : -step_I : e_I;
                if I_steps(end) ~= e_I; I_steps(end+1) = e_I; end
            end

            % hysteresis loop
            if app.HysteresisCheckBox.Value
                if length(I_steps) > 1
                    I_steps = [I_steps, I_steps(end-1:-1:1)];
                end
            end

            % Setup ETA estimation
            points_per_cycle = length(I_steps);
            time_per_point = step_T + 1.0; % 1.0s overhead approx for two recordTimePoint calls
            if isRTZ
                time_per_point = 2 * step_T + 2.0;
            end
            total_time_est = cycles * points_per_cycle * time_per_point + (cycles - 1) * delay_cycle;

            % plots
            mode = app.DropDown.Value;
            if strcmp(mode, 'Supply + Gaussmeter')
                title(app.UIAxes, 'Magnetic Field vs Current');
                xlabel(app.UIAxes, 'Input Current (A)');
                ylabel(app.UIAxes, 'Measured Magnetic Field Strength (G)');
                
                title(app.UIAxes2, 'Magnetic Field vs Current');
                xlabel(app.UIAxes2, 'Input Current (A)');
                ylabel(app.UIAxes2, 'Measured Magnetic Field Strength (G)');
            else
                title(app.UIAxes, 'Resistance vs Current');
                xlabel(app.UIAxes, 'Input Current (A)');
                ylabel(app.UIAxes, 'Measured Resistance (Ohms)');
                
                title(app.UIAxes2, 'Resistance vs Magnetic Field');
                xlabel(app.UIAxes2, 'Measured Magnetic Field Strength (G)');
                ylabel(app.UIAxes2, 'Measured Resistance (Ohms)');
            end

            title(app.UIAxes_2, 'Magnetic Field vs Current');
            xlabel(app.UIAxes_2, 'Input Current (A)');
            ylabel(app.UIAxes_2, 'Measured Magnetic Field Strength (G)');

            cla(app.UIAxes);
            cla(app.UIAxes2);
            cla(app.UIAxes_2);
            cla(app.UIAxes_3);
            cla(app.UIAxes_4);
            
            app.hLine1 = plot(app.UIAxes, nan, nan, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
            xlim(app.UIAxes, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);
            app.hLine2 = plot(app.UIAxes2, nan, nan, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
            if strcmp(mode, 'Supply + Gaussmeter')
                xlim(app.UIAxes2, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);
            end
            app.hLine3 = plot(app.UIAxes_2, nan, nan, '-go', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
            xlim(app.UIAxes_2, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);
            
            app.hLine4 = plot(app.UIAxes_3, nan, nan, '-ko', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
            app.hLine5 = plot(app.UIAxes_4, nan, nan, '-mo', 'LineWidth', 1.5, 'MarkerFaceColor', 'm');

            app.CurrData = [];
            app.MeasuredCurrData = [];
            app.ResData = [];
            app.FieldData = [];
            app.TimeData = [];
            app.TimeCurrData = [];
            app.TimeFieldData = [];
            
            app.SavetoExcelButton.Enable = 'off';

            try
                % output
                fprintf(app.Kepco, 'OUTP ON');
                if ~isempty(app.SMU)
                    fprintf(app.SMU, ':OUTP ON');
                end

                fprintf(app.Kepco, sprintf('CURR %.3f', s_I))
                pause(1);

                app.ticStart = tic;

                for c = 1:cycles
                    for i = 1:length(I_steps)
                        if app.StopFlag; break; end
                        
                        elapsed = toc(app.ticStart);
                        eta = max(0, total_time_est - elapsed);
                        app.TimetofinishLabel.Text = sprintf('Time to finish : %.1f s', eta);

                        % current setup
                        target_I = I_steps(i);
                        fprintf(app.Kepco, sprintf('CURR %.3f', target_I));
                        
                        % pause(0.05)
                        pause(0.05);
                        
                        % Measure power supply & gaussmeter & plot (Start)
                        recordTimePoint(app);
                        
                        % pause(Measuretime-0.05)
                        pause(max(0, meas_T - 0.05));
                        
                        % Measure source meter, gauss meter, power supply & plot (Sensor measure)
                        recordTimePoint(app);
                        
                        % Record for static plots
                        app.CurrData(end+1) = app.TimeCurrData(end);
                        
                        % source meter reading
                        if ~isempty(app.SMU)
                            fprintf(app.SMU, ':READ?');
                            res_str = fscanf(app.SMU);
                            res_val = str2double(res_str);
                            app.ResData(end+1) = res_val;
                            app.ResistanceOhmsLabel.Text = sprintf('Resistance : %.4f Ohms', res_val);
                        end

                        % gaussmeeter reading from TimeFieldData
                        if ~isempty(app.Gaussmeter)
                            app.FieldData(end+1) = app.TimeFieldData(end);
                        end

                        updateStaticPlots(app);
                        
                        % pause(step_time - Measuretime - 0.05)
                        pause(max(0, step_T - meas_T - 0.05));
                        
                        % Measure power supply & gaussmeter & plot (End)
                        recordTimePoint(app);
                        
                        % pause(0.05) before next Update current
                        pause(0.05);
                        
                        if isRTZ
                            fprintf(app.Kepco, 'CURR 0.0');
                            
                            % Same delay sequence for the zero point
                            pause(0.05);
                            recordTimePoint(app);
                            
                            pause(max(0, meas_T - 0.05));
                            recordTimePoint(app);
                            
                            pause(max(0, step_T - meas_T - 0.05));
                            recordTimePoint(app);
                            
                            pause(0.05);
                        end
                    end
                    
                    if app.StopFlag; break; end
                    
                    if c < cycles
                        pause(delay_cycle);
                    end
                end
                
                app.TimetofinishLabel.Text = 'Time to finish : 0.0 s';

            catch ME
                uialert(app.UIFigure, ['Error during sweep: ', ME.message], 'Error');
            end

            app.safeShutdown();
            app.StartButton.Enable = 'on';
            app.StopButton.Enable = 'off';
            app.DisconnectButton.Enable = 'on';

            if ~isempty(app.CurrData)
                app.SavetoExcelButton.Enable = 'on';
                if ~app.RealTimePlotCheckBox.Value
                    app.PlotButton.Enable = 'on';
                end
                
                beep; pause(0.3); beep;
                uialert(app.UIFigure, 'The measurement sequence has finished.', 'Measurement Finished', 'Icon', 'warning');
            end
        end

        % Button pushed function: PlotButton
        function PlotButtonPushed(app, event)
            app.RealTimePlotCheckBox.Value = true; % Force plot refresh
            updateStaticPlots(app);
            
            if ~isempty(app.TimeData)
                set(app.hLine4, 'XData', app.TimeData, 'YData', app.TimeCurrData);
                if ~isempty(app.Gaussmeter)
                    set(app.hLine5, 'XData', app.TimeData, 'YData', app.TimeFieldData);
                end
            end
            drawnow limitrate;
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.StopFlag = true;
        end

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            try
                app.StatusLabel.Text = 'Connecting...'; drawnow;
                try delete(instrfind); catch; end

                mode = app.DropDown.Value;
                % power supply connection
                app.Kepco = gpib('adlink', 0, app.SupplyAddrEditField.Value);
                app.Kepco.Timeout = 5;
                fopen(app.Kepco);
                % power supply
                fprintf(app.Kepco, 'FUNC:MODE CURR');
                fprintf(app.Kepco, 'VOLT 20.0');
                fprintf(app.Kepco, 'CURR 0.0');

                switch mode

                case 'Supply + Source meter'
                    % source meter connection
                    app.SMU = gpib('adlink', 0, app.SupplyAddrEditField_2.Value);
                    app.SMU.Timeout = 5;
                    fopen(app.SMU);
                    % source meter 
                    fprintf(app.SMU, "*RST");
                    pause(2);
                    fprintf(app.SMU, ":SENS:FUNC 'RES'");
                    fprintf(app.SMU, ":SENS:RES:OCOM ON");
                    fprintf(app.SMU, ":FORM:ELEM RES");

                case 'Supply + Gaussmeter'
                    % Gaussmeter connection
                    app.Gaussmeter = gpib('adlink', 0, app.GaussmeterAddrEditField.Value);
                    app.Gaussmeter.Timeout = 5;
                    fopen(app.Gaussmeter);

                    fprintf(app.Gaussmeter, '*RST');
                    pause(0.5);
                    fprintf(app.Gaussmeter, 'UNIT 1');
                    fprintf(app.Gaussmeter, 'AUTO 1');

                case 'All instruments'
                    % source meter connection
                    app.SMU = gpib('adlink', 0, app.SupplyAddrEditField_2.Value);
                    app.SMU.Timeout = 5;
                    fopen(app.SMU);

                    fprintf(app.SMU, "*RST");
                    pause(2);
                    fprintf(app.SMU, ":SENS:FUNC 'RES'");
                    fprintf(app.SMU, ":SENS:RES:OCOM ON");
                    fprintf(app.SMU, ":FORM:ELEM RES");

                    % gaussmeter
                    app.Gaussmeter = gpib('adlink', 0, app.GaussmeterAddrEditField.Value);
                    app.Gaussmeter.Timeout = 5;
                    fopen(app.Gaussmeter);

                    fprintf(app.Gaussmeter, '*RST');
                    pause(0.5);
                    fprintf(app.Gaussmeter, 'UNIT 1');
                    fprintf(app.Gaussmeter, 'AUTO 1');

                end

                app.StatusLabel.Text = 'Online';
                app.StatusLabel.FontColor = [0.47, 0.67, 0.19];

                app.ConnectButton.Enable = 'off';
                app.DisconnectButton.Enable = 'on';
                app.StartButton.Enable = 'on';
            catch ME
                uialert(app.UIFigure, ['Connection failed: ' ME.message], 'Hardware Error');
                app.StatusLabel.Text = 'Offline';
            end
        end

        % Button pushed function: DisconnectButton
        function DisconnectButtonPushed(app, event)
            app.StopFlag = true;
            app.safeShutdown();

            if ~isempty(app.SMU) && isvalid(app.SMU)
                try fclose(app.SMU); delete(app.SMU); catch; end
            end
            if ~isempty(app.Kepco) && isvalid(app.Kepco)
                try fclose(app.Kepco); delete(app.Kepco); catch; end
            end
            if ~isempty(app.Gaussmeter) && isvalid(app.Gaussmeter)
                try fclose(app.Gaussmeter); delete(app.Gaussmeter); catch; end
            end
            app.SMU = []; app.Kepco = []; app.Gaussmeter = [];

            app.StatusLabel.Text = 'Offline';
            app.StatusLabel.FontColor = 'r';
            app.ConnectButton.Enable = 'on';
            app.DisconnectButton.Enable = 'off';
            app.StartButton.Enable = 'off';
        end
        
        function safeShutdown(app)
            if ~isempty(app.Kepco) && isvalid(app.Kepco)
                try
                    fprintf(app.Kepco, 'CURR 0.0');
                    pause(0.2);
                    fprintf(app.Kepco, 'OUTP OFF');
                catch
                end
            end
            if ~isempty(app.SMU) && isvalid(app.SMU)
                try
                    fprintf(app.SMU, ':OUTP OFF');
                catch
                end
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1147 805];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [310 21 820 757];

            % Create OhmsATab
            app.OhmsATab = uitab(app.TabGroup);
            app.OhmsATab.Title = 'Ohms/A';

            % Create UIAxes
            app.UIAxes = uiaxes(app.OhmsATab);
            title(app.UIAxes, 'Resistance vs Current')
            xlabel(app.UIAxes, 'Input Current (A)')
            ylabel(app.UIAxes, 'Measured Resistance (Ohms)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [14 76 782 635];

            % Create OhmsGTab
            app.OhmsGTab = uitab(app.TabGroup);
            app.OhmsGTab.Title = 'Ohms/G';

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.OhmsGTab);
            title(app.UIAxes2, 'Resistance vs Magnetic Field')
            xlabel(app.UIAxes2, 'Measured Resistance (Ohms)')
            ylabel(app.UIAxes2, 'Measured Magnetic Field Strength (G)')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [15 76 781 635];

            % Create GATab
            app.GATab = uitab(app.TabGroup);
            app.GATab.Title = 'G/A';

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.GATab);
            title(app.UIAxes_2, 'Magnetic field vs Current')
            xlabel(app.UIAxes_2, 'Measured Magnetic Field (G)')
            ylabel(app.UIAxes_2, 'Measured Resistance (Ohms)')
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.Position = [14 76 782 635];

            % Create AsTab
            app.AsTab = uitab(app.TabGroup);
            app.AsTab.Title = 'A/s';

            % Create UIAxes_3
            app.UIAxes_3 = uiaxes(app.AsTab);
            title(app.UIAxes_3, 'Output current vs Time')
            xlabel(app.UIAxes_3, 'Time (s)')
            ylabel(app.UIAxes_3, 'Measured output current (s)')
            zlabel(app.UIAxes_3, 'Z')
            app.UIAxes_3.Position = [14 76 782 635];

            % Create GsTab
            app.GsTab = uitab(app.TabGroup);
            app.GsTab.Title = 'G/s';

            % Create UIAxes_4
            app.UIAxes_4 = uiaxes(app.GsTab);
            title(app.UIAxes_4, 'Measured Magnetic field vs Time')
            xlabel(app.UIAxes_4, 'Time (s)')
            ylabel(app.UIAxes_4, 'Measured magnetic field(G)')
            zlabel(app.UIAxes_4, 'Z')
            app.UIAxes_4.Position = [14 76 782 635];

            % Create TabGroup2
            app.TabGroup2 = uitabgroup(app.UIFigure);
            app.TabGroup2.Position = [17 20 285 758];

            % Create Tab
            app.Tab = uitab(app.TabGroup2);
            app.Tab.Title = 'Tab';

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.Tab);
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.Position = [13 352 265 370];

            % Create StartCurrentAEditFieldLabel
            app.StartCurrentAEditFieldLabel = uilabel(app.SettingsPanel);
            app.StartCurrentAEditFieldLabel.HorizontalAlignment = 'right';
            app.StartCurrentAEditFieldLabel.Position = [19 248 93 22];
            app.StartCurrentAEditFieldLabel.Text = 'Start Current (A)';

            % Create StartCurrentAEditField
            app.StartCurrentAEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.StartCurrentAEditField.Position = [139 248 100 22];
            app.StartCurrentAEditField.Value = -1;

            % Create SupplyAddrEditFieldLabel_3
            app.SupplyAddrEditFieldLabel_3 = uilabel(app.SettingsPanel);
            app.SupplyAddrEditFieldLabel_3.HorizontalAlignment = 'right';
            app.SupplyAddrEditFieldLabel_3.Position = [19 216 89 22];
            app.SupplyAddrEditFieldLabel_3.Text = 'End Current (A)';

            % Create SupplyAddrEditField_4
            app.SupplyAddrEditField_4 = uieditfield(app.SettingsPanel, 'numeric');
            app.SupplyAddrEditField_4.Position = [139 216 100 22];
            app.SupplyAddrEditField_4.Value = 1;

            % Create StepsizeAEditFieldLabel
            app.StepsizeAEditFieldLabel = uilabel(app.SettingsPanel);
            app.StepsizeAEditFieldLabel.HorizontalAlignment = 'right';
            app.StepsizeAEditFieldLabel.Position = [19 186 74 22];
            app.StepsizeAEditFieldLabel.Text = 'Step size (A)';

            % Create StepsizeAEditField
            app.StepsizeAEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.StepsizeAEditField.Position = [139 186 100 22];
            app.StepsizeAEditField.Value = 0.1;

            % Create SavetoExcelButton
            app.SavetoExcelButton = uibutton(app.SettingsPanel, 'push');
            app.SavetoExcelButton.ButtonPushedFcn = createCallbackFcn(app, @SavetoExcelButtonPushed, true);
            app.SavetoExcelButton.Position = [22 14 220 33];
            app.SavetoExcelButton.Text = 'Save to Excel';

            % Create SteptimesEditFieldLabel
            app.SteptimesEditFieldLabel = uilabel(app.SettingsPanel);
            app.SteptimesEditFieldLabel.HorizontalAlignment = 'right';
            app.SteptimesEditFieldLabel.Position = [19 145 73 22];
            app.SteptimesEditFieldLabel.Text = 'Step time (s)';

            % Create SteptimesEditField
            app.SteptimesEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.SteptimesEditField.Position = [141 145 98 22];
            app.SteptimesEditField.Value = 0.2;

            % Create FilenameEditField_2Label
            app.FilenameEditField_2Label = uilabel(app.SettingsPanel);
            app.FilenameEditField_2Label.HorizontalAlignment = 'right';
            app.FilenameEditField_2Label.Position = [19 65 54 22];
            app.FilenameEditField_2Label.Text = 'Filename';

            % Create FilenameEditField_2
            app.FilenameEditField_2 = uieditfield(app.SettingsPanel, 'text');
            app.FilenameEditField_2.HorizontalAlignment = 'right';
            app.FilenameEditField_2.Position = [139 65 100 22];
            app.FilenameEditField_2.Value = 'Data';

            % Create StartCurrentAEditFieldLabel_2
            app.StartCurrentAEditFieldLabel_2 = uilabel(app.SettingsPanel);
            app.StartCurrentAEditFieldLabel_2.HorizontalAlignment = 'right';
            app.StartCurrentAEditFieldLabel_2.Position = [20 312 89 22];
            app.StartCurrentAEditFieldLabel_2.Text = 'Max Current (+)';

            % Create StartCurrentAEditField_2
            app.StartCurrentAEditField_2 = uieditfield(app.SettingsPanel, 'numeric');
            app.StartCurrentAEditField_2.Position = [140 312 100 22];
            app.StartCurrentAEditField_2.Value = -2;

            % Create StartCurrentAEditFieldLabel_3
            app.StartCurrentAEditFieldLabel_3 = uilabel(app.SettingsPanel);
            app.StartCurrentAEditFieldLabel_3.HorizontalAlignment = 'right';
            app.StartCurrentAEditFieldLabel_3.Position = [21 280 83 22];
            app.StartCurrentAEditFieldLabel_3.Text = 'Min Current (-)';

            % Create StartCurrentAEditField_3
            app.StartCurrentAEditField_3 = uieditfield(app.SettingsPanel, 'numeric');
            app.StartCurrentAEditField_3.Position = [140 280 100 22];
            app.StartCurrentAEditField_3.Value = -1;

            % Create MeasuretimesEditFieldLabel
            app.MeasuretimesEditFieldLabel = uilabel(app.SettingsPanel);
            app.MeasuretimesEditFieldLabel.HorizontalAlignment = 'right';
            app.MeasuretimesEditFieldLabel.Position = [19 113 95 22];
            app.MeasuretimesEditFieldLabel.Text = 'Measure time (s)';

            % Create MeasuretimesEditField
            app.MeasuretimesEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.MeasuretimesEditField.Position = [139 113 102 22];
            app.MeasuretimesEditField.Value = 0.2;

            % Create ControlPanel_2
            app.ControlPanel_2 = uipanel(app.Tab);
            app.ControlPanel_2.Title = 'Control';
            app.ControlPanel_2.Position = [15 95 265 247];

            % Create TimetofinishLabel
            app.TimetofinishLabel = uilabel(app.ControlPanel_2);
            app.TimetofinishLabel.Position = [22 6 86 22];
            app.TimetofinishLabel.Text = 'Time to finish : ';

            % Create CyclecountEditFieldLabel
            app.CyclecountEditFieldLabel = uilabel(app.ControlPanel_2);
            app.CyclecountEditFieldLabel.HorizontalAlignment = 'right';
            app.CyclecountEditFieldLabel.Position = [14 187 68 22];
            app.CyclecountEditFieldLabel.Text = 'Cycle count';

            % Create CyclecountEditField
            app.CyclecountEditField = uieditfield(app.ControlPanel_2, 'text');
            app.CyclecountEditField.InputType = 'digits';
            app.CyclecountEditField.HorizontalAlignment = 'right';
            app.CyclecountEditField.Position = [148 187 100 22];
            app.CyclecountEditField.Value = '1';

            % Create DelaypercyclesEditFieldLabel
            app.DelaypercyclesEditFieldLabel = uilabel(app.ControlPanel_2);
            app.DelaypercyclesEditFieldLabel.HorizontalAlignment = 'right';
            app.DelaypercyclesEditFieldLabel.Position = [15 152 104 22];
            app.DelaypercyclesEditFieldLabel.Text = 'Delay per cycle (s)';

            % Create DelaypercyclesEditField
            app.DelaypercyclesEditField = uieditfield(app.ControlPanel_2, 'text');
            app.DelaypercyclesEditField.InputType = 'digits';
            app.DelaypercyclesEditField.HorizontalAlignment = 'right';
            app.DelaypercyclesEditField.Position = [149 152 100 22];
            app.DelaypercyclesEditField.Value = '1';

            % Create HysteresisCheckBox
            app.HysteresisCheckBox = uicheckbox(app.ControlPanel_2);
            app.HysteresisCheckBox.Text = 'Hysteresis';
            app.HysteresisCheckBox.Position = [19 118 78 22];

            % Create StartButton
            app.StartButton = uibutton(app.ControlPanel_2, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Position = [19 70 71 36];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.ControlPanel_2, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [101 70 72 36];
            app.StopButton.Text = 'Stop';

            % Create ResistanceOhmsLabel
            app.ResistanceOhmsLabel = uilabel(app.ControlPanel_2);
            app.ResistanceOhmsLabel.Position = [21 35 118 22];
            app.ResistanceOhmsLabel.Text = 'Resistance : -- Ohms';

            % Create PlotButton
            app.PlotButton = uibutton(app.ControlPanel_2, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);
            app.PlotButton.Position = [183 70 72 36];
            app.PlotButton.Text = 'Plot';
            app.PlotButton.Enable = 'off';

            % Create RealTimePlotCheckBox
            app.RealTimePlotCheckBox = uicheckbox(app.ControlPanel_2);
            app.RealTimePlotCheckBox.Text = 'Real Time Plot';
            app.RealTimePlotCheckBox.Position = [154 35 100 22];

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.Tab);
            app.ButtonGroup.Title = 'Button Group';
            app.ButtonGroup.Position = [16 13 262 68];

            % Create ReturntoZeroButton
            app.ReturntoZeroButton = uiradiobutton(app.ButtonGroup);
            app.ReturntoZeroButton.Text = 'Return to Zero';
            app.ReturntoZeroButton.Position = [22 11 99 22];
            app.ReturntoZeroButton.Value = true;

            % Create NormalButton
            app.NormalButton = uiradiobutton(app.ButtonGroup);
            app.NormalButton.Text = 'Normal';
            app.NormalButton.Position = [165 11 65 22];

            % Create Tab2_2
            app.Tab2_2 = uitab(app.TabGroup2);
            app.Tab2_2.Title = 'Tab2';

            % Create ConnectionPanel
            app.ConnectionPanel = uipanel(app.Tab2_2);
            app.ConnectionPanel.Title = 'Connection';
            app.ConnectionPanel.Position = [13 465 265 257];

            % Create SupplyAddrEditFieldLabel
            app.SupplyAddrEditFieldLabel = uilabel(app.ConnectionPanel);
            app.SupplyAddrEditFieldLabel.HorizontalAlignment = 'right';
            app.SupplyAddrEditFieldLabel.Position = [13 201 70 22];
            app.SupplyAddrEditFieldLabel.Text = 'Supply Addr';

            % Create SupplyAddrEditField
            app.SupplyAddrEditField = uieditfield(app.ConnectionPanel, 'numeric');
            app.SupplyAddrEditField.Position = [136 201 100 22];
            app.SupplyAddrEditField.Value = 6;

            % Create GaussmeterAddrEditField
            app.GaussmeterAddrEditField = uieditfield(app.ConnectionPanel, 'numeric');
            app.GaussmeterAddrEditField.Position = [135 135 100 22];

            % Create DropDown
            app.DropDown = uidropdown(app.ConnectionPanel);
            app.DropDown.Items = {'Supply + Source meter', 'Supply + Gaussmeter', 'All instruments'};
            app.DropDown.ValueChangedFcn = createCallbackFcn(app, @DropDownValueChanged, true);
            app.DropDown.ClickedFcn = createCallbackFcn(app, @DropDownClicked, true);
            app.DropDown.Position = [17 93 219 22];
            app.DropDown.Value = 'Supply + Source meter';

            % Create GaussmeterAddrEditFieldLabel
            app.GaussmeterAddrEditFieldLabel = uilabel(app.ConnectionPanel);
            app.GaussmeterAddrEditFieldLabel.HorizontalAlignment = 'right';
            app.GaussmeterAddrEditFieldLabel.Position = [13 135 102 22];
            app.GaussmeterAddrEditFieldLabel.Text = 'Gaussmeter  Addr';

            % Create SupplyAddrEditFieldLabel_2
            app.SupplyAddrEditFieldLabel_2 = uilabel(app.ConnectionPanel);
            app.SupplyAddrEditFieldLabel_2.HorizontalAlignment = 'right';
            app.SupplyAddrEditFieldLabel_2.Position = [13 169 104 22];
            app.SupplyAddrEditFieldLabel_2.Text = 'Source Meter addr';

            % Create SupplyAddrEditField_2
            app.SupplyAddrEditField_2 = uieditfield(app.ConnectionPanel, 'numeric');
            app.SupplyAddrEditField_2.Position = [136 169 100 22];
            app.SupplyAddrEditField_2.Value = 24;

            % Create Label
            app.Label = uilabel(app.ConnectionPanel);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [62 93 25 22];
            app.Label.Text = '';

            % Create ConnectButton
            app.ConnectButton = uibutton(app.ConnectionPanel, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.Position = [18 37 100 33];
            app.ConnectButton.Text = 'Connect';

            % Create DisconnectButton
            app.DisconnectButton = uibutton(app.ConnectionPanel, 'push');
            app.DisconnectButton.ButtonPushedFcn = createCallbackFcn(app, @DisconnectButtonPushed, true);
            app.DisconnectButton.Position = [152 37 100 33];
            app.DisconnectButton.Text = 'Disconnect';

            % Create StatusLabel
            app.StatusLabel = uilabel(app.ConnectionPanel);
            app.StatusLabel.Position = [112 10 39 22];
            app.StatusLabel.Text = 'Status';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = RevisedMagneticStationController

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            app.StopFlag = true;
            app.safeShutdown();
            DisconnectButtonPushed(app, []);

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end