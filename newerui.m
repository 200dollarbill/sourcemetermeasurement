classdef newerui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        ControlPanel                   matlab.ui.container.Panel
        RealTimePlotCheckBox           matlab.ui.control.CheckBox
        PlotButton                     matlab.ui.control.Button
        ResistanceOhmsLabel            matlab.ui.control.Label
        StopButton                     matlab.ui.control.Button
        StartButton                    matlab.ui.control.Button
        SettingsPanel                  matlab.ui.container.Panel
        HysteresisCheckBox             matlab.ui.control.CheckBox
        StartCurrentAEditField_3       matlab.ui.control.NumericEditField
        StartCurrentAEditFieldLabel_3  matlab.ui.control.Label
        StartCurrentAEditField_2       matlab.ui.control.NumericEditField
        StartCurrentAEditFieldLabel_2  matlab.ui.control.Label
        FilenameEditField_2            matlab.ui.control.EditField
        FilenameEditField_2Label       matlab.ui.control.Label
        SteptimesEditField             matlab.ui.control.NumericEditField
        SteptimesEditFieldLabel        matlab.ui.control.Label
        SavetoExcelButton              matlab.ui.control.Button
        SaveToFigureButton             matlab.ui.control.Button
        StepsizeAEditField             matlab.ui.control.NumericEditField
        StepsizeAEditFieldLabel        matlab.ui.control.Label
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
        GaussmeterAddrEditField        matlab.ui.control.NumericEditField
        GaussmeterAddrEditFieldLabel   matlab.ui.control.Label
        SupplyAddrEditField_2          matlab.ui.control.NumericEditField
        SupplyAddrEditFieldLabel_2     matlab.ui.control.Label
        SupplyAddrEditField            matlab.ui.control.NumericEditField
        SupplyAddrEditFieldLabel       matlab.ui.control.Label
        TabGroup                       matlab.ui.container.TabGroup
        Tab1                           matlab.ui.container.Tab
        UIAxes                         matlab.ui.control.UIAxes
        Tab2                           matlab.ui.container.Tab
        UIAxes2                        matlab.ui.control.UIAxes
        Tab3                           matlab.ui.container.Tab
        UIAxes_2                       matlab.ui.control.UIAxes
    end

    % Non-UI properties for hardware handles and sweep data
    properties (Access = private)
        Kepco
        SMU
        Gaussmeter
        StopFlag = false
        CurrData = []
        ResData = []
        FieldData = []
        hLine1
        hLine2
        hLine3
    end

    % Callbacks that handle component events
    methods (Access = private)

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
                fprintf(app.SMU, ":FORM:ELEM RES");

            case 'Supply + Gaussmeter'
                % Gaussmeter connection
                app.Gaussmeter = gpib('adlink', 0, app.GaussmeterAddrEditField.Value);
                app.Gaussmeter.Timeout = 5;
                fopen(app.Gaussmeter);

                % add code for gaussmeter SCPI setup
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
                fprintf(app.SMU, ":FORM:ELEM RES");

                % gaussmeter
                app.Gaussmeter = gpib('adlink', 0, app.GaussmeterAddrEditField.Value);
                app.Gaussmeter.Timeout = 5;
                fopen(app.Gaussmeter);

                % add code for gaussmeter SCPI setup
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
                % Calculate total sensitivity for the entire measurement
                % (Highest Resistance - Lowest Resistance) / (Highest Magnetic Field - Lowest Magnetic Field)
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
            uialert(app.UIFigure, sprintf('Data successfully saved to:%s', fullPath), 'Save Complete', 'Icon', 'success');

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
            f.Position = [100 100 1200 400];
            
            % Replot axes 1
            ax1 = subplot(1,3,1, 'Parent', f);
            plot(ax1, app.hLine1.XData, app.hLine1.YData, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
            title(ax1, app.UIAxes.Title.String);
            xlabel(ax1, app.UIAxes.XLabel.String);
            ylabel(ax1, app.UIAxes.YLabel.String);
            if ~isempty(app.UIAxes.XLim) && app.UIAxes.XLim(2) > app.UIAxes.XLim(1)
                xlim(ax1, app.UIAxes.XLim);
            end
            
            % Replot axes 2
            ax2 = subplot(1,3,2, 'Parent', f);
            plot(ax2, app.hLine2.XData, app.hLine2.YData, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
            title(ax2, app.UIAxes2.Title.String);
            xlabel(ax2, app.UIAxes2.XLabel.String);
            ylabel(ax2, app.UIAxes2.YLabel.String);
            if ~isempty(app.UIAxes2.XLim) && app.UIAxes2.XLim(2) > app.UIAxes2.XLim(1)
                xlim(ax2, app.UIAxes2.XLim);
            end
            
            % Replot axes 3
            ax3 = subplot(1,3,3, 'Parent', f);
            plot(ax3, app.hLine3.XData, app.hLine3.YData, '-go', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
            title(ax3, app.UIAxes_2.Title.String);
            xlabel(ax3, app.UIAxes_2.XLabel.String);
            ylabel(ax3, app.UIAxes_2.YLabel.String);
            if ~isempty(app.UIAxes_2.XLim) && app.UIAxes_2.XLim(2) > app.UIAxes_2.XLim(1)
                xlim(ax3, app.UIAxes_2.XLim);
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

        % Ensure max_I > min_I
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
        pause_T = app.SteptimesEditField.Value;
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
        app.hLine1 = plot(app.UIAxes, nan, nan, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
        xlim(app.UIAxes, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);
        app.hLine2 = plot(app.UIAxes2, nan, nan, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
        if strcmp(mode, 'Supply + Gaussmeter')
            xlim(app.UIAxes2, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);
        end
        app.hLine3 = plot(app.UIAxes_2, nan, nan, '-go', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
        xlim(app.UIAxes_2, [min(s_I, e_I)-0.1, max(s_I, e_I)+0.1]);

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
            

            % Extra settle time for the first measurement
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
                if app.RealTimePlotCheckBox.Value
                    set(app.hLine1, 'XData', app.CurrData, 'YData', app.ResData);
                end
            end

            % gaussmeeter reading
            if ~isempty(app.Gaussmeter)
                pause(0.1);
                fprintf(app.Gaussmeter, 'RDGFIELD?');
                field_str = fscanf(app.Gaussmeter);
                field_val = str2double(field_str);
                app.FieldData(end+1) = field_val;
            end

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
            end
            pause(0.05);
            drawnow limitrate;
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
    end
    end

    % Button pushed function: PlotButton
    function PlotButtonPushed(app, event)
        if ~isempty(app.ResData) && length(app.CurrData) == length(app.ResData)
            set(app.hLine1, 'XData', app.CurrData, 'YData', app.ResData);
        end
        
        if ~isempty(app.ResData) && length(app.ResData) == length(app.FieldData) && ~isempty(app.FieldData)
            set(app.hLine2, 'XData', app.FieldData, 'YData', app.ResData);
        elseif isempty(app.ResData) && length(app.CurrData) == length(app.FieldData) && ~isempty(app.FieldData)
            set(app.hLine1, 'XData', app.CurrData, 'YData', app.FieldData);
            set(app.hLine2, 'XData', app.CurrData, 'YData', app.FieldData);
        end

        if length(app.CurrData) == length(app.FieldData) && ~isempty(app.FieldData)
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


    
    % Component initialization
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

            % Create Tab3
            app.Tab3 = uitab(app.TabGroup);
            app.Tab3.Title = 'Tab3';

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.Tab3);
            title(app.UIAxes_2, 'Magnetic field vs Current')
            xlabel(app.UIAxes_2, 'Measured Magnetic Field (G)')
            ylabel(app.UIAxes_2, 'Measured Resistance (Ohms)')
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.Position = [14 31 782 655];

            % Create ConnectionPanel
            app.ConnectionPanel = uipanel(app.UIFigure);
            app.ConnectionPanel.Title = 'Connection';
            app.ConnectionPanel.Position = [25 513 265 257];

            % Create SupplyAddrEditFieldLabel
            app.SupplyAddrEditFieldLabel = uilabel(app.ConnectionPanel);
            app.SupplyAddrEditFieldLabel.HorizontalAlignment = 'right';
            app.SupplyAddrEditFieldLabel.Position = [13 201 70 22];
            app.SupplyAddrEditFieldLabel.Text = 'Supply Addr';

            % Create SupplyAddrEditField
            app.SupplyAddrEditField = uieditfield(app.ConnectionPanel, 'numeric');
            app.SupplyAddrEditField.Position = [136 201 100 22];
            app.SupplyAddrEditField.Value = 6;

            % Create SupplyAddrEditFieldLabel_2
            app.SupplyAddrEditFieldLabel_2 = uilabel(app.ConnectionPanel);
            app.SupplyAddrEditFieldLabel_2.HorizontalAlignment = 'right';
            app.SupplyAddrEditFieldLabel_2.Position = [13 169 104 22];
            app.SupplyAddrEditFieldLabel_2.Text = 'Source Meter addr';

            % Create SupplyAddrEditField_2
            app.SupplyAddrEditField_2 = uieditfield(app.ConnectionPanel, 'numeric');
            app.SupplyAddrEditField_2.Position = [136 169 100 22];
            app.SupplyAddrEditField_2.Value = 24;

            % Create GaussmeterAddrEditFieldLabel
            app.GaussmeterAddrEditFieldLabel = uilabel(app.ConnectionPanel);
            app.GaussmeterAddrEditFieldLabel.HorizontalAlignment = 'right';
            app.GaussmeterAddrEditFieldLabel.Position = [13 135 102 22];
            app.GaussmeterAddrEditFieldLabel.Text = 'Gaussmeter  Addr';
            

            % Create GaussmeterAddrEditField
            app.GaussmeterAddrEditField = uieditfield(app.ConnectionPanel, 'numeric');
            app.GaussmeterAddrEditField.Position = [135 135 100 22];
            app.GaussmeterAddrEditField.Value = 18;

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

            % Create Label
            app.Label = uilabel(app.ConnectionPanel);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [62 93 25 22];
            app.Label.Text = '';

            % Create DropDown
            app.DropDown = uidropdown(app.ConnectionPanel);
            app.DropDown.Items = {'Supply + Source meter', 'Supply + Gaussmeter', 'All instruments'};
            app.DropDown.ValueChangedFcn = createCallbackFcn(app, @DropDownValueChanged, true);
            app.DropDown.ClickedFcn = createCallbackFcn(app, @DropDownClicked, true);
            app.DropDown.Position = [17 93 219 22];
            app.DropDown.Value = 'Supply + Source meter';

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.UIFigure);
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.Position = [25 174 265 325];

            % Create StartCurrentAEditFieldLabel
            app.StartCurrentAEditFieldLabel = uilabel(app.SettingsPanel);
            app.StartCurrentAEditFieldLabel.HorizontalAlignment = 'right';
            app.StartCurrentAEditFieldLabel.Position = [18 203 93 22];
            app.StartCurrentAEditFieldLabel.Text = 'Start Current (A)';

            % Create StartCurrentAEditField
            app.StartCurrentAEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.StartCurrentAEditField.Position = [139 203 100 22];
            app.StartCurrentAEditField.Value = -1;

            % Create SupplyAddrEditFieldLabel_3
            app.SupplyAddrEditFieldLabel_3 = uilabel(app.SettingsPanel);
            app.SupplyAddrEditFieldLabel_3.HorizontalAlignment = 'right';
            app.SupplyAddrEditFieldLabel_3.Position = [19 171 89 22];
            app.SupplyAddrEditFieldLabel_3.Text = 'End Current (A)';

            % Create SupplyAddrEditField_4
            app.SupplyAddrEditField_4 = uieditfield(app.SettingsPanel, 'numeric');
            app.SupplyAddrEditField_4.Position = [139 171 100 22];
            app.SupplyAddrEditField_4.Value = 1;

            % Create StepsizeAEditFieldLabel
            app.StepsizeAEditFieldLabel = uilabel(app.SettingsPanel);
            app.StepsizeAEditFieldLabel.HorizontalAlignment = 'right';
            app.StepsizeAEditFieldLabel.Position = [19 141 74 22];
            app.StepsizeAEditFieldLabel.Text = 'Step size (A)';

            % Create StepsizeAEditField
            app.StepsizeAEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.StepsizeAEditField.Position = [139 141 100 22];
            app.StepsizeAEditField.Value = 0.1;

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
            app.SteptimesEditFieldLabel.HorizontalAlignment = 'right';
            app.SteptimesEditFieldLabel.Position = [19 109 73 22];
            app.SteptimesEditFieldLabel.Text = 'Step time (s)';

            % Create SteptimesEditField
            app.SteptimesEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.SteptimesEditField.Position = [139 109 100 22];
            app.SteptimesEditField.Value = 0.2;

            % Create FilenameEditField_2Label
            app.FilenameEditField_2Label = uilabel(app.SettingsPanel);
            app.FilenameEditField_2Label.HorizontalAlignment = 'right';
            app.FilenameEditField_2Label.Position = [19 76 54 22];
            app.FilenameEditField_2Label.Text = 'Filename';

            % Create FilenameEditField_2
            app.FilenameEditField_2 = uieditfield(app.SettingsPanel, 'text');
            app.FilenameEditField_2.HorizontalAlignment = 'right';
            app.FilenameEditField_2.Position = [139 76 100 22];
            app.FilenameEditField_2.Value = 'Data';

            % Create StartCurrentAEditFieldLabel_2
            app.StartCurrentAEditFieldLabel_2 = uilabel(app.SettingsPanel);
            app.StartCurrentAEditFieldLabel_2.HorizontalAlignment = 'right';
            app.StartCurrentAEditFieldLabel_2.Position = [23 267 89 22];
            app.StartCurrentAEditFieldLabel_2.Text = 'Max Current (+)';

            % Create StartCurrentAEditField_2
            app.StartCurrentAEditField_2 = uieditfield(app.SettingsPanel, 'numeric');
            app.StartCurrentAEditField_2.Position = [140 267 100 22];
            app.StartCurrentAEditField_2.Value = 2;

            % Create StartCurrentAEditFieldLabel_3
            app.StartCurrentAEditFieldLabel_3 = uilabel(app.SettingsPanel);
            app.StartCurrentAEditFieldLabel_3.HorizontalAlignment = 'right';
            app.StartCurrentAEditFieldLabel_3.Position = [29 235 83 22];
            app.StartCurrentAEditFieldLabel_3.Text = 'Min Current (-)';

            % Create StartCurrentAEditField_3
            app.StartCurrentAEditField_3 = uieditfield(app.SettingsPanel, 'numeric');
            app.StartCurrentAEditField_3.Position = [140 235 100 22];
            app.StartCurrentAEditField_3.Value = -2;

            % Create HysteresisCheckBox
            app.HysteresisCheckBox = uicheckbox(app.SettingsPanel);
            app.HysteresisCheckBox.Text = 'Hysteresis';
            app.HysteresisCheckBox.Position = [24 50 78 22];

            % Create ControlPanel
            app.ControlPanel = uipanel(app.UIFigure);
            app.ControlPanel.Title = 'Control';
            app.ControlPanel.Position = [25 39 265 122];

            % Create StartButton
            app.StartButton = uibutton(app.ControlPanel, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Position = [17 51 71 36];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.ControlPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [99 51 72 36];
            app.StopButton.Text = 'Stop';

            % Create ResistanceOhmsLabel
            app.ResistanceOhmsLabel = uilabel(app.ControlPanel);
            app.ResistanceOhmsLabel.Position = [19 16 118 22];
            app.ResistanceOhmsLabel.Text = 'Resistance : -- Ohms';

            % Create PlotButton
            app.PlotButton = uibutton(app.ControlPanel, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);
            app.PlotButton.Position = [181 51 72 36];
            app.PlotButton.Text = 'Plot';
            app.PlotButton.Enable = 'off';

            % Create RealTimePlotCheckBox
            app.RealTimePlotCheckBox = uicheckbox(app.ControlPanel);
            app.RealTimePlotCheckBox.Text = 'Real Time Plot';
            app.RealTimePlotCheckBox.Position = [152 16 100 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = newerui

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
