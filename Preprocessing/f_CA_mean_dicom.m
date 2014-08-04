function [BOLD_data fileStruct] = f_CA_mean_dicom(BOLD_data, fileStruct)

% F_CA_MEAN_DICOM Creates a mean fMRI image and saves it into the data
%   directory.
%
%   Syntax:
%   data_output = f_CA_mean_dicom(data_input, param_struct, file_struct)
%
%   DATA_INPUT: A BOLD data structure
%   PARAM_STRUCT (OPTIONAL): The global parameter structure
%   FILE_STRUCT (OPTIONAL): The global file structure
% 
%   Written by Garth Thompson
%       Modified heavily by Josh Grooms on 6/13/2012 to operate with the
%       complete analysis package.
%       Modified heavily on 6/30/2012 to accomodate parallel computing

%% Initialize
% Initialize function-specific parameters
subject = BOLD_data.info.subject;
scan = BOLD_data.info.scans;
num_file_slices = 1;

%% Create the mean DICOM & save

% Extract the functional folder path
functional_path = fileStruct.paths.raw_functional{subject}{scan};

% Make a folder for the mean
cd(functional_path)
mkdir('mean')

% Load the directory
[dcm, dicom_info] = readDicomDirectory(functional_path, num_file_slices, [-Inf Inf]);

% Take the mean of the DICOM in the 4th (time) dimension
mn = mean(dcm,4);

% Create a filename for the mean
mean_filename = 'mean/mean.dcm';

% If the file already exists, ask before writing
if exist([functional_path '/' mean_filename],'file')
    overwrite = '';
    while ~(strcmp(overwrite,'y') || strcmp(overwrite,'n'))
        overwrite = input(['File ' mean_filename ' already exists.  Input ''y'' to overwrite, ''n'' otherwise']);
        overwrite = lower(overwrite);
    end
    if strcmp(overwrite,'y')
        delete([functional_path '/' mean_filename]);
    end
else
    overwrite = 'y';
end

% If prompted to overwrite, or if it doesn't exist, write the file
if strcmp(overwrite,'y')
    dicomwrite(uint16(round(mn)),[functional_path '/' mean_filename],dicom_info,'CreateMode','copy','WritePrivate',true);
end

% Save for output
fileStruct.files.mean{subject}{scan} = [functional_path '/' mean_filename];

% Save structures
save([fileStruct.paths.main '/tempFileStruct.mat'], 'fileStruct');

