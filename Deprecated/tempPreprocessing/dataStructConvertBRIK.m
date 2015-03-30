function dataStruct = dataStructConvertBRIK(dataStruct)
%DATASTRUCTCONVERTBRIK Converts BRIK images from AFNI into the SPM-compatible NIFTI format.
%   This function uses AFNI to convert images from BRIK format into ANALYZE format, which is
%   compatible with the SPM preprocessing used in later steps. Because this function uses AFNI, it
%   is only compatible with computers running the Linux operating system.
%
%   SYNTAX:
%   dataStruct = dataStructConvertBRIK(dataStruct)
%   
%   OUTPUT:
%   dataStruct:     The human data structure with a new reference to the converted mean data image
%                   and a string to search for AFNI corrected files needed by SPM later on.
%
%   INPUT:
%   dataStruct:     A human data structure.
%
%   Written by Josh Grooms on 20130701


%% Initialize

% Get folder paths from data structure
functionalFolder = dataStruct.Files.FunctionalFolder;
meanFolder = [functionalFolder '/mean'];
imgFolder = dataStruct.Files.IMGFolder;

% Get .BRIK filenames
brikFile = fileData(functionalFolder, 'ext', '.BRIK', 'Search', 'tshift_reg');
meanBRIKFile = fileData(meanFolder, 'ext', '.BRIK');

% AFNI file names
afniName = 'tshift_reg';
meanAFNIName = 'mean_template';

% Get the current working directory to easily switch back to it later
origDir = pwd;


%% Convert AFNI Images to NIFTI Format
cd(functionalFolder)

% Run the conversion
system(['3dAFNItoANALYZE -orient rpi ' afniName ' ' brikFile.Name]);

% Move files to the IMG folder
movefile([functionalFolder afniName '_*.img'], imgFolder);
movefile([functionalFolder afniName '_*.hdr'], imgFolder);

% Now convert the mean image
cd(meanFolder)
system(['3dAFNItoANALYZE -orient rpi ' meanAFNIName ' ' meanBRIKFile.Name]);

% Overwrite the structure's mean image with the converted one
dataStruct.Files.IMG.Mean = get(fileData(meanFolder, 'ext', '.img'), 'Path');

% Switch back to the original directory
cd(origDir)

% Save a search string for use in SPM
dataStruct.Files.IMG.FunctionalStr = afniName;