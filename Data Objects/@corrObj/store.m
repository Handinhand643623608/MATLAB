function store(corrData, varargin)
%STORE Saves the correlation data object to the hard drive.
%   This function stores the data object in a .mat file on the hard drive. If optional inputs are not provided, this
%   function generates its own path and file name to store the data under.
%
%   SYNTAX:
%   store(corrData)
%   store(corrData, 'PropertyName', PropertyValue...)
%
%   INPUT:
%   corrData:       The data object containing correlation data between EEG and fMRI modalities.
%
%   OPTIONAL INPUTS:
%   'Name':         The name of the file to be saved. If not provided, this function generates its own save name based 
%                   on various data object properties.
%
%   'Path':         The path where the file is to be saved. If not provided, this function defaults to the data object 
%                   path found in "fileStruct".
%
%   Written by Josh Grooms on 20130702
%       20130709:   Bug fix for modality tag generation being case sensitive.
%       20130728:   Added save name string generation for partial correlation data sets. Added ability to set the 
%                   variable's name (as it's saved) externally.
%       20131029:   Updated modality & GSR tag generation for file save name.
%       20131126:   Bug fix for file name generation.


%% Initialize
load masterStructs
inStruct = struct(...
    'saveName', [],...
    'savePath', [fileStruct.Paths.DataObjects '/' corrData(1, 1).Relation '/'...
                 corrData(1, 1).Modalities],...
     'varName', []);
assignInputs(inStruct, varargin,...
    'compatibility', {'saveName', 'name', [];
                      'savePath', 'path', 'dir'},...
    {'savePath'}, 'regexprep(varPlaceholder, ''(/$)'', '''');',...
    {'saveName'}, 'regexprep(varPlaceholder, ''\.\w*$'', '''');');
assignInputs(corrData(1, 1).Parameters.Correlation, 'varsOnly');


%% Generate a Name String if One is Not Provided
if isempty(saveName)
    
    % Generate names based on relation
    varName = 'corrData';
    switch lower(corrData(1, 1).Relation)
        case 'correlation'
            saveNameStr = 'corrObject';
        case 'partial correlation'
            saveNameStr = 'partialCorrObject';
    end
    
    % Determine if data is real or null
    if GenerateNull
        varName = 'nullCorrData';
        saveNameStr(1) = upper(saveNameStr(1));
        saveNameStr = ['null' saveNameStr];
    end
    
    % Determine if data has been averaged
    if corrData(1, 1).Averaged
        varName(1) = upper(varName(1));
        saveNameStr(1) = upper(saveNameStr(1));
        varName = ['mean' varName];
        saveNameStr = ['mean' saveNameStr];
    end
    
    % Get the scan state of the data
    stateTag = corrData(1, 1).ScanState;
    
    % Determine the modalities being correlated
    switch lower(corrData(1, 1).Modalities)
        case 'bold-eeg'
            modTag = cat(2, 'BOLD-', Channels{:});
        case 'bold-bold nuisance'
            modTag = 'BOLD-Nuisance';
        otherwise
            modTag = [corrData(1, 1).Modalities];
    end
    
    % Determine the bandwidth of the input data
    if isequal(corrData(1, 1).Bandwidth{1}, [0.01 0.08])
        bandTag = 'dc';
    else
        error('Unknown bandwidth of data. Update "store" function before saving');
    end  
    
    % Determine whether global signal has been regressed
    modalities = segmentModalities(corrData(1, 1).Modalities);
    if istrue(corrData(1, 1).GSR, 'all')
        gsrTag = 'GSR';
    elseif any(strcmpi(modalities, 'eeg'))
        if istrue(corrData(1, 1).GSR(strcmpi(modalities, 'eeg')))
            gsrTag = 'CSR';
        else
            gsrTag = [];
        end
    else
        gsrTag = [];
    end
    
    % Determine if the data have been z-scored
    if istrue(corrData(1, 1).ZScored)
        zTag = 'Z';
    else
        zTag = [];
    end

    % Get the data storage date
    dateTag = datestr(now, 'yyyymmdd');
        
    % Assemble the data file save name
    saveName = [saveNameStr '_' stateTag '_' modTag '_' bandTag gsrTag zTag '_' dateTag];
    clear temp*
end

% Create the directory that data is to be stored in
if ~exist(savePath, 'dir')
    mkdir(savePath)
end
saveName = [savePath '/' saveName '.mat'];


%% Store the Data
set(corrData, 'StorageDate', datestr(now, 'yyyymmddTHHMMSS'), 'StoragePath', saveName);

% Change variable name
if ~exist('varName', 'var') || isempty(varName)
    defaultAns = {'corrData'};
    varName = inputdlg('Input the name of the data object as it should be saved (e.g. corrData, meanCorrData)',...
        'Data Variable Name', 1, defaultAns);
    if iscell(varName)
        varName = varName{1};
    end
end
eval([varName '= corrData;']);

% Save the data
save(saveName, varName, '-v7.3');


end%================================================================================================
%% Nested Functions
% Segment modalities string into parsable cells
function modalities = segmentModalities(modalities)
    modalities = regexpi(modalities, '([^-]*)', 'tokens');
    modalities = cat(2, modalities{:});
end