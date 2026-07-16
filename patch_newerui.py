import re

with open("newUI.m", "r") as f:
    nui_content = f.read()
    
with open("newerui.m", "r") as f:
    newer_content = f.read()

# Extract private properties from newUI.m
props_match = re.search(r'(% Non-UI properties for hardware handles and sweep data.*?end)\s+% Callbacks that handle component events', nui_content, re.DOTALL)
private_props = props_match.group(1) if props_match else """
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

# Extract private methods from newUI.m
methods_match = re.search(r'(% Callbacks that handle component events\s+methods \(Access = private\).*?)% Component initialization', nui_content, re.DOTALL)
private_methods = methods_match.group(1)

# Rename PlotResponseButton to PlotButton
private_methods = private_methods.replace('PlotResponseButton', 'PlotButton')

# Insert properties and replace methods in newerui.m
newer_content = re.sub(r'% Callbacks that handle component events\s+methods \(Access = private\).*?end\s+end\s+% Component initialization', 
                       private_props + '\n\n    ' + private_methods + '\n    % Component initialization', newer_content, flags=re.DOTALL)

# Add ButtonPushedFcn to PlotButton and disable it by default
plot_button_code = """
            % Create PlotButton
            app.PlotButton = uibutton(app.ControlPanel, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);
            app.PlotButton.Position = [181 51 72 36];
            app.PlotButton.Text = 'Plot';
            app.PlotButton.Enable = 'off';
"""
newer_content = re.sub(r'% Create PlotButton.*?app\.PlotButton\.Text = \'Plot\';', plot_button_code.strip(), newer_content, flags=re.DOTALL)

# Modify delete method
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
newer_content = re.sub(r'% Code that executes before app deletion.*?delete\(app\.UIFigure\)\s*end', delete_code.strip(), newer_content, flags=re.DOTALL)

with open("newerui.m", "w") as f:
    f.write(newer_content)

print("Patch applied to newerui.m")
