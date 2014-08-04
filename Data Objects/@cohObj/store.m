function store(cohData, varargin)
%STORE Saves the coherence data object to the hard drive.
%   This function stores the data object in a .mat file on the hard drive. If optional inputs are
%   not provided, this function generates its own path and file name to store the data under. 
%
%   SYNTAX:
%   store(cohData)
%   store(cohData, 'PropertyName', PropertyValue,...)
%
%   INPUTS:
%   cohData:        The coherence data object.
%
%   OPTIONAL INPUTS:
%   'Name':       A string of the desired name of the save file generated. If one is not provided,
%                 this function generates a name automatically using the data parameters.
%
%   'Path':       The desired path to which data is saved. If not provided, a default is used.
%                 DEFAULT: [fileStruct.Paths.DataObjects '\' cohData.Relation]
%
%   'VarName':    The name of the data object variable found within the .mat file being saved. This
%                 can be inputted if the variable name is ambiguous (i.e. a file name is provided
%                 instead of generated).
%                 DEFAULT: automatically determined from data parameters
%
%   Written by Josh Grooms on 20130614
%       20130919:   Updated path separators for compatibility with Linux systems.
%       20131001:   Updated to automatically save partial coherence objects.
%       20131103:   Updated modality & GSR tag generation for file save name.
%       20140203:   Bug fix for GSR file name tag not being generated under certain circumstances.


%% Initialize
load masterStructs
inStruct = struct(...
    'saveName', [],...
    'savePath', [fileStruct.Paths.DataObjects '/' cohData(1, 1).Relation],...
    'varName', []);
assignInputs(inStruct, varargin,...
    'compatibility', {'saveName', 'name', [];
                      'savePath', 'path', 'dir'},...
    {'savePath'}, 'regexprep(varPlaceholder, ''(/$)'', '''');',...
    {'saveName'}, 'regexprep(varPlaceholder, ''\.\w*$'', '''');');


%% Generate a Name String if One is Not Provided
if isempty(saveName)
    
    % Generate a name based on relation
    varName = 'cohData';
    switch lower(cohData(1, 1).Relation)
        case 'ms coherence'
             saveNameTag = 'cohObject';
        case 'partial coherence'
            saveNameTag = 'partialCohObj';
    end
    
    % Determine if data is real or null
    if cohData(1, 1).Parameters.Coherence.GenerateNull
        varName = 'nullCohData';
        saveNameTag(1) = upper(saveNameTag(1));
        saveNameTag = ['null' saveNameTag];
    end
    
    % Determine if data has been averaged
    if cohData(1, 1).Averaged
        varName(1) = upper(varName(1));
        saveNameTag(1) = upper(saveNameTag(1));
        varName = ['mean' varName];
        saveNameTag = ['mean' saveNameTag];
    end
    
    % Get the scan state of the data
    stateTag = cohData(1, 1).ScanState;
    
    % Determine the modalities for coherence
    switch lower(cohData(1, 1).Modalities)
        case 'bold-eeg'
            modTag = cat(2, 'BOLD-', cohData(1, 1).Parameters.Coherence.Channels{:});            
        otherwise
            modTag = [cohData(1, 1).Modalities];
    end
    
    % Determine the bandwidth of the input data
    if isequal(cohData(1, 1).Bandwidth{1}, [0.01 0.08])
        bandTag = 'dc';
    elseif isequal(cohData(1, 1).Bandwidth{1}, [0 0.5]) || strcmpi(cohData(1, 1).Bandwidth{1}, 'fb')
        bandTag = 'fb';
    end
    
    % Determine whether global signal has been regressed
    modalities = segmentModalities(cohData(1, 1).Modalities);
    gsrTag = [];
    if istrue(cohData(1, 1).GSR, 'all')
        gsrTag = 'GSR';
    elseif any(strcmpi(modalities, 'eeg'))
        if istrue(cohData(1, 1).GSR(strcmpi(modalities, 'eeg')))
            gsrTag = 'CSR';
        end
    end
    
    % Get the data storage date    
    dateTag = datestr(now, 'yyyymmdd');
    
    % Assemble the data file save name
    saveName = [saveNameTag '_' stateTag '_' modTag '_' bandTag gsrTag '_' dateTag];
end

% Use a default save path if one is not provided
if ~exist(savePath, 'dir')
    mkdir(savePath)
end
saveName = [savePath '/' saveName '.mat'];


%% Store the Data
set(cohData, 'StorageDate', datestr(now, 'yyyymmddTHHMMSS'), 'StoragePath', saveName);

% Change variable name
if ~exist('varName', 'var')
    defaultAns = {'cohData'};
    varName = inputdlg('Input the name of the data object as it should be saved (e.g. cohData, meanCohData)',...
        'Data Variable Name', 1, defaultAns);
    if iscell(varName)
        varName = varName{1};
    end
end
eval([varName '= cohData;']);

% Save the data
save(saveName, varName, '-v7.3');


end%================================================================================================
%% Nested Functions
% Segment modalities string into parsable cells
function modalities = segmentModalities(modalities)
    modalities = regexpi(modalities, '([^-]*)', 'tokens');
    modalities = cat(2, modalities{:});
end