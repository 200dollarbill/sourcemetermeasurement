classdef LUTGUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        LUTPanel                       matlab.ui.container.Panel
        MRRatiomr_ratioLabel           matlab.ui.control.Label
        FilefilenameLabel_3            matlab.ui.control.Label
        StartCurrentAEditFieldLabel_7  matlab.ui.control.Label
        StartCurrentAEditFieldLabel_6  matlab.ui.control.Label
        Stepsizestep_sizeLabel_2       matlab.ui.control.Label
        Datapointsdata_pointsLabel     matlab.ui.control.Label
        ChooseLUTButton                matlab.ui.control.Button
        ControlPanel                   matlab.ui.container.Panel
        RealTimePlotCheckBox           matlab.ui.control.CheckBox
        PlotButton                     matlab.ui.control.Button
        ResistanceOhmsLabel            matlab.ui.control.Label
        StopButton                     matlab.ui.control.Button
        StartButton                    matlab.ui.control.Button
        SettingsPanel                  matlab.ui.container.Panel
        HysteresisCheckBox             matlab.ui.control.CheckBox
        FilenameEditField_2            matlab.ui.control.EditField
        FilenameEditField_2Label       matlab.ui.control.Label
        SteptimesEditField             matlab.ui.control.NumericEditField
        SteptimesEditFieldLabel        matlab.ui.control.Label
        SavetoExcelButton              matlab.ui.control.Button
        SaveToFigureButton             matlab.ui.control.Button
        SupplyAddrEditField_4          matlab.ui.control.NumericEditField
        SupplyAddrEditFieldLabel_3     matlab.ui.control.Label
        StartCurrentAEditField         matlab.ui.control.NumericEditField
        StartCurrentAEditFieldLabel    matlab.ui.control.Label
        ConnectionPanel                matlab.ui.container.Panel
        DropDown                       matlab.ui.control.DropDown
        Label                          matlab.ui.control.Label
        StatusLabel                    matlab.ui.control.Label
        DisconnectButton               matlab.ui.control.Button
        ConnectButton                  matlab.ui.control.Button
        SupplyAddrEditField_2          matlab.ui.control.NumericEditField
        SupplyAddrEditFieldLabel_2     matlab.ui.control.Label
        SupplyAddrEditField            matlab.ui.control.NumericEditField
        SupplyAddrEditFieldLabel       matlab.ui.control.Label
        TabGroup                       matlab.ui.container.TabGroup
        Tab1                           matlab.ui.container.Tab
        UIAxes                         matlab.ui.control.UIAxes
        Tab2                           matlab.ui.container.Tab
        UIAxes2                        matlab.ui.control.UIAxes
    end
    % Non-UI properties for hardware handles and sweep data
    properties (Access = private)
        Kepco
        SMU
        StopFlag = false
        CurrData = []
        ResData = []
        FieldData = []
        hLine1
        hLine2
        LUT_Current = []
        LUT_Field = []
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: ChooseLUTButton
        function ChooseLUTButtonPushed(app, event)
            [file, path] = uigetfile({'*.xlsx';'*.xls';'*.csv'}, 'Select LUT File');
            if isequal(file,0)
                return;
            end
            
            try
                filepath = fullfile(path, file);
                T = readtable(filepath);
                
                % Assume column 1 is Current, column 2 is Field
                app.LUT_Current = T{:, 1};
                app.LUT_Field = T{:, 2};
                
                % Update Labels
                app.FilefilenameLabel_3.Text = sprintf('File : %s', file);
                app.Datapointsdata_pointsLabel.Text = sprintf('Data points : %d', length(app.LUT_Current));
                app.StartCurrentAEditFieldLabel_6.Text = sprintf('Max Current : %.3f', max(app.LUT_Current));
                app.StartCurrentAEditFieldLabel_7.Text = sprintf('Min Current : %.3f', min(app.LUT_Current));
                if length(app.LUT_Current) > 1
                    app.Stepsizestep_sizeLabel_2.Text = sprintf('Step size : %.3f', abs(app.LUT_Current(2) - app.LUT_Current(1)));
                end
                
            catch ME
                uialert(app.UIFigure, ['Failed to load LUT: ' ME.message], 'Error');
            end
        end

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            try
                app.StatusLabel.Text = 'Connecting...'; drawnow;
                try delete(instrfind); catch; end

                % power supply connection
                app.Kepco = gpib('adlink', 0, app.SupplyAddrEditField.Value);
                app.Kepco.Timeout = 5;
                fopen(app.Kepco);
                % power supply
                fprintf(app.Kepco, 'FUNC:MODE CURR');
                fprintf(app.Kepco, 'VOLT 20.0');
                fprintf(app.Kepco, 'CURR 0.0');

                % source meter connection
                app.SMU = gpib('adlink', 0, app.SupplyAddrEditField_2.Value);
                app.SMU.Timeout = 5;
                fopen(app.SMU);
                
                fprintf(app.SMU, "*RST");
                pause(2);
                fprintf(app.SMU, ":SENS:FUNC 'RES'");
                fprintf(app.SMU, ":SENS:RES:OCOM ON"); % Offset Compensated Ohms
                fprintf(app.SMU, ":FORM:ELEM RES");

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

        % saving
        function SavetoExcelButtonPushed(app, event)
            if ~isempty(app.CurrData)
                defaultName = sprintf('%s.xlsx', app.FilenameEditField_2.Value);
                [file, path] = uiputfile('*.xlsx', 'Save Data As', defaultName);
                if isequal(file, 0) || isequal(path, 0)
                    return;
                end

                fullPath = fullfile(path, file);

                % table creation
                if length(app.ResData) == length(app.CurrData) && length(app.FieldData) == length(app.CurrData)
                    R = app.ResData(:);
                    H = app.FieldData(:);
                    R_min = min(R);
                    MR_Ratio_Percent = (R - R_min) ./ R_min * 100;
                    
                    if length(R) > 1 && length(H) > 1
                        total_sensitivity = (max(R) - min(R)) / (max(H) - min(H));
                        Sensitivity_Ohms_per_G = repmat(total_sensitivity, size(R));
                        Sensitivity_Ohms_per_G(~isfinite(Sensitivity_Ohms_per_G)) = 0; % Handle div by 0
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

                try
                    writetable(T, fullPath);
                    uialert(app.UIFigure, sprintf('Data successfully saved to:\n%s', fullPath), 'Save Complete', 'Icon', 'success');
                catch ME
                    uialert(app.UIFigure, ['Failed to save Excel file: ' ME.message], 'Save Error', 'Icon', 'warning');
                end
            end
        end

        % Button pushed function: SaveToFigureButton
        function SaveToFigureButtonPushed(app, event)
            if isempty(app.CurrData)
                return;
            end
            defaultName = sprintf('%s.png', app.FilenameEditField_2.Value);
            [file, path] = uiputfile({'*.png', 'PNG Image (*.png)'; '*.fig', 'MATLAB Figure (*.fig)'}, 'Save Figures As', defaultName);
            if isequal(file, 0) || isequal(path, 0)
                return;
            end
            fullPath = fullfile(path, file);
            
            try
                % Create a new figure to hold the subplots (invisible while building)
                f = figure('Name', 'Exported Plots', 'NumberTitle', 'off', 'Visible', 'off');
                f.Position = [100 100 800 400];
                
                % Replot axes 1
                ax1 = subplot(1,2,1, 'Parent', f);
                if ~isempty(app.hLine1) && isvalid(app.hLine1)
                    plot(ax1, app.hLine1.XData, app.hLine1.YData, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
                else
                    plot(ax1, app.CurrData, app.ResData, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
                end
                title(ax1, app.UIAxes.Title.String);
                xlabel(ax1, app.UIAxes.XLabel.String);
                ylabel(ax1, app.UIAxes.YLabel.String);
                if ~isempty(app.UIAxes.XLim) && app.UIAxes.XLim(2) > app.UIAxes.XLim(1)
                    xlim(ax1, app.UIAxes.XLim);
                end
                
                % Replot axes 2
                ax2 = subplot(1,2,2, 'Parent', f);
                if ~isempty(app.hLine2) && isvalid(app.hLine2)
                    plot(ax2, app.hLine2.XData, app.hLine2.YData, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
                else
                    plot(ax2, app.FieldData, app.ResData, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
                end
                title(ax2, app.UIAxes2.Title.String);
                xlabel(ax2, app.UIAxes2.XLabel.String);
                ylabel(ax2, app.UIAxes2.YLabel.String);
                if ~isempty(app.UIAxes2.XLim) && app.UIAxes2.XLim(2) > app.UIAxes2.XLim(1)
                    xlim(ax2, app.UIAxes2.XLim);
                end
                
                % Set visible immediately before saving so .fig file loads visibly
                f.Visible = 'on';
                drawnow;
                
                [~, ~, ext] = fileparts(fullPath);
                if strcmpi(ext, '.fig')
                    savefig(f, fullPath);
                else
                    exportgraphics(f, fullPath, 'Resolution', 300);
                end
                close(f);
                
                uialert(app.UIFigure, sprintf('Figures successfully saved to:\n%s', fullPath), 'Save Complete', 'Icon', 'success');
            catch ME
                uialert(app.UIFigure, ['Failed to save figure: ' ME.message], 'Save Error', 'Icon', 'warning');
                if exist('f', 'var') && isvalid(f)
                    close(f);
                end
            end
        end

        % Main start button
        function StartButtonPushed(app, event)
            if isempty(app.LUT_Current) || isempty(app.LUT_Field)
                uialert(app.UIFigure, 'Please load a LUT file first.', 'Missing LUT', 'Icon', 'warning');
                return;
            end
            app.StartButton.Enable = 'off';
            app.StopButton.Enable = 'on';
            app.DisconnectButton.Enable = 'off';
            app.PlotButton.Enable = 'off';
            app.StopFlag = false;
            
            s_I = app.StartCurrentAEditField.Value;
            e_I = app.SupplyAddrEditField_4.Value;

            % Restrict to LUT boundaries
            max_I = max(app.LUT_Current);
            min_I = min(app.LUT_Current);
            if s_I > max_I
                s_I = max_I; app.StartCurrentAEditField.Value = s_I;
            elseif s_I < min_I
                s_I = min_I; app.StartCurrentAEditField.Value = s_I;
            end
            if e_I > max_I
                e_I = max_I; app.SupplyAddrEditField_4.Value = e_I;
            elseif e_I < min_I
                e_I = min_I; app.SupplyAddrEditField_4.Value = e_I;
            end

            % Sweep steps
            step_I = abs(app.LUT_Current(2) - app.LUT_Current(1)); % Default to LUT step size
            if step_I == 0; step_I = 0.1; end
            pause_T = app.SteptimesEditField.Value;

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

            % plots titles
            title(app.UIAxes, 'Resistance vs Current');
            xlabel(app.UIAxes, 'Input Current (A)');
            ylabel(app.UIAxes, 'Measured Resistance (Ohms)');
            
            title(app.UIAxes2, 'Resistance vs Magnetic Field');
            xlabel(app.UIAxes2, 'Interpolated Magnetic Field (G)');
            ylabel(app.UIAxes2, 'Measured Resistance (Ohms)');

            cla(app.UIAxes);
            cla(app.UIAxes2);
            app.hLine1 = plot(app.UIAxes, nan, nan, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
            xlim(app.UIAxes, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);
            app.hLine2 = plot(app.UIAxes2, nan, nan, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');

            app.CurrData = [];
            app.ResData = [];
            app.FieldData = [];
            app.SavetoExcelButton.Enable = 'off';
            app.SaveToFigureButton.Enable = 'off';

            try
                % output
                fprintf(app.Kepco, 'OUTP ON');
                if ~isempty(app.SMU)
                    fprintf(app.SMU, ':OUTP ON');
                end

                fprintf(app.Kepco, sprintf('CURR %.3f', s_I))
                pause(1);

                for i = 1:length(I_steps)
                    if app.StopFlag; break; end

                    % current setup
                    target_I = I_steps(i);
                    fprintf(app.Kepco, sprintf('CURR %.3f', target_I));
                    pause(pause_T);

                    if i == 1
                        pause(0.5);
                    end

                    app.CurrData(end+1) = target_I;

                    % source meter reading
                    if ~isempty(app.SMU)
                        fprintf(app.SMU, ':READ?');
                        res_str = fscanf(app.SMU);
                        res_val = str2double(res_str);
                        app.ResData(end+1) = res_val;

                        app.ResistanceOhmsLabel.Text = sprintf('Resistance : %.4f Ohms', res_val);
                    end

                    % Interpolate Magnetic Field from LUT
                    field_val = interp1(app.LUT_Current, app.LUT_Field, target_I, 'linear', 'extrap');
                    app.FieldData(end+1) = field_val;

                    if app.RealTimePlotCheckBox.Value
                        if ~isempty(app.ResData)
                            set(app.hLine1, 'XData', app.CurrData, 'YData', app.ResData);
                            set(app.hLine2, 'XData', app.FieldData, 'YData', app.ResData);
                        end
                    end
                    pause(0.05);
                    drawnow limitrate;
                end

                % MR Ratio Update
                if ~isempty(app.ResData)
                    R_min = min(app.ResData);
                    R_max = max(app.ResData);
                    MR = (R_max - R_min) / R_min * 100;
                    app.MRRatiomr_ratioLabel.Text = sprintf('MR Ratio : %.2f %%', MR);
                end

            catch ME
                uialert(app.UIFigure, ['Error during sweep: ', ME.message], 'Error');
            end

            app.safeShutdown();
            app.StartButton.Enable = 'on';
            app.StopButton.Enable = 'off';
            app.DisconnectButton.Enable = 'on';

            if ~isempty(app.CurrData)
                app.SavetoExcelButton.Enable = 'on';
                app.SaveToFigureButton.Enable = 'on';
                if ~app.RealTimePlotCheckBox.Value
                    app.PlotButton.Enable = 'on';
                end
                beep; pause(0.3); beep;
                uialert(app.UIFigure, 'The measurement sequence has finished.', 'Measurement Finished', 'Icon', 'success');
            end
        end

        % Button pushed function: PlotButton
        function PlotButtonPushed(app, event)
            if ~isempty(app.ResData) && length(app.CurrData) == length(app.ResData)
                set(app.hLine1, 'XData', app.CurrData, 'YData', app.ResData);
                set(app.hLine2, 'XData', app.FieldData, 'YData', app.ResData);
            end
            if length(app.CurrData) == length(app.FieldData)
            end
            drawnow;
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.StopFlag = true;
        end

        % Button pushed function: DisconnectButton
        function DisconnectButtonPushed(app, event)
            app.StopFlag = true; % stop any running sweeps
            app.safeShutdown();

            if ~isempty(app.SMU) && isvalid(app.SMU)
                try fclose(app.SMU); delete(app.SMU); catch; end
            end
            if ~isempty(app.Kepco) && isvalid(app.Kepco)
                try fclose(app.Kepco); delete(app.Kepco); catch; end
            end
            app.SMU = []; app.Kepco = [];

            app.StatusLabel.Text = 'Offline';
            app.StatusLabel.FontColor = 'r';
            app.ConnectButton.Enable = 'on';
            app.DisconnectButton.Enable = 'off';
            app.StartButton.Enable = 'off';
        end

        % Clicked callback: DropDown
        function DropDownClicked(app, event)
            item = event.InteractionInformation.Item;
        end

        % Value changed function: DropDown
        function DropDownValueChanged(app, event)
            value = app.DropDown.Value;
        end

        % switch off
        function safeShutdown(app)
            % supply poweroff
            if ~isempty(app.Kepco) && isvalid(app.Kepco)
                try
                    fprintf(app.Kepco, 'CURR 0.0');
                    pause(0.2);
                    fprintf(app.Kepco, 'OUTP OFF');
                catch
                end
            end
            % source meter poweroff
            if ~isempty(app.SMU) && isvalid(app.SMU)
                try
                    fprintf(app.SMU, ':OUTP OFF');
                catch
                end
            end
        end
    end

    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1147 797];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [310 38 820 732];

            % Create Tab1
            app.Tab1 = uitab(app.TabGroup);
            app.Tab1.Title = 'Tab1';

            % Create UIAxes
            app.UIAxes = uiaxes(app.Tab1);
            title(app.UIAxes, 'Resistance vs Current')
            xlabel(app.UIAxes, 'Input Current (A)')
            ylabel(app.UIAxes, 'Measured Resistance (Ohms)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [14 22 782 664];

            % Create Tab2
            app.Tab2 = uitab(app.TabGroup);
            app.Tab2.Title = 'Tab2';

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.Tab2);
            title(app.UIAxes2, 'Resistance vs Magnetic Field')
            xlabel(app.UIAxes2, 'Measured Resistance (Ohms)')
            ylabel(app.UIAxes2, 'Measured Magnetic Field Strength (G)')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [15 22 781 664];

            % Create ConnectionPanel
            app.ConnectionPanel = uipanel(app.UIFigure);
            app.ConnectionPanel.Title = 'Connection';
            app.ConnectionPanel.Position = [25 548 265 222];

            % Create SupplyAddrEditFieldLabel
            app.SupplyAddrEditFieldLabel = uilabel(app.ConnectionPanel);
            app.SupplyAddrEditFieldLabel.HorizontalAlignment = 'right';
            app.SupplyAddrEditFieldLabel.Position = [23 155 70 22];
            app.SupplyAddrEditFieldLabel.Text = 'Supply Addr';

            % Create SupplyAddrEditField
            app.SupplyAddrEditField = uieditfield(app.ConnectionPanel, 'numeric');
            app.SupplyAddrEditField.Position = [146 155 100 22];
            app.SupplyAddrEditField.Value = 6;

            % Create SupplyAddrEditFieldLabel_2
            app.SupplyAddrEditFieldLabel_2 = uilabel(app.ConnectionPanel);
            app.SupplyAddrEditFieldLabel_2.HorizontalAlignment = 'right';
            app.SupplyAddrEditFieldLabel_2.Position = [24 123 104 22];
            app.SupplyAddrEditFieldLabel_2.Text = 'Source Meter addr';

            % Create SupplyAddrEditField_2
            app.SupplyAddrEditField_2 = uieditfield(app.ConnectionPanel, 'numeric');
            app.SupplyAddrEditField_2.Position = [146 123 100 22];
            app.SupplyAddrEditField_2.Value = 24;

            % Create ConnectButton
            app.ConnectButton = uibutton(app.ConnectionPanel, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.Position = [25 43 100 33];
            app.ConnectButton.Text = 'Connect';

            % Create DisconnectButton
            app.DisconnectButton = uibutton(app.ConnectionPanel, 'push');
            app.DisconnectButton.ButtonPushedFcn = createCallbackFcn(app, @DisconnectButtonPushed, true);
            app.DisconnectButton.Position = [150 43 97 33];
            app.DisconnectButton.Text = 'Disconnect';

            % Create StatusLabel
            app.StatusLabel = uilabel(app.ConnectionPanel);
            app.StatusLabel.Position = [117 10 39 22];
            app.StatusLabel.Text = 'Status';

            % Create Label
            app.Label = uilabel(app.ConnectionPanel);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [58 97 25 22];
            app.Label.Text = '';

            % Create DropDown
            app.DropDown = uidropdown(app.ConnectionPanel);
            app.DropDown.Items = {'Supply + Source meter'};
            app.DropDown.ValueChangedFcn = createCallbackFcn(app, @DropDownValueChanged, true);
            app.DropDown.ClickedFcn = createCallbackFcn(app, @DropDownClicked, true);
            app.DropDown.Position = [24 86 223 22];
            app.DropDown.Value = 'Supply + Source meter';

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.UIFigure);
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.Position = [25 153 264 228];

            % Create StartCurrentAEditFieldLabel
            app.StartCurrentAEditFieldLabel = uilabel(app.SettingsPanel);
            app.StartCurrentAEditFieldLabel.Position = [23 173 93 22];
            app.StartCurrentAEditFieldLabel.Text = 'Start Current (A)';

            % Create StartCurrentAEditField
            app.StartCurrentAEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.StartCurrentAEditField.Position = [142 173 101 22];
            app.StartCurrentAEditField.Value = -1;

            % Create SupplyAddrEditFieldLabel_3
            app.SupplyAddrEditFieldLabel_3 = uilabel(app.SettingsPanel);
            app.SupplyAddrEditFieldLabel_3.Position = [23 141 89 22];
            app.SupplyAddrEditFieldLabel_3.Text = 'End Current (A)';

            % Create SupplyAddrEditField_4
            app.SupplyAddrEditField_4 = uieditfield(app.SettingsPanel, 'numeric');
            app.SupplyAddrEditField_4.Position = [142 141 101 22];
            app.SupplyAddrEditField_4.Value = 1;

            % Create SavetoExcelButton
            app.SavetoExcelButton = uibutton(app.SettingsPanel, 'push');
            app.SavetoExcelButton.ButtonPushedFcn = createCallbackFcn(app, @SavetoExcelButtonPushed, true);
            app.SavetoExcelButton.Position = [18 11 105 33];
            app.SavetoExcelButton.Text = 'Save Excel';

            % Create SaveToFigureButton
            app.SaveToFigureButton = uibutton(app.SettingsPanel, 'push');
            app.SaveToFigureButton.ButtonPushedFcn = createCallbackFcn(app, @SaveToFigureButtonPushed, true);
            app.SaveToFigureButton.Position = [133 11 105 33];
            app.SaveToFigureButton.Text = 'Save Fig';

            % Create SteptimesEditFieldLabel
            app.SteptimesEditFieldLabel = uilabel(app.SettingsPanel);
            app.SteptimesEditFieldLabel.Position = [23 112 73 22];
            app.SteptimesEditFieldLabel.Text = 'Step time (s)';

            % Create SteptimesEditField
            app.SteptimesEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.SteptimesEditField.Position = [142 112 101 22];
            app.SteptimesEditField.Value = 0.2;

            % Create FilenameEditField_2Label
            app.FilenameEditField_2Label = uilabel(app.SettingsPanel);
            app.FilenameEditField_2Label.Position = [23 79 54 22];
            app.FilenameEditField_2Label.Text = 'Filename';

            % Create FilenameEditField_2
            app.FilenameEditField_2 = uieditfield(app.SettingsPanel, 'text');
            app.FilenameEditField_2.HorizontalAlignment = 'right';
            app.FilenameEditField_2.Position = [142 79 101 22];
            app.FilenameEditField_2.Value = 'Data';

            % Create HysteresisCheckBox
            app.HysteresisCheckBox = uicheckbox(app.SettingsPanel);
            app.HysteresisCheckBox.Text = 'Hysteresis';
            app.HysteresisCheckBox.Position = [23 54 78 22];

            % Create ControlPanel
            app.ControlPanel = uipanel(app.UIFigure);
            app.ControlPanel.Title = 'Control';
            app.ControlPanel.Position = [25 39 265 107];

            % Create StartButton
            app.StartButton = uibutton(app.ControlPanel, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Position = [17 38 71 36];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.ControlPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [99 38 72 36];
            app.StopButton.Text = 'Stop';

            % Create ResistanceOhmsLabel
            app.ResistanceOhmsLabel = uilabel(app.ControlPanel);
            app.ResistanceOhmsLabel.Position = [19 6 118 22];
            app.ResistanceOhmsLabel.Text = 'Resistance : -- Ohms';

            % Create PlotButton
            app.PlotButton = uibutton(app.ControlPanel, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);
            app.PlotButton.Position = [181 38 72 36];
            app.PlotButton.Text = 'Plot';
            app.PlotButton.Enable = 'off';

            % Create RealTimePlotCheckBox
            app.RealTimePlotCheckBox = uicheckbox(app.ControlPanel);
            app.RealTimePlotCheckBox.Text = 'Real Time Plot';
            app.RealTimePlotCheckBox.Position = [152 6 100 22];

            % Create LUTPanel
            app.LUTPanel = uipanel(app.UIFigure);
            app.LUTPanel.Title = 'LUT';
            app.LUTPanel.Position = [26 400 265 132];

            % Create ChooseLUTButton
            app.ChooseLUTButton = uibutton(app.LUTPanel, 'push');
            app.ChooseLUTButton.Position = [20 67 91 32];
            app.ChooseLUTButton.ButtonPushedFcn = createCallbackFcn(app, @ChooseLUTButtonPushed, true);
            app.ChooseLUTButton.Text = 'Choose LUT';

            % Create Datapointsdata_pointsLabel
            app.Datapointsdata_pointsLabel = uilabel(app.LUTPanel);
            app.Datapointsdata_pointsLabel.Position = [20 13 138 22];
            app.Datapointsdata_pointsLabel.Text = 'Data points : data_points';

            % Create Stepsizestep_sizeLabel_2
            app.Stepsizestep_sizeLabel_2 = uilabel(app.LUTPanel);
            app.Stepsizestep_sizeLabel_2.Position = [141 58 115 22];
            app.Stepsizestep_sizeLabel_2.Text = 'Step size : step_size';

            % Create StartCurrentAEditFieldLabel_6
            app.StartCurrentAEditFieldLabel_6 = uilabel(app.LUTPanel);
            app.StartCurrentAEditFieldLabel_6.Position = [141 36 148 22];
            app.StartCurrentAEditFieldLabel_6.Text = 'Max Current : max_current';

            % Create StartCurrentAEditFieldLabel_7
            app.StartCurrentAEditFieldLabel_7 = uilabel(app.LUTPanel);
            app.StartCurrentAEditFieldLabel_7.Position = [141 13 141 22];
            app.StartCurrentAEditFieldLabel_7.Text = 'Min Current : min_current';

            % Create FilefilenameLabel_3
            app.FilefilenameLabel_3 = uilabel(app.LUTPanel);
            app.FilefilenameLabel_3.Position = [20 35 80 22];
            app.FilefilenameLabel_3.Text = 'File : filename';

            % Create MRRatiomr_ratioLabel
            app.MRRatiomr_ratioLabel = uilabel(app.LUTPanel);
            app.MRRatiomr_ratioLabel.Position = [141 79 109 22];
            app.MRRatiomr_ratioLabel.Text = 'MR Ratio : mr_ratio';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = LUTGUI

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