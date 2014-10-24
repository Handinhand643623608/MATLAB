function Store(H, varargin)
% STORE - Saves an image of the plot in the specified format.
%   This function saves images BRAINPLOT objects in one or more formats as specified by the user. Each generated image
%   is the same size as the MATLAB figure (default full-screen) and should appear exactly the same when opened up. Save
%   to PDFs or FIG files to retain infinite resolution where applicable.
%
%   SYNTAX:
%   Store(brainData)
%   Store(brainData, 'PropertyName', PropertyValue...)
%
%   INPUT:
%   brainData:      BRAINPLOT
%                   A brain plot object or array of objects that are to be saved as images. 
%
%   OPTIONAL INPUTS:
%   'Ext':          STRING or {STRINGS}
%                   A string or cell array of strings indicating the format that the images are to be stored in. If
%                   multiple formats are desired, input a cell array containing the format strings.
%                   DEFAULT: 'png'
%
%                   EXAMPLE:
%                            Store(brainData, 'ext', 'png');             % Store image in PNG format only
%                            Store(brainData, 'ext', {'fig', 'png'})     % Store image in both PNG & FIG formats
%
%                   OPTIONS: Any MATLAB-native format from the SAVEAS function.
%                           'bmp'
%                           'eps'
%                           'fig'
%                           'jpg'
%                           'png'
%                           'tif'
%                   
%   'Name':         STRING or {STRINGS}
%                   A string or cell array of strings containing the name(s) of the images being stored. These are the
%                   file names that the user will see. If multiple plot windows are being stored at once (from a
%                   brainData array), input individual ordered plot titles as a cell array. The default value of this
%                   parameter is a string representing the exact time that the save occurred for each image. 
%                   DEFAULT: datestr(now, 'yyyymmddHHMMSSFFF')
%
%                   EXAMPLE:
%                            % If brainData is a single BRAINPLOT object, store a single image
%                            Store(brainData, 'Name', 'Brain Image');
%
%                            % If brainData is a BRAINPLOT of length 2, store both images with separate file names
%                            Store(brainData, 'Name', {'BrainImage1', 'BrainImage2'});
%
%   'Overwrite':    BOOLEAN
%                   A Boolean indicating whether or not any existing files with the same name should be overwritten when
%                   the inputted brain montage is being saved as an image to the hard drive. Setting this to true will
%                   overwrite any pre-existing images with the same file names.
%                   DEFAULT: false
%
%   'Path':         STRING
%                   The path string referencing where the images are to be stored. The default value of this parameter
%                   saves images to the same folder that the BRAINPLOT code is located in.
%                   DEFAULT: which('brainPlot.m')
%   
%   See also SAVEAS

%% CHANGELOG
%   Written by Josh Grooms on 20130711
%       20130718:   Updated default save path to a folder named "brainPlot" on the desktop to more easily organize 
%                   saves.
%       20140625:   Implemented protection against ovrewriting existing data files. If an overwrite is desired, the user
%                   must specify this through a new Overwrite input argument toggle. Made major improvements to the
%                   documentation of this function. Removed dependencies on my personal file structure. Removed random
%                   file name generation when no save name is inputted. This was replaced with a date string
%                   representing exactly when the save occurs (down to the millisecond to prevent overwrite errors).
%       20140718:   Bug fix for crashing during error throwing when image file names already exist.



%% Initialize
[defaultPath, ~, ~] = fileparts(which('brainPlot.m'));
inStruct = struct(...
    'Ext', {{'png'}},...
    'Overwrite', false,...
    'SaveName', {cell(size(H))},...
    'SavePath', defaultPath);
assignInputs(inStruct, varargin,...
    'compatibility', {'Ext', 'extension', 'format';
                      'SaveName', 'name', 'filename';
                      'SavePath', 'path', 'dir'},...
    {'SavePath'}, 'regexprep(varPlaceholder, ''(/$)'', '''');',...
    {'SaveName'}, 'regexprep(varPlaceholder, ''\.\w*$'', '''');',...
    {'Ext'}, 'regexprep(varPlaceholder, ''\.^'', '''');');

% Create the directory that data is to be stored in
if ~exist(SavePath, 'dir'); mkdir(SavePath); end

% Make the extension save name parameters cells
if ~iscell(Ext); Ext = {Ext}; end;
if ~iscell(SaveName); SaveName = {SaveName}; end;


%% Generate a Name String if One is Not Provided
% Loop through brainData array in case there are multiple plots
for a = 1:numel(H)
    for b = 1:length(Ext)
        if isempty(SaveName{a}) && isempty(H(a).Title)
            % Use a random name if there is no plot title or user input
            fullSaveName{a}{b} = [SavePath '/' datestr(now, 'yyyymmddHHMMSSFFF') '.' Ext{b}];
        elseif isempty(SaveName{a})
            fullSaveName{a}{b} = [SavePath '/' H(a).Title '.' Ext{b}];
        else
            fullSaveName{a}{b} = [SavePath '/' SaveName{a} '.' Ext{b}];
        end
    end
end


%% Store the Image(s)
for a = 1:length(H)
    for b = 1:length(Ext)
        if exist(fullSaveName{a}{b}, 'file') && ~istrue(Overwrite)
            [filePath, fileName, ~] = fileparts(fullSaveName{a}{b});
            error(['A file with the name "%s" already exists in %s.\n'...
                   'Choose a different file name for the image or use the overwrite parameter of this function.'],...
                   fileName,...
                   filePath);
        end
        saveas(H(a).FigureHandle, fullSaveName{a}{b}, Ext{b});
    end
end
