function Store(dataObject, varargin)
%STORE - Saves a data object to the hard drive.
%   This function creates two standard MAT files (.mat) representing a human data object on the hard drive. Both files
%   are stored either at the user-specified location or, by default, wherever the current working path is. 
%   
%   The first stored file contains all of the data from the object (found under the "Data" property). The object "Data"
%   property is then overwritten with a reference to this new file through the MATFILE function. In this way, data can
%   be freely accessed in exactly the same manner as before except that theres is now no need to load the entire data
%   set first. This nearly eliminates the once lengthy loading times required for each individual object, especially
%   when applying operations that only require a subset of the data at any given time.
%
%   The second of the two files being stored contains the data object itself, stripped of its large data sets. This file
%   will be very small in size because it almost exclusively contains metadata about the other file. 
%
%   To utilize the data after storage, load only the data object file (typically the smaller of the two) using the usual
%   LOAD function in MATLAB. There should never be a need to explicitly load the data file associated with the object;
%   this is done automatically when indexing into the data.
%
%   SYNTAX:
%   store(dataObject)
%   store(dataObject, 'PropertyName', PropertyValue)
%
%   INPUT:
%   dataObject:     HUMANOBJ
%                   A single human data object.
%
%   OPTIONAL INPUTS:
%   'Name':         STRING
%                   A string that will become the name of the MAT file containing the inputted data object. If this
%                   variable is not provided as an input, a name for the data file is automatically generated using
%                   object properties and the date on which the save is occurring (in YYYYMMDD format).
%                   DEFAULT ("boldObject" is used here as an example): 
%                            'boldObject-X-Y_S_D.mat'    - The data object.
%                                                          > X: Subject number
%                                                          > Y: Scan number
%                                                          > S: Scan state
%                                                          > D: Save date
%                            'boldData-X-Y_S_D.mat'      - The data file (same format as object).
%
%   'Overwrite':    BOOLEAN
%                   A Boolean indicating whether or not any existing files with the same name should be overwritten when
%                   the inputted data object is saved to the hard drive.
%                   DEFAULT: false
%
%   'Path':         STRING
%                   A path string indicating which directory the MAT file should be stored in. If this variable is not
%                   provided as an input, this function defaults to using the current working path.
%                   DEFAULT: pwd

%% CHANGELOG
%   Written by Josh Grooms on 20140711
%       20140711:   Adapted from STORE functions that existed separately for both EEG and BOLD data objects. As time
%                   passed, the functionality of these separate methods began to converge. At the time of this method's
%                   creation, they were nearly identical, and so this superclass method was created to replace them.



%% Error Check
% Ensure that the input is a human data object
if ~isa(dataObject, 'humanObj')
    error('Input data object is not of class "humanObj" and cannot be stored using this function.')
end

% Ensure that only single data objects are inputted
if numel(dataObject) ~= 1
    error('Only one data object may be saved at a time.');
end



%% Initialize
% Initialize default values & settings
inStruct = struct(...
    'Overwrite', false,...
    'SaveName', [],...
    'SavePath', pwd);
assignInputs(inStruct, varargin,...
    'compatibility', {'SaveName', 'name', [];
                      'SavePath', 'path', 'dir'},...
    {'SavePath'}, 'regexprep(varPlaceholder, ''(/$)'', '''');',...
    {'SaveName'}, 'regexprep(varPlaceholder, ''\.\w*$'', '''');');

% Get the type of data being stored
if isa(dataObject, 'boldObj')
    objectFileName = 'boldObject'; 
    dataVarName = 'boldData';
elseif isa(dataObject, 'eegObj'); 
    objectFileName = 'eegObject'; 
    dataVarName = 'eegData';
else
    error('Input data object class "%s" is not recognized by the Store function and cannot be saved', class(dataObject));
end

% Load any MATFILE data
if isa(dataObject, 'matlab.io.MatFile')
    dataObject.Data = load(dataObject.Data.Properties.Source);
end

% Create a name string if one is not provided
if isempty(SaveName)
    saveDate = datestr(now, 'yyyymmdd');
    
    % Get the scan state of the data
    saveState = dataObject.ScanState;
    
    % Get the subject of the data set being stored
    subject = dataObject.Subject;
    scan = dataObject.Scan;
    
    % Generate save names for the object & data
    SaveName = sprintf('%s/%s-%d-%d_%s_%s.mat', SavePath, objectFileName, subject, scan, saveState, saveDate);   
    DataSaveName = sprintf('%s/%s-%d-%d_%s_%s.mat', SavePath, dataVarName, subject, scan, saveState, saveDate);
else
    DataSaveName = [SavePath '/' 'Data_' SaveName '.mat'];
    SaveName = [SavePath '/' SaveName '.mat'];
end

% Create the save directory if it doesn't already exist
if ~exist(SavePath, 'dir'); mkdir(SavePath); end



%% Store the Data
set(dataObject, 'StorageDate', datestr(now, 'yyyymmddHHMMSS'), 'StoragePath', SaveName);

% Save the data
if exist(SaveName, 'file') && ~istrue(Overwrite)
    [filePath, fileName, ~] = fileparts(SaveName);
    error(['A file with the name "%s" already exists in %s.\n'...
           'Choose a different file name for the data object or use the overwrite parameter of this function.'],...
           fileName,...
           filePath);
else
    Data = dataObject.Data;
    save(DataSaveName, '-struct', 'Data', '-v7.3');
    dataObject.Data = matfile(DataSaveName);
    eval([dataVarName ' = dataObject;']);
    save(SaveName, dataVarName, '-v7.3');
end