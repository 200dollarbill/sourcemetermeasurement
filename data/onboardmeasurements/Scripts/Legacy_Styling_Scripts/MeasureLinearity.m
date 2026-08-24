% batchStyleFigures.m
% Finds all .fig files in the current folder, duplicates the main plot 
% into an inset, applies the specific template styles, and saves a new copy.

% 1. Get a list of all .fig files in the current directory
figFiles = dir('*.fig');

if isempty(figFiles)
    disp('Error: No .fig files found.');
    return;
end

for k = 1:length(figFiles)
    filename = figFiles(k).name;
    fullFilePath = fullfile(figFiles(k).folder, filename);
    
    % Skip files that already have the 'styled_' prefix
    if startsWith(filename, 'styled_')
        continue;
    end
    
    % 2. Open figure invisibly
    try
        hFigure = openfig(fullFilePath, 'invisible');
    catch ME
        fprintf('Failed to open %s. Error: %s\n', filename, ME.message);
        continue; 
    end
    
    hFigure.Color = [0.9412, 0.9412, 0.9412];
    
    % 3. Find the original axes (Main Axes)
    hAxes = findobj(hFigure, 'Type', 'axes');
    
    if isempty(hAxes)
        fprintf('No axes found in %s. Skipping.\n', filename);
        close(hFigure);
        continue;
    elseif length(hAxes) > 1
        fprintf('Multiple axes already exist in %s. Skipping.\n', filename);
        close(hFigure);
        continue;
    end
    
    mainAxes = hAxes(1);
    
    % 4. Duplicate the axes to create the inset
    insetAxes = copyobj(mainAxes, hFigure);
    
    % 5. Style the Main Axes
    mainAxes.Position = [0.1300, 0.1100, 0.6476, 0.8150];
    mainAxes.LineWidth = 2;
    mainAxes.Box = 'on';
    mainAxes.XGrid = 'off';
    mainAxes.YGrid = 'off';
    
    % Main axes grid numbers (tick labels) - Size 20, Non-bold
    mainAxes.FontSize = 20;
    mainAxes.FontWeight = 'normal';
    
    % Main axes Labels - Size 22, Bold
    if ~isempty(mainAxes.XLabel.String)
        mainAxes.XLabel.FontSize = 22;
        mainAxes.XLabel.FontWeight = 'bold';
    end
    if ~isempty(mainAxes.YLabel.String)
        mainAxes.YLabel.FontSize = 22;
        mainAxes.YLabel.FontWeight = 'bold';
    end
    if ~isempty(mainAxes.ZLabel.String)
        mainAxes.ZLabel.FontSize = 22;
        mainAxes.ZLabel.FontWeight = 'bold';
    end
    
    if ~isempty(mainAxes.Title.String)
        mainAxes.Title.FontWeight = 'bold';
    end
    
    % 6. Style the Inset Axes
    insetAxes.Position = [0.5430, 0.4677, 0.2075, 0.3048];
    insetAxes.LineWidth = 2;
    insetAxes.BoxStyle = 'full';
    insetAxes.Box = 'on';
    
    % Inset axes grid numbers (tick labels) - Size 18
    insetAxes.FontSize = 24;
    
    % Strip titles and labels from the copied inset
    insetAxes.Title.String = '';
    insetAxes.XLabel.String = '';
    insetAxes.YLabel.String = '';
    insetAxes.ZLabel.String = '';
    
    % 7. Handle Legends
    allLegends = findobj(hFigure, 'Type', 'legend');
    for L = 1:length(allLegends)
        if allLegends(L).Axes == insetAxes
            delete(allLegends(L));
        else
            allLegends(L).FontSize = 18;
            allLegends(L).Position = [0.6600, 0.8042, 0.1008, 0.0358];
        end
    end
    
    % 8. Style Floating Text Annotations
    hText = findobj(hFigure, 'Type', 'text');
    for t = 1:length(hText)
        if ~isempty(hText(t).String)
            hText(t).FontSize = 20;
            try
                hText(t).Position = [0.6789, 0.9472, 0];
            catch
            end
        end
    end
    
    % 9. Make the figure visible again, then save
    hFigure.Visible = 'on'; 
    
    newFilename = ['styled_', filename];
    newFilePath = fullfile(figFiles(k).folder, newFilename);
    savefig(hFigure, newFilePath);
    close(hFigure);
    
    fprintf('Processed and saved: %s\n', newFilename);
end

disp('Batch processing complete!');