function store(relationData, varargin)
%STORE Saves the relation data object to the hard drive.
%
%   SYNTAX:
%   store(relationData, 'PropertyName', PropertyValue,...)
%
%   INPUTS: (values in parentheses are optional)
%   relationData:
%
%   ('Name'):       A string of the desired name of the save file generated. If one is not provided,
%                   this function generates a name automatically using the data parameters.
%
%   ('Path'):       The desired path to which data is saved. If not provided, a default is used. 
%   
%   Written by Josh Grooms on 20130428
%       20130611:   Updated the help & reference section.
%       20130613:   Updated to allow saving of null coherence data and mean coherence data. 


%% Initialize
inStruct = struct(...
    'saveName', [],...
    'savePath', ['E:\Graduate Studies\Lab Work\Data Sets\Data Objects\' relationData(1, 1).Relation]);
assignInputs(inStruct, varargin,...
    'compatibility', {'saveName', 'name', [];
                      'savePath', 'path', 'dir'},...
    {'savePath'}, 'regexprep(varPlaceholder, ''(\\$)'', '''')',...
    {'saveName'}, 'regexprep(varPlaceholder, ''\.\w*$'', '''')');


%% Generate a Name String if One is Not Provided
if isempty(saveName)
    dateID = datestr(now, 'yyyymmdd');
    maskTag = [];
    
    % Determine the relationship being examined
    switch lower(relationData(1, 1).Relation)
        case 'coherence'
            if relationData(1, 1).Parameters.GenerateNull
                dataStr = 'nullCohData';
                tempSaveStr = 'nullCohObject';
            else                
                dataStr = 'cohData';
                tempSaveStr = 'cohObject';
            end
            
            if isequal(size(relationData), [1, 1])
                dataStr(1) = upper(dataStr(1));
                tempSaveStr(1) = upper(tempSaveStr(1));
                dataStr = ['mean' dataStr];
                tempSaveStr = ['mean' tempSaveStr];
            end
            
            switch lower(relationData(1, 1).Parameters.MaskMethod)
                case {'correlation', 'corrdata', 'corr', 'xcorrdata', 'xcorr'}
                    maskTag = '_corrMask';                    
                case {'rsn', 'rsns', 'ic', 'ics'}
                    maskTag = '_rsnMask';                            
                case {'seed', 'manual', 'seedregion', 'region'}
                    maskTag = '_seedMask';
            end
            
        case 'correlation'
            dataStr = 'corrData';
            tempSaveStr = 'corrObject';
    end
    dataName = [tempSaveStr maskTag];
    clear temp*    
    
    % Get the scan state of the data
    saveTag = relationData(1, 1).ScanState;
    
    % Get the specific modalities being analyzed
    switch relationData(1, 1).Modalities
        case 'EEG-BOLD'
            modTag = [cat(2, relationData(1, 1).Parameters.Channels{:}) '-BOLD'];
        otherwise
            modTag = relationData(1, 1).Modalities;
    end
    saveTag = [saveTag '_' modTag];
    
    % Determine the bandwidth of the input data
    if relationData(1, 1).Filtered
        bandwidth = relationData(1, 1).Bandwidth;
        if isequal(bandwidth, [0.01 0.08])
            saveTag = [saveTag '_dc'];
        else
            error('Unknown bandwidth of data. Update "store" function before saving');
        end
    else
        saveTag = [saveTag '_fb'];
    end
            
    % Determine whether global signal has been regresed
    if relationData(1, 1).GlobalRegressed
        saveTag = [saveTag 'GR'];
    end
    
    % Determine if z-scoring has been done
    if relationData(1, 1).ZScored
        saveTag = [saveTag 'Z'];
    end
    
    saveName = [dataName '_' saveTag '_' dateID];
end

% Use a default save path if one is not provided
if ~exist(savePath, 'dir')
    mkdir(savePath)
end
saveName = [savePath '\' saveName '.mat'];


%% Store the Data
set(relationData, 'StorageDate', datestr(now, 'yyyymmddTHHMMSS'), 'StoragePath', saveName);

% Change variable name
if ~exist('dataStr', 'var')
    switch lower(relationData(1, 1).Relation)
        case 'coherence'
            defaultAns = {'cohData'};
        case 'correlation'
            defaultAns = {'corrData'};
    end
    dataStr = inputdlg('Input the name of the data object as it should be saved (e.g. corrData, cohData)',...
        'Data Variable Name', 1, defaultAns);
    if iscell(dataStr)
        dataStr = dataStr{1};
    end
end
eval([dataStr '= relationData;']);

% Save the data
save(saveName, dataStr, '-v7.3');