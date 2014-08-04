function assignProperties(dataObject, varargin)
%ASSIGNPROPERTIES Assigns EEG data object properties based on constructor inputs.

%   Written by Josh Grooms on 20130321


%% Initialize
% Initialize the defaults structure
inStruct = struct(...
    'Bandwidth', [],...
    'BCG', [],...
    'Channels', [],...
    'EEG', [],...
    'Filtered', [],...
    'FilterShift', [],...
    'Fs', [],...
    'Global', [],...
    'GlobalRegressed', [],...
    'Subject', [],...
    'Scan', [],...
    'ScanDate', [],...
    'ScanState', []);
assignInputs(inStruct, varargin, 'structOnly',...
    'compatibility', {'Channels', 'electrodes', 'labels';
                      'EEG', 'eegData', 'data';
                      'FilterShift', 'phaseShift', 'delay';
                      'Fs', 'samplingFreq', 'sampleFreq';
                      'Global', 'globSig', 'globalData';
                      'GlobalRegressed', 'GR', 'regressedGlobal';
                      'ScanDate', 'date', 'scannedOn';
                      'ScanState', 'state', 'task'});
                  
                  
%% Fill In Object Properties
if ~isempty(inStruct.EEG)
    % Error out if input data is not a matrix
    if ~ismatrix(inStruct.EEG)
        error(['Input "data" must be an array of EEG data of the form (Channels x Time)'...
               ' or a structure of EEG data plus information'])
    end

    % Correct the orientation of the data matrix, if necessary
    szData = size(inStruct.EEG);
    dimChannels = find(szData == length(inStruct.Channels));
    if dimChannels == 2
        inStruct.EEG = inStruct.EEG';
    end

    % Get the object property names
    propNames = fieldnames(inStruct);
    
    for i = 1:length(propNames)
        switch propNames{i}
            % Fill in the data section of the object
            case {'BCG', 'EEG', 'Global'}
                % If global signal or BCG is a column vector, transpose
                if iscolumn(inStruct.(propNames{i}))
                    inStruct.(propNames{i}) = inStruct.(propNames{i})';
                end
                
                % If data field is empty, error out
                if strcmp(propNames{i}, 'EEG') && isempty(inStruct.(propNames{i}))
                    error(['Value not provided for "' propNames{i} '".']);
                else
                    dataObject.Data.(propNames{i}) = inStruct.(propNames{i});
                end
                
            case {'ScanDate'}
                % Get the original scan date of the data
                if isempty(inStruct.ScanDate)
                    scanFiles = fileData('path', 'E:\Graduate Studies\Lab Work\Data Sets\MAT Files\human_data\No BOLD Global Regression');
                    fileNames = get(scanFiles, 'Name', 'search', 'human_data');
                    dateExpr = '_(\d\d\d\d\d\d\d\d)_';
                    humanDataDates = regexp(fileNames, dateExpr, 'tokens');
                    humanDataDates = cat(1, humanDataDates{:});
                    scanDates = cat(1, humanDataDates{:});
                    dataObject.ScanDate = scanDates{inStruct.Subject};
                else
                    dataObject.ScanDate = scanDate;
                end
                
            % Fill in property values
            otherwise
                if isempty(inStruct.(propNames{i}))
                    error(['Value not provided for "' propNames{i} '".']);
                else
                    dataObject.(propNames{i}) = inStruct.(propNames{i});
                end
        end
    end
else
    error('EEG data must be provided to create the data object')
end