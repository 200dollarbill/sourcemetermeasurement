import sys

with open('RevisedMagneticStationController.m', 'r') as f:
    orig = f.read()

# 1. Add property
target_prop = """        SteptimesEditFieldLabel        matlab.ui.control.Label
        SavetoExcelButton              matlab.ui.control.Button
        StepsizeAEditField             matlab.ui.control.NumericEditField"""
replacement_prop = """        SteptimesEditFieldLabel        matlab.ui.control.Label
        SavetoExcelButton              matlab.ui.control.Button
        SaveToFigureButton             matlab.ui.control.Button
        StepsizeAEditField             matlab.ui.control.NumericEditField"""

orig = orig.replace(target_prop, replacement_prop)

# 2. Add callback
target_cb = """        % Value changed function: DropDown"""

save_fig_cb = """        % Button pushed function: SaveToFigureButton
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
                f = figure('Name', 'Exported Plots', 'NumberTitle', 'off', 'Visible', 'off');
                f.Position = [100 100 1200 800];
                
                ax1 = subplot(2,3,1, 'Parent', f);
                plot(ax1, app.hLine1.XData, app.hLine1.YData, '-ro', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
                title(ax1, app.UIAxes.Title.String); xlabel(ax1, app.UIAxes.XLabel.String); ylabel(ax1, app.UIAxes.YLabel.String);
                if ~isempty(app.UIAxes.XLim) && app.UIAxes.XLim(2) > app.UIAxes.XLim(1); xlim(ax1, app.UIAxes.XLim); end
                
                ax2 = subplot(2,3,2, 'Parent', f);
                plot(ax2, app.hLine2.XData, app.hLine2.YData, '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
                title(ax2, app.UIAxes2.Title.String); xlabel(ax2, app.UIAxes2.XLabel.String); ylabel(ax2, app.UIAxes2.YLabel.String);
                if ~isempty(app.UIAxes2.XLim) && app.UIAxes2.XLim(2) > app.UIAxes2.XLim(1); xlim(ax2, app.UIAxes2.XLim); end
                
                ax3 = subplot(2,3,3, 'Parent', f);
                plot(ax3, app.hLine3.XData, app.hLine3.YData, '-go', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
                title(ax3, app.UIAxes_2.Title.String); xlabel(ax3, app.UIAxes_2.XLabel.String); ylabel(ax3, app.UIAxes_2.YLabel.String);
                if ~isempty(app.UIAxes_2.XLim) && app.UIAxes_2.XLim(2) > app.UIAxes_2.XLim(1); xlim(ax3, app.UIAxes_2.XLim); end
                
                ax4 = subplot(2,3,4, 'Parent', f);
                plot(ax4, app.hLine4.XData, app.hLine4.YData, '-ko', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
                title(ax4, app.UIAxes_3.Title.String); xlabel(ax4, app.UIAxes_3.XLabel.String); ylabel(ax4, app.UIAxes_3.YLabel.String);
                if ~isempty(app.UIAxes_3.XLim) && app.UIAxes_3.XLim(2) > app.UIAxes_3.XLim(1); xlim(ax4, app.UIAxes_3.XLim); end
                
                ax5 = subplot(2,3,5, 'Parent', f);
                plot(ax5, app.hLine5.XData, app.hLine5.YData, '-mo', 'LineWidth', 1.5, 'MarkerFaceColor', 'm');
                title(ax5, app.UIAxes_4.Title.String); xlabel(ax5, app.UIAxes_4.XLabel.String); ylabel(ax5, app.UIAxes_4.YLabel.String);
                if ~isempty(app.UIAxes_4.XLim) && app.UIAxes_4.XLim(2) > app.UIAxes_4.XLim(1); xlim(ax5, app.UIAxes_4.XLim); end
                
                f.Visible = 'on';
                drawnow;
                
                [~, ~, ext] = fileparts(fullPath);
                if strcmpi(ext, '.fig')
                    savefig(f, fullPath);
                else
                    exportgraphics(f, fullPath, 'Resolution', 300);
                end
                close(f);
                
                uialert(app.UIFigure, sprintf('Figures successfully saved to:\\n%s', fullPath), 'Save Complete', 'Icon', 'success');
            catch ME
                uialert(app.UIFigure, ['Failed to save figure: ' ME.message], 'Save Error', 'Icon', 'warning');
                if exist('f', 'var') && isvalid(f)
                    close(f);
                end
            end
        end

        % Value changed function: DropDown"""

orig = orig.replace(target_cb, save_fig_cb)

# 3. Disable state
target_dis = """            app.TimeFieldData = [];
            
            app.SavetoExcelButton.Enable = 'off';"""
replacement_dis = """            app.TimeFieldData = [];
            
            app.SavetoExcelButton.Enable = 'off';
            app.SaveToFigureButton.Enable = 'off';"""

orig = orig.replace(target_dis, replacement_dis)

# 4. Enable state
target_en = """            if ~isempty(app.CurrData)
                app.SavetoExcelButton.Enable = 'on';"""
replacement_en = """            if ~isempty(app.CurrData)
                app.SavetoExcelButton.Enable = 'on';
                app.SaveToFigureButton.Enable = 'on';"""

orig = orig.replace(target_en, replacement_en)

# 5. UI components
target_ui = """            % Create SavetoExcelButton
            app.SavetoExcelButton = uibutton(app.SettingsPanel, 'push');
            app.SavetoExcelButton.ButtonPushedFcn = createCallbackFcn(app, @SavetoExcelButtonPushed, true);
            app.SavetoExcelButton.Position = [22 14 220 33];
            app.SavetoExcelButton.Text = 'Save to Excel';"""

replacement_ui = """            % Create SavetoExcelButton
            app.SavetoExcelButton = uibutton(app.SettingsPanel, 'push');
            app.SavetoExcelButton.ButtonPushedFcn = createCallbackFcn(app, @SavetoExcelButtonPushed, true);
            app.SavetoExcelButton.Position = [22 14 100 33];
            app.SavetoExcelButton.Text = 'Save Excel';

            % Create SaveToFigureButton
            app.SaveToFigureButton = uibutton(app.SettingsPanel, 'push');
            app.SaveToFigureButton.ButtonPushedFcn = createCallbackFcn(app, @SaveToFigureButtonPushed, true);
            app.SaveToFigureButton.Position = [142 14 100 33];
            app.SaveToFigureButton.Text = 'Save Plot';"""

orig = orig.replace(target_ui, replacement_ui)

with open('RevisedMagneticStationController.m', 'w') as f:
    f.write(orig)

print("Added SaveToFigureButton.")
