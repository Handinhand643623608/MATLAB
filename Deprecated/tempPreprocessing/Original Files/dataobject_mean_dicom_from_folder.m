function data_object = dataobject_mean_dicom_from_folder(data_object)
% DATAOBJECT_MEAN_DICOM_FROM_FOLDER
% Creates a mean image as the last dicom image in a folder
%
% mean_dicom_filename =                 Name of file output
% mean_dicom_from_folder(
%                       data_object      See preprocess.m for format
%                       )
% FILE OUTPUT
% A mean dicom file
% 

% Extract data from data structure
folder_name = data_object.files.functional_folder;
num_file_slices = data_object.files.num_file_slices;

% Make a folder for the mean
mkdir([folder_name 'mean']);

% Append / to the end of the directory name, if missing
if folder_name(end) ~= '/'
    folder_name = [folder_name '/'];
end

% Load the entire directory
[dcm,dicom_info] = readDicomDirectory(folder_name,num_file_slices,[-Inf Inf]);
% Take the mean of the dicom in the "time" dimension
mn = mean(dcm,4);

% A constant - the filename for the mean
mean_filename = 'mean/mean.dcm';

% If the file already exists, ask before writing
if exist([folder_name mean_filename],'file')
    overwrite = '';
    while ~(strcmp(overwrite,'y') || strcmp(overwrite,'n'))
        overwrite = input(['File ' mean_filename ' already exists.  Input ''y'' to overwrite, ''n'' otherwise']);
        overwrite = lower(overwrite);
    end
    if strcmp(overwrite,'y')
        delete([folder_name mean_filename]);
    end
else
    overwrite = 'y';
end

% If prompted to overwrite, or if it doesn't exist, write the file
if strcmp(overwrite,'y')
    dicomwrite(uint16(round(mn)),[folder_name mean_filename],dicom_info,'CreateMode','copy','WritePrivate',true);
end
% Save for output
data_object.files.mean_dicom_filename = [folder_name mean_filename];