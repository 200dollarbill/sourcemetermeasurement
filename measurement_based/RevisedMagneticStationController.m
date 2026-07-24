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
        Tab1                           matlab.ui.container.Tab
        UIAxes                         matlab.ui.control.UIAxes
        Tab2                           matlab.ui.container.Tab
        UIAxes2                        matlab.ui.control.UIAxes
        Tab3                           matlab.ui.container.Tab
        UIAxes_2                       matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: SavetoExcelButton
        function SavetoExcelButtonPushed(app, event)
            
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
            
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            
        end

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            
        end

        % Button pushed function: DisconnectButton
        function DisconnectButtonPushed(app, event)
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1147 729];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [310 12 820 690];

            % Create Tab1
            app.Tab1 = uitab(app.TabGroup);
            app.Tab1.Title = 'Tab1';

            % Create UIAxes
            app.UIAxes = uiaxes(app.Tab1);
            title(app.UIAxes, 'Resistance vs Current')
            xlabel(app.UIAxes, 'Input Current (A)')
            ylabel(app.UIAxes, 'Measured Resistance (Ohms)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [14 9 782 635];

            % Create Tab2
            app.Tab2 = uitab(app.TabGroup);
            app.Tab2.Title = 'Tab2';

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.Tab2);
            title(app.UIAxes2, 'Resistance vs Magnetic Field')
            xlabel(app.UIAxes2, 'Measured Resistance (Ohms)')
            ylabel(app.UIAxes2, 'Measured Magnetic Field Strength (G)')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [15 9 781 635];

            % Create Tab3
            app.Tab3 = uitab(app.TabGroup);
            app.Tab3.Title = 'Tab3';

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.Tab3);
            title(app.UIAxes_2, 'Magnetic field vs Current')
            xlabel(app.UIAxes_2, 'Measured Magnetic Field (G)')
            ylabel(app.UIAxes_2, 'Measured Resistance (Ohms)')
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.Position = [14 9 782 635];

            % Create TabGroup2
            app.TabGroup2 = uitabgroup(app.UIFigure);
            app.TabGroup2.Position = [17 11 285 691];

            % Create Tab
            app.Tab = uitab(app.TabGroup2);
            app.Tab.Title = 'Tab';

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.Tab);
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.Position = [13 285 265 370];

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
            app.ControlPanel_2.Position = [15 10 265 265];

            % Create TimetofinishLabel
            app.TimetofinishLabel = uilabel(app.ControlPanel_2);
            app.TimetofinishLabel.Position = [22 19 86 22];
            app.TimetofinishLabel.Text = 'Time to finish : ';

            % Create CyclecountEditFieldLabel
            app.CyclecountEditFieldLabel = uilabel(app.ControlPanel_2);
            app.CyclecountEditFieldLabel.HorizontalAlignment = 'right';
            app.CyclecountEditFieldLabel.Position = [14 205 68 22];
            app.CyclecountEditFieldLabel.Text = 'Cycle count';

            % Create CyclecountEditField
            app.CyclecountEditField = uieditfield(app.ControlPanel_2, 'text');
            app.CyclecountEditField.InputType = 'digits';
            app.CyclecountEditField.HorizontalAlignment = 'right';
            app.CyclecountEditField.Position = [148 205 100 22];
            app.CyclecountEditField.Value = '1';

            % Create DelaypercyclesEditFieldLabel
            app.DelaypercyclesEditFieldLabel = uilabel(app.ControlPanel_2);
            app.DelaypercyclesEditFieldLabel.HorizontalAlignment = 'right';
            app.DelaypercyclesEditFieldLabel.Position = [15 170 104 22];
            app.DelaypercyclesEditFieldLabel.Text = 'Delay per cycle (s)';

            % Create DelaypercyclesEditField
            app.DelaypercyclesEditField = uieditfield(app.ControlPanel_2, 'text');
            app.DelaypercyclesEditField.InputType = 'digits';
            app.DelaypercyclesEditField.HorizontalAlignment = 'right';
            app.DelaypercyclesEditField.Position = [149 170 100 22];
            app.DelaypercyclesEditField.Value = '1';

            % Create HysteresisCheckBox
            app.HysteresisCheckBox = uicheckbox(app.ControlPanel_2);
            app.HysteresisCheckBox.Text = 'Hysteresis';
            app.HysteresisCheckBox.Position = [19 136 78 22];

            % Create StartButton
            app.StartButton = uibutton(app.ControlPanel_2, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Position = [19 88 71 36];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.ControlPanel_2, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [101 88 72 36];
            app.StopButton.Text = 'Stop';

            % Create ResistanceOhmsLabel
            app.ResistanceOhmsLabel = uilabel(app.ControlPanel_2);
            app.ResistanceOhmsLabel.Position = [21 53 118 22];
            app.ResistanceOhmsLabel.Text = 'Resistance : -- Ohms';

            % Create PlotButton
            app.PlotButton = uibutton(app.ControlPanel_2, 'push');
            app.PlotButton.Position = [183 88 72 36];
            app.PlotButton.Text = 'Plot';

            % Create RealTimePlotCheckBox
            app.RealTimePlotCheckBox = uicheckbox(app.ControlPanel_2);
            app.RealTimePlotCheckBox.Text = 'Real Time Plot';
            app.RealTimePlotCheckBox.Position = [154 53 100 22];

            % Create Tab2_2
            app.Tab2_2 = uitab(app.TabGroup2);
            app.Tab2_2.Title = 'Tab2';

            % Create ConnectionPanel
            app.ConnectionPanel = uipanel(app.Tab2_2);
            app.ConnectionPanel.Title = 'Connection';
            app.ConnectionPanel.Position = [13 398 265 257];

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

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end