function ToIMG(boldData, savePath)
%TOIMG Converts BOLD data matrices to NIFTI .img format.
%   This function converts the functional images in BOLD data objects to IMG files that are used by other programs, such
%   as GIFT. It extracts the 4-dimensional numerical array (functional volumes over time) and creates one IMG file for
%   every time point available. 
%
%   The outputted IMG files are numbered sequentially according to the time point their volume represents. They are
%   stored in folders organized by subject and scan numbers (the preferred format for GIFT). All of these
%   subject and scan folders can be found inside one top-level folder called "Preprocessed IMG Files", which is placed
%   in either a user-specified directory or wherever BOLD objects were stored after preprocessing.
%
%   INPUT
%   boldData:       BOLDOBJ
%                   A BOLD data object or array of objects containing functional data that should be converted to IMG
%                   files.
%
%   OPTIONAL INPUT:
%   savePath:       STRING
%                   A string indicating the top-level directory where all IMG files will be stored. If no path string is
%                   provided, this location will default to wherever the inputted data objects were stored after
%                   preprocessing was performed. 
%
%                   DEFAULT: boldData(1).Preprocessing.Parameters.General.OutputPath


%% CHANGELOG
% Written by Josh Grooms on 20130324
%       20131027:   Added the current date to the output folder string to prevent data overwrites. Updated progress bar 
%                   syntax.
%       20140612:   Complete overhaul of this function. The original was very old and contained a number of
%                   functionalities that were obsolete. This new version is also coded to be much more efficient.
%       20140623:   Updated to make use of the new static method for converting 4D arrays into IMG format. 



%% Create IMG Files from BOLD Data
% Create a default path for saving IMG files to if not inputted
if nargin == 1
    savePath = [boldData(1).Preprocessing.Parameters.General.OutputPath '/Preprocessed IMG Files'];
end
                  
% Create the IMG files (one file for every time point)
pbar = progress('Converting BOLD Data to IMG Files');
for a = 1:numel(boldData)
    % Organize files into specific subject & scan folders
    currentSaveFolder = [savePath '/Subject ' num2str(boldData(a).Subject) '/Scan ' num2str(boldData(a).Scan)];
    if ~exist(currentSaveFolder, 'dir'); mkdir(currentSaveFolder); end
    
    % Pull the functional data from the object & write IMG files
    boldObj.ArrayToIMG(ToArray(boldData(a), currentSaveFolder));
    
    update(pbar, a/numel(boldData));
end
close(pbar);