import re

with open('LUT_based/LUTGUI.m', 'r') as f:
    content = f.read()

# 1. Remove UI properties
content = re.sub(r'\s*Tab3\s*matlab\.ui\.container\.Tab\n', '\n', content)
content = re.sub(r'\s*UIAxes_2\s*matlab\.ui\.control\.UIAxes\n', '\n', content)

# 2. Remove private property
content = re.sub(r'\s*hLine3\n', '\n', content)

# 3. Remove createComponents code for Tab3 and UIAxes_2
creation_pattern = r"\s*% Create Tab3\s*app\.Tab3 = uitab\(app\.TabGroup\);\s*app\.Tab3\.Title = 'Tab3';\s*% Create UIAxes_2\s*app\.UIAxes_2 = uiaxes\(app\.Tab3\);\s*title\(app\.UIAxes_2, 'Magnetic field vs Current'\)\s*xlabel\(app\.UIAxes_2, 'Measured Magnetic Field \(G\)'\)\s*ylabel\(app\.UIAxes_2, 'Measured Resistance \(Ohms\)'\)\s*zlabel\(app\.UIAxes_2, 'Z'\)\s*app\.UIAxes_2\.Position = \[\d+ \d+ \d+ \d+\];\n"
content = re.sub(creation_pattern, '\n', content)

# 4. Remove StartButtonPushed title, xlabel, ylabel
labels_pattern = r"\s*title\(app\.UIAxes_2, 'Magnetic Field vs Current'\);\s*xlabel\(app\.UIAxes_2, 'Input Current \(A\)'\);\s*ylabel\(app\.UIAxes_2, 'Interpolated Magnetic Field \(G\)'\);\n"
content = re.sub(labels_pattern, '\n', content)

# 5. Remove cla, plot, xlim
cla_pattern = r"\s*cla\(app\.UIAxes_2\);\n"
content = re.sub(cla_pattern, '\n', content)

plot_pattern = r"\s*app\.hLine3 = plot\(app\.UIAxes_2, nan, nan, '-go', 'LineWidth', 1\.5, 'MarkerFaceColor', 'g'\);\s*xlim\(app\.UIAxes_2, \[min\(s_I, e_I\)-0\.1, max\(s_I, e_I\)\+0\.1\]\);\n"
content = re.sub(plot_pattern, '\n', content)

# 6. Remove hLine3 updates in StartButtonPushed
update_pattern = r"\s*set\(app\.hLine3, 'XData', app\.CurrData, 'YData', app\.FieldData\);\n"
content = re.sub(update_pattern, '\n', content)

# 7. Remove hLine3 updates in PlotButtonPushed
plot_btn_pattern = r"\s*if length\(app\.CurrData\) == length\(app\.FieldData\)\s*set\(app\.hLine3, 'XData', app\.CurrData, 'YData', app\.FieldData\);\s*end\n"
content = re.sub(plot_btn_pattern, '\n', content)

with open('LUT_based/LUTGUI.m', 'w') as f:
    f.write(content)

print("Figure 3 successfully removed.")
