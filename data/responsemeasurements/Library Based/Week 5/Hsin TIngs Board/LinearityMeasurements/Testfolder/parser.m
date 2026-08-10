% batchStyleFigures.m
% Finds all .fig files in the current folder, duplicates the main plot 
% into an inset, applies the specific template styles, and saves a new copy.

% 1. Get a list of all .fig files in the current directory
figFiles = dir('*.fig');

for k = 1:length(figFiles)
    filename = figFiles(k).name;
    
    % Skip files that already have the 'styled_' prefix to avoid infinite loops
    if startsWith(filename, 'styled')
        continue;
    end
    
    % 2. Open figure invisibly to prevent screen flashing and speed up processing
    hFigure = openfig(filename, 'invisible');
    
    % Apply Figure Background Color
    hFigure.Color = [0.9412, 0.9412, 0.9412];
    
    % 3. Find the original axes (Main Axes)
    hAxes = findobj(hFigure, 'Type', 'axes');
    
    if isempty(hAxes)
        fprintf('No axes found in %s. Skipping.\n', filename);
        close(hFigure);
        continue;
    elseif length(hAxes) > 1
        fprintf('Multiple axes already exist in %s. Assuming it is already styled. Skipping.\n', filename);
        close(hFigure);
        continue;
    end
    
    mainAxes = hAxes(1);
    
    % 4. Duplicate the axes to create the inset
    % copyobj clones the axes and all its plotted data lines into the same figure
    insetAxes = copyobj(mainAxes, hFigure);
    
    % 5. Style the Main Axes
    mainAxes.FontSize = 20;
    mainAxes.Position = [0.1300, 0.1100, 0.6476, 0.8150];
    mainAxes.LineWidth = 2;
    mainAxes.FontWeight = 'normal';
    mainAxes.Box = 'on';
    mainAxes.XGrid = 'off';
    mainAxes.YGrid = 'off';
    
    if ~isempty(mainAxes.Title.String)
        mainAxes.Title.FontWeight = 'bold';
    end
    
    % 6. Style the Inset Axes
    insetAxes.Position = [0.5430, 0.4677, 0.2075, 0.3048];
    insetAxes.LineWidth = 1.5000;
    insetAxes.BoxStyle = 'full';
    insetAxes.Box = 'on';
    
    % Strip titles and labels from the copied inset
    insetAxes.Title.String = '';
    insetAxes.XLabel.String = '';
    insetAxes.YLabel.String = '';
    insetAxes.ZLabel.String = '';
    
    % 7. Handle Legends
    % copyobj might duplicate the legend. We need to keep only the main one.
    allLegends = findobj(hFigure, 'Type', 'legend');
    for L = 1:length(allLegends)
        % If the legend is linked to the inset, delete it
        if allLegends(L).Axes == insetAxes
            delete(allLegends(L));
        else
            % Style the remaining main legend
            allLegends(L).FontSize = 18;
            allLegends(L).Position = [0.6600, 0.8042, 0.1008, 0.0358];
        end
    end
    
    % 8. Style Floating Text Annotations (if any exist)
    hText = findobj(hFigure, 'Type', 'text');
    for t = 1:length(hText)
        if ~isempty(hText(t).String)
            hText(t).FontSize = 20;
            try
                hText(t).Position = [0.6628, 0.9585, 0];
            catch
                % Silently pass if position unit mismatch occurs
            end
        end
    end
    
    % 9. Save and Close
    newFilename = ['styled_', filename];
    savefig(hFigure, newFilename);
    close(hFigure);
    
    fprintf('Processed and saved: %s\n', newFilename);
end

disp('Batch processing complete!');