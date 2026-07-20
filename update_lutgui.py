import re

with open('LUT_based/LUTGUI.m', 'r') as f:
    lut_content = f.read()

with open('measurement_based/newerui.m', 'r') as f:
    newerui_content = f.read()

# We need to inject the properties block from newerui, but without Gaussmeter
properties_block = """
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
        hLine3
        LUT_Current = []
        LUT_Field = []
    end
"""

# Extract the methods (Access = private) block from lut_content
methods_pattern = re.compile(r'(\s+% Callbacks that handle component events\s+methods \(Access = private\).*?)(\s+% Component initialization)', re.DOTALL)
methods_match = methods_pattern.search(lut_content)
if not methods_match:
    print("Could not find methods block in LUTGUI.m")
    exit(1)

# Now we will define the new methods
new_methods = """
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
                    uialert(app.UIFigure, sprintf('Data successfully saved to:\\n%s', fullPath), 'Save Complete', 'Icon', 'success');
                catch ME
                    uialert(app.UIFigure, ['Failed to save Excel file: ' ME.message], 'Save Error', 'Icon', 'warning');
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

            title(app.UIAxes_2, 'Magnetic Field vs Current');
            xlabel(app.UIAxes_2, 'Input Current (A)');
            ylabel(app.UIAxes_2, 'Interpolated Magnetic Field (G)');

            cla(app.UIAxes);
            cla(app.UIAxes2);
            cla(app.UIAxes_2);
            app.hLine1 = plot(app.UIAxes, nan, nan, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
            xlim(app.UIAxes, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);
            app.hLine2 = plot(app.UIAxes2, nan, nan, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
            app.hLine3 = plot(app.UIAxes_2, nan, nan, '-go', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
            xlim(app.UIAxes_2, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);

            app.CurrData = [];
            app.ResData = [];
            app.FieldData = [];
            app.SavetoExcelButton.Enable = 'off';

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
                        set(app.hLine3, 'XData', app.CurrData, 'YData', app.FieldData);
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
                set(app.hLine3, 'XData', app.CurrData, 'YData', app.FieldData);
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
"""

# Replace the methods block
new_lut_content = lut_content[:methods_match.start()] + properties_block + new_methods + lut_content[methods_match.end(2):]

# Find where ChooseLUTButton is created to add the callback
button_creation_pattern = r"(app\.ChooseLUTButton = uibutton\(app\.LUTPanel, 'push'\);\s+app\.ChooseLUTButton\.Position = \[\d+ \d+ \d+ \d+\];)"
new_lut_content = re.sub(button_creation_pattern, r"\1\n            app.ChooseLUTButton.ButtonPushedFcn = createCallbackFcn(app, @ChooseLUTButtonPushed, true);", new_lut_content)

# Update safe shutdown call in delete()
delete_pattern = r"(% Code that executes before app deletion\s+function delete\(app\))"
delete_replacement = r"\1\n            app.StopFlag = true;\n            app.safeShutdown();\n            DisconnectButtonPushed(app, []);\n"
new_lut_content = re.sub(delete_pattern, delete_replacement, new_lut_content)

with open('LUT_based/LUTGUI.m', 'w') as f:
    f.write(new_lut_content)

print("Successfully generated and updated LUT_based/LUTGUI.m")
