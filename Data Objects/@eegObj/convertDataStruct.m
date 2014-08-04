function eegData = convertDataStruct(eegData, dataStruct, varargin)
%CONVERTDATASTRUCT Converts EEG data from old-style data structure into the new data objects.
%   This eegData class-specific method is a private class not intended for general-purpose use. 
% 
%   Written by Josh Grooms on 20130202
%       20130318:   Added new object properties
%       20130324:   Added a temporary section to convert data structures from save files into 
%                   objects in order to work around a current MATLAB OOP bug.
%       20130407:   MATLAB OOP bug is resolved. Removed sections converting between objects and
%                   structures.
%       20130611:   Removed a section from OOP bug that was missed. Removed a superfluous "end" from
%                   function.


%% Initialize
% Initialize a variable structure
inStruct = struct(...
    'bandwidth', [],...
    'globalRegressed', [],...
    'scanState', []);
assignInputs(inStruct, varargin,...
    'compatibility', {'globalRegressed', 'GR', 'regressedGlobal';
                      'scanState', 'stae', 'task'});

% Get the size of the input data structure (old format was (Subjects x Scans))
[numSubjects, numScans] = size(dataStruct);

% Initialize the EEG data object
tempEEGData(numSubjects, numScans) = eegObj;            

% Get the scan date from the old human_data structures
searchPath = 'E:\Graduate Studies\Lab Work\Data Sets\MAT Files\human_data\No BOLD Global Regression';
humanDataNames = fileNames(...
    'searchPath', searchPath,...
    'searchStr', 'human_data*',...
    'fileExt', '.mat');
dateExpr = '_(\d\d\d\d\d\d\d\d)_';
humanDataDates = regexp(humanDataNames, dateExpr, 'tokens');
humanDataDates = cat(1, humanDataDates{:});
humanDataDates = cat(1, humanDataDates{:});


%% Transfer the Data
for idxSubject = 1:numSubjects
    for idxScan = 1:numScans
        if ~isempty(dataStruct(idxSubject, idxScan).data)
            
            % Transfer the old EEG data into the new data object
            tempEEGData(idxSubject, idxScan).Data.EEG = dataStruct(idxSubject, idxScan).data.EEG;
            tempEEGData(idxSubject, idxScan).Data.BCG = dataStruct(idxSubject, idxScan).data.BCG;
            if isfield(dataStruct(idxSubject, idxScan).data, 'globalSignal')
                tempEEGData(idxSubject, idxScan).Data.Global = dataStruct(idxSubject, idxScan).data.globalSignal;
                tempEEGData(idxSubject, idxScan).GlobalRegressed = true;
            else
                tempEEGData(idxSubject, idxScan).Data.Global = [];
                tempEEGData(idxSubject, idxScan).GlobalRegressed = false;
            end

            % Account for variability in old naming schemes & for missing filter shift (e.g. raw data)
            if isfield(dataStruct(idxSubject, idxScan).info, 'filterShift')
                currentFilterShift = dataStruct(idxSubject, idxScan).info.filterShift;
            elseif isfield(dataStruct(idxSubject, idxScan).info, 'filter_shift')
                currentFilterShift = dataStruct(idxSubject, idxScan).info.filter_shift;
            elseif isfield(dataStruct(idxSubject, idxScan).info, 'filterSampleShift')
                currentFilterShift = dataStruct(idxSubject, idxScan).info.filterSampleShift;
            end
            
            % Determine whether or not data has been filtered
            if ~isempty(currentFilterShift) && currentFilterShift ~= 0
                tempEEGData(idxSubject, idxScan).Filtered = true;
                tempEEGData(idxSubject, idxScan).FilterShift = currentFilterShift;
            else
                tempEEGData(idxSubject, idxScan).Filtered = false;
                tempEEGData(idxSubject, idxScan).FilterShift = 0;
            end
            
            % Determine the bandwidth of the signals being processed
            if isempty(bandwidth)
                dlgStatement = {'Enter the highpass filter cutoff';
                                'Enter the lowpass filter cutoff'};
                bandwidth = inputdlg(dlgStatement, dlgTitle, 1, {'0.01', '0.08'});
                bandwidth = [eval(bandwidth{1}) eval(bandwidth{2})];
            end
            tempEEGData(idxSubject, idxScan).Bandwidth = bandwidth;
            
            % Determine the scan state of the data
            if isempty(scanState)
                dlgStatement = {'Is this resting state data?'};
                dlgResponse = questdlg(dlgStatement, 'Specify Scan State', 'Yes', 'No', 'Yes');
                if strcmp(dlgResponse, 'Yes')
                    scanState = 'RS';
                else
                    scanState = 'PVT';
                end
            end
            tempEEGData(idxSubject, idxScan).ScanState = scanState;
            
            % Transfer the old EEG info section into the new data object
            tempEEGData(idxSubject, idxScan).Channels = dataStruct(idxSubject, idxScan).info.channels;
            tempEEGData(idxSubject, idxScan).Fs = dataStruct(idxSubject, idxScan).info.Fs;
            tempEEGData(idxSubject, idxScan).Scan = dataStruct(idxSubject, idxScan).info.scan;
            tempEEGData(idxSubject, idxScan).ScanDate = humanDataDates{idxSubject};                
            tempEEGData(idxSubject, idxScan).Subject = dataStruct(idxSubject, idxScan).info.subject;        
        
        end
    end
end
eegData = tempEEGData;