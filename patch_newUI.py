import re

with open("ControllerGUI.m", "r") as f:
    cg_content = f.read()
    
with open("newUI.m", "r") as f:
    nui_content = f.read()

# 1. Extract callbacks block from ControllerGUI.m
# It starts at "methods (Access = private)" and ends right before "% Component initialization"
match = re.search(r'(methods \(Access = private\).*?)% Component initialization', cg_content, re.DOTALL)
callbacks_block = match.group(1)

# Modify callbacks_block to use StartCurrentAEditField_2 for Max and StartCurrentAEditField_3 for Min
# In ControllerGUI, they were MaxCurrentEditField and MinCurrentEditField (text fields)
callbacks_block = callbacks_block.replace("max_limit_str = strtrim(app.MaxCurrentEditField.Value);", "max_I = app.StartCurrentAEditField_2.Value;")
callbacks_block = callbacks_block.replace("min_limit_str = strtrim(app.MinCurrentEditField.Value);", "min_I = app.StartCurrentAEditField_3.Value;")
callbacks_block = re.sub(r'if isempty\(max_limit_str\).*?end', '', callbacks_block, flags=re.DOTALL)
callbacks_block = re.sub(r'if isempty\(min_limit_str\).*?end', '', callbacks_block, flags=re.DOTALL)

# UIAxes3 in ControllerGUI is UIAxes_2 in newUI.m
callbacks_block = callbacks_block.replace("app.UIAxes3", "app.UIAxes_2")

# Replace callbacks in newUI.m
nui_content = re.sub(r'methods \(Access = private\)\s+% Button pushed function: ConnectButton.*?end\s+end', callbacks_block.strip() + '\n', nui_content, flags=re.DOTALL)

# 2. Add properties
props_addition = """
        HysteresisCheckBox             matlab.ui.control.CheckBox
        RealTimePlotCheckBox           matlab.ui.control.CheckBox
        PlotResponseButton             matlab.ui.control.Button
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
"""
nui_content = nui_content.replace("        UIAxes_2                       matlab.ui.control.UIAxes\n    end", "        UIAxes_2                       matlab.ui.control.UIAxes\n" + props_addition)

# 3. Modify createComponents
# We need to add HysteresisCheckBox to SettingsPanel
# Let's put HysteresisCheckBox in SettingsPanel at position [18 288 100 22] or similar, wait.
# The user's newUI SettingsPanel has height 325.
# Max Current (+) is at [21 258 89 22]
# Min Current (-) is at [27 226 83 22]
# So let's put Hysteresis at [18 290 100 22]
hys_code = """
            % Create HysteresisCheckBox
            app.HysteresisCheckBox = uicheckbox(app.SettingsPanel);
            app.HysteresisCheckBox.Text = 'Hysteresis';
            app.HysteresisCheckBox.Position = [18 290 100 22];
"""
nui_content = nui_content.replace("% Create ControlPanel", hys_code + "\n            % Create ControlPanel")

# RealTimePlotCheckBox in ControlPanel
# PlotResponseButton in ControlPanel
rt_code = """
            % Create RealTimePlotCheckBox
            app.RealTimePlotCheckBox = uicheckbox(app.ControlPanel);
            app.RealTimePlotCheckBox.Text = 'Real-time Plot';
            app.RealTimePlotCheckBox.Position = [17 95 150 22];
            app.RealTimePlotCheckBox.Value = true;
"""
pr_code = """
            % Create PlotResponseButton
            app.PlotResponseButton = uibutton(app.ControlPanel, 'push');
            app.PlotResponseButton.ButtonPushedFcn = createCallbackFcn(app, @PlotResponseButtonPushed, true);
            app.PlotResponseButton.Position = [135 10 100 33];
            app.PlotResponseButton.Text = 'Plot Response';
            app.PlotResponseButton.Enable = 'off';
"""
# Find "% Create StartButton" inside createComponents
nui_content = nui_content.replace("% Create StartButton", rt_code + "\n            % Create StartButton")
nui_content = nui_content.replace("% Show the figure after all components are created", pr_code + "\n            % Show the figure after all components are created")

# Replace safeShutdown and delete from ControllerGUI.m?
# safeShutdown is already in the callbacks block we copied.
# But delete(app) in newUI.m needs to call safeShutdown and DisconnectButtonPushed.
delete_code = """
        % Code that executes before app deletion
        function delete(app)
            app.StopFlag = true;
            app.safeShutdown();
            DisconnectButtonPushed(app, []);

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
"""
nui_content = re.sub(r'% Code that executes before app deletion.*?delete\(app\.UIFigure\)\s*end', delete_code.strip(), nui_content, flags=re.DOTALL)

with open("newUI.m", "w") as f:
    f.write(nui_content)

print("Patch applied to newUI.m")
