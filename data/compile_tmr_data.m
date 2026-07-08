% compile_tmr_data.m
clear; clc;
dataDirs = {'Hsin Tings Board', 'Peters Board'};
baseDataPath = pwd
allData = {};
fileCount = 0;

for d = 1:length(dataDirs)
    dirPath = fullfile(baseDataPath, dataDirs{d});
    files = dir(fullfile(dirPath, '**', '*.xlsx'));
    for f = 1:length(files)
        filePath = fullfile(files(f).folder, files(f).name);
        fileName = files(f).name;
        try
        T = readtable(filePath);
        
        if isempty(T)
            continue; 
        end
        boardName = 'Unknown';
        testPoint = 'Unknown';
        
        if strcmp(dataDirs{d}, 'Hsin Tings Board')
            tokens = regexp(fileName, '(Board\d+)_([A-Za-z0-9]+)\.xlsx', 'tokens');
            if ~isempty(tokens)
                boardName = tokens{1}{1};
                testPoint = tokens{1}{2};
            end
        elseif strcmp(dataDirs{d}, 'Peters Board')
            tokens = regexp(fileName, 'B(\d+)([A-Za-z0-9_]+)\.xlsx', 'tokens');
            if ~isempty(tokens)
                boardName = ['Board', tokens{1}{1}];
                testPoint = tokens{1}{2};
            end
        end
        numRows = height(T);
        Dataset = repmat(string(dataDirs{d}), numRows, 1);
        Board = repmat(string(boardName), numRows, 1);
        Sensor = repmat(string(testPoint), numRows, 1);
        T = addvars(T, Dataset, Board, Sensor, 'Before', 1);
        fileCount = fileCount + 1;
        allData{fileCount, 1} = T;
        
        catch ME
            fprintf('error');
        end
    end
end

if ~isempty(allData)
    disp(['Merging ', num2str(fileCount), '']);
    masterTable = vertcat(allData{:});
    save('Compiled_TMR_Data.mat', 'masterTable');
    writetable(masterTable, 'Compiled_TMR_Data.csv');
    
    disp('saved');
else
    disp('no file found.');
end
