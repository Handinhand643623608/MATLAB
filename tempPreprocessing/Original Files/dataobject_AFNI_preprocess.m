function data_object = dataobject_AFNI_preprocess(data_object,nslices,order,ii)
% DATAOBJECT_AFNI_PREPROCESS
% Uses AFNI to pre-process DICOM files
%
% data_object = preprocess_Siemens(data_object,nslices,...)
%
% nslices is number of slices
%
% ... is AFNI parameters, which are optional
% order, ii
%

% Extract data
img_mean = data_object.files.mean_dicom_filename;
num_file_slices = data_object.files.num_file_slices;
functional_folder = data_object.files.functional_folder;

% First get dicom information from mean image
info = dicominfo(img_mean);
% The total number of slices in each file is the number of slices in that
% file times the number of files
if ~exist('nslices','var')
    nslices = num_file_slices * ((double(info.Width) * double(info.Height)) / prod(double(info.AcquisitionMatrix(info.AcquisitionMatrix ~= 0))));
end
% The repetition time is in ms standard
TR = info.RepetitionTime;

% Find the number of time points
% Get the dicom files in the directory
dicom_files = dir([functional_folder '*.dcm']);
% Number of files
nt = length(dicom_files);
% Output filename
output_filename = fnpart(info.ProtocolName);

% Missing arguments
if ~exist('ii','var')
    ii = 15;
end
if ~exist('order','var')
    if (mod(nslices, 2) == 0)
        order = 'alt+z2';
    else
        order = 'alt+z';
    end
end

% Determine if running a true mean or a single image as mean
[dirpart namepart extpart] = segment_filename(img_mean);
% Get the file number
file_number = floor((numpart(namepart)));

% Save the current directory so can switch back if an error occurs
old_directory = pwd;
try
    % Switch to the functional images folder
    cd(functional_folder);
    % RM out files
    delete([output_filename, '*BRIK']);
    delete([output_filename, '*HEAD']);
    delete([output_filename, '*1D']);
    if exist('mean','dir')
        delete([output_filename, 'mean/*BRIK']);
        delete([output_filename, 'mean/*HEAD']);
        delete([output_filename, 'mean/*1D']);
    end

    % Convert functional data to 3D AFNI format
    cmd = sprintf('to3d -epan -time:zt %d %d %f %s -prefix %s *.dcm', nslices, nt, TR, order, output_filename);
    system(cmd);
    % Run only if using a separate mean image
    if exist('mean','dir')
        cd('mean');
        % Convert mean image to AFNI 3D format
        cmd = sprintf('to3d -epan -time:zt %d %d %f %s -prefix %s *.dcm', nslices, 0, TR, order, 'mean');
        system(cmd);
        cd('..');
    end
    
    % Time shift
    cmd = sprintf('3dTshift -Fourier -ignore %d -prefix %s_tshift %s+orig', ii, output_filename, output_filename);
    system(cmd);
    
    if exist('mean','dir')
        % Get the name of the mean's dataset
        mean_dir = dir('mean/*.BRIK');
        mean_dataset_name = mean_dir(1).name(1:(end-5));
        cmd = sprintf('3dvolreg -base ''%s''[0] -Fourier -noclip -1Dfile %s.1D -maxdisp1D %s.maxdisp -prefix %s_tshift_reg %s_tshift+orig', [functional_folder 'mean/' mean_dataset_name], output_filename, output_filename, output_filename, output_filename);
    else
        cmd = sprintf('3dvolreg -base %s -Fourier -noclip -1Dfile %s.1D -maxdisp1D %s.maxdisp -prefix %s_tshift_reg %s_tshift+orig', num2str(file_number), output_filename, output_filename, output_filename, output_filename);
    end
    system(cmd);
    
    % Switch back to old directory
    cd(old_directory);
catch
    % If an error occurred, still error, but switch back to the right
    % directory first
    cd(old_directory);
    % Get error info
    [lasterrortext lasterrorcode] = lasterr;
    error(lasterrorcode,lasterrortext);
end