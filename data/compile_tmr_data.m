% compile_tmr_data.m
% Simple script to compile all TMR Excel files into one large master table.

clear; clc;

% Define the directories to read from
dataDirs = {'Hsin Tings Board', 'Peters Board'};
baseDataPath = pwd; % Assuming you run this inside the 'data' folder

allData = {};
fileCount = 0;

disp('Starting data compilation...');

for d = 1:length(dataDirs)
    dirPath = fullfile(baseDataPath, dataDirs{d});
    
    % Recursively find all .xlsx files in the directory
    files = dir(fullfile(dirPath, '**', '*.xlsx'));
    
    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;
        
        try
            % Read the Excel file
            T = readtable(filePath);
            
            if isempty(T)
                continue; % Skip empty files
            end
            
            % Try to extract Board and Test Point metadata from the filename
            boardName = 'Unknown';
            testPoint = 'Unknown';
            
            if strcmp(dataDirs{d}, 'Hsin Tings Board')
                % Expected format: Board1_A.xlsx
                tokens = regexp(fileName, '(Board\d+)_([A-Za-z0-9]+)\.xlsx', 'tokens');
                if ~isempty(tokens)
                    boardName = tokens{1}{1};
                    testPoint = tokens{1}{2};
                end
            elseif strcmp(dataDirs{d}, 'Peters Board')
                % Expected format: B1A.xlsx or B1D_mod.xlsx
                tokens = regexp(fileName, 'B(\d+)([A-Za-z0-9_]+)\.xlsx', 'tokens');
                if ~isempty(tokens)
                    boardName = ['Board', tokens{1}{1}];
                    testPoint = tokens{1}{2};
                end
            end
            
            % Create metadata columns to match the number of rows
            numRows = height(T);
            Dataset = repmat(string(dataDirs{d}), numRows, 1);
            Board = repmat(string(boardName), numRows, 1);
            Sensor = repmat(string(testPoint), numRows, 1);
            
            % Prepend the metadata to the table
            T = addvars(T, Dataset, Board, Sensor, 'Before', 1);
            
            % Add to our cell array
            fileCount = fileCount + 1;
            allData{fileCount, 1} = T;
            
        catch ME
            fprintf('Error reading %s: %s\n', fileName, ME.message);
        end
    end
end

% Combine all individual tables into one massive master table
if ~isempty(allData)
    disp(['Merging ', num2str(fileCount), ' files into a single master table...']);
    masterTable = vertcat(allData{:});
    
    % Save as a MATLAB .mat workspace variable for fast loading later
    save('Compiled_TMR_Data.mat', 'masterTable');
    
    % Also save as a CSV file for easy viewing in Excel/Python
    writetable(masterTable, 'Compiled_TMR_Data.csv');
    
    disp('Success! Data saved to Compiled_TMR_Data.mat and Compiled_TMR_Data.csv');
else
    disp('No Excel files found. Please ensure you are running this in the "data" directory.');
end
