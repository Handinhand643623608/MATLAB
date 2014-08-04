function store(spectralData, varargin)
%STORE Save the spectral data object to the specified path
% 
%   Written by Josh Grooms on 20130910
%       20140205:   Updated banwidth tag strings for save name generation.


%% Initialize
% Error check
if ~isa(spectralData, 'spectralObj')
    error('Input data object is not of class "spectralObj" and cannot be stored using this function.')
end

% Initialize the defaults structure
load masterStructs
inStruct = struct(...
    'saveName', [],...
    'savePath', [fileStruct.Paths.DataObjects '/' 'Spectra'],...
    'varName', []);
assignInputs(inStruct, varargin,...
    {'savePath'}, 'regexprep(varPlaceholder, ''(/$)'', '''');',...
    {'saveName'}, 'regexprep(varPlaceholder, ''\.\w*$'', '''');');

% Create a name string if one is not provided
if isempty(saveName)
    
    % Generate a variable name
    varName = 'spectralData';
    fileName = 'spectralObject';
    if spectralData(1, 1).Averaged
        varName(1) = upper(varName(1)); varName = ['mean' varName];
        fileName(1) = upper(fileName(1)); fileName = ['mean' fileName];
    end
    
    % Get the scan state of the data
    stateTag = spectralData(1, 1).ScanState;
   
    % Determine the bandwidth of the input EEG data
    eegBand = spectralData(1, 1).Parameters.Initialization.Bandwidth;
    if ischar(eegBand)
        bandTag = eegBand;
    elseif isequal(eegBand, [0.01 0.08])
        bandTag = 'dc';
    elseif isequal(eegBand, [0.01 0.5])
        bandTag = 'wbdc';
    elseif isequal(eegBand, [0.01 0.1])
        bandTag = 'isf';
    end
    
    % Determine whether global signal regression has been performed
    gsrTag = [];
    if istrue(spectralData(1, 1).GSR)
        gsrTag = 'GR';
    end 
    
    % Determine which EEG channels were used
    channelTag = cat(2, spectralData(1, 1).Channels{:});
    
    % Get the storage date
    dateTag = datestr(now, 'yyyymmdd');
   
    % Assemple the data file save name
    saveName = [fileName '_' stateTag '_'  bandTag gsrTag '_' channelTag '_' dateTag];

end

% Create the directory that data is to be stored in
if ~exist(savePath, 'dir')
    mkdir(savePath);
end
saveName = [savePath '/' saveName '.mat'];


%% Store the Data
set(spectralData, 'StorageDate', datestr(now, 'yyyymmddTHHMMSS'), 'StoragePath', saveName);

% Change variable name
if ~exist('varName', 'var') || isempty(varName)
    defaultAns = {'spectralData'};
    varName = inputdlg('Input the name of the data object as it should be saved (e.g. spectralData, meanSpectralData)',...
        'Data Variable Name', 1, defaultAns);
    if iscell(varName)
        varName = varName{1};
    end
end
eval([varName '= spectralData;']);

% Save the data
save(saveName, varName)

