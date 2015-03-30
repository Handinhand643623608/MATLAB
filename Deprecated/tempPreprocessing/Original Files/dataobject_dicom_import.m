function data_object = dataobject_dicom_import(data_object,root,convopts_format,convopts_icedims)
% DATAOBJECT_DICOM_IMPORT
% Runs the DICOM import process on human data, for further processing.
%
% data_object = batchspm_dicom_import(data_object, ...)
%
% ... is the SPM parameters
% root,convopts_format,convopts_icedims
%
%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 3130 $)
%-----------------------------------------------------------------------

if ~exist('root','var') || isempty(root)
    root = 'flat';
end
if ~exist('convopts_format','var') || isempty(convopts_format)
    convopts_format = 'img';
end
if ~exist('convopts_icedims','var') || isempty(convopts_icedims)
    convopts_icedims = 0;
end

% Extract values from data structure
mean_dicom_filename = data_object.files.mean_dicom_filename;
anatomical_folder = data_object.files.anatomical_folder;
IMG_folder = data_object.files.IMG_folder;

% Save and read file format
anatomical_import_log_format = '%s\n';
anatomical_import_log_filename = [anatomical_folder 'anatomical_import.txt'];

% See if the anatomical dicoms have already been imported
if exist(anatomical_import_log_filename,'file')
    
    % Instead of re-running dicom import, just copy the img over for
    % anatomical
    
    % Load the data in the log which must exist
    anatomical_import_log_data = textread(anatomical_import_log_filename,anatomical_import_log_format);
    % Copy the files over
    copyfile([(anatomical_import_log_data{1}(1:end-3)) '*'],IMG_folder);
    % Get the new filename
    [ad_dir ad_name ad_ext] = segment_filename(anatomical_import_log_data{1});
    % Save the new filename    
    data_object.files.img.structural = [IMG_folder ad_name '.' ad_ext];
    
    % Then DICOM import the mean functional image
    
    % Set up the variables the SPM Batch needs
    % Set SPM batch command for input files
    matlabbatch{1}.spm.util.dicom.data = {mean_dicom_filename};
    % Set SPM parameters
    matlabbatch{1}.spm.util.dicom.root = root;
    % Set SPM output directory
    matlabbatch{1}.spm.util.dicom.outdir = {IMG_folder};
    % Set SPM parameters
    matlabbatch{1}.spm.util.dicom.convopts.format = convopts_format;
    matlabbatch{1}.spm.util.dicom.convopts.icedims = convopts_icedims;
    
    % Run the SPM batch
    spm_output = spm_jobman('run',matlabbatch);
    
    % Save the output
    data_object.files.img.mean = spm_output{1}.files{1};
    
else
    
    % Run DICOM import on the anatomical data also in this case
    
    % Set up the variables the SPM Batch needs
    % Input files
    % Get the list of anatomical files
    anatomical_file_list = dir(anatomical_folder);
    % Save the filenames out
    anatomical_filename_list = cell(size(anatomical_file_list));
    % Keep track of which to remove
    remove_indices = [];
    % Remove anything that isn't a DICOM from the list
    for index = 1:length(anatomical_file_list)
        current_file = anatomical_file_list(index).name;
        if length(current_file) < 4
            remove_indices = [remove_indices index]; %#ok<AGROW>
        else
            if ~strcmp(current_file((end-3):end),'.dcm')
                remove_indices = [remove_indices index]; %#ok<AGROW>
            end
        end
        % Save just the file name (the dir is all file information)
        anatomical_filename_list(index) = {[anatomical_folder current_file]};
    end
    % Remove the unnecessary files
    clear anatomical_file_list;
    anatomical_filename_list(remove_indices) = [];
    % Set SPM batch command for input files
    matlabbatch{1}.spm.util.dicom.data = [anatomical_filename_list;{mean_dicom_filename}];
    % Set SPM parameters
    matlabbatch{1}.spm.util.dicom.root = root;
    % Set SPM output directory
    matlabbatch{1}.spm.util.dicom.outdir = {IMG_folder};
    % Set SPM parameters
    matlabbatch{1}.spm.util.dicom.convopts.format = convopts_format;
    matlabbatch{1}.spm.util.dicom.convopts.icedims = convopts_icedims;
    
    % Run the SPM batch
    spm_output = spm_jobman('run',matlabbatch);
    
    % Save the output
    % Output is in alphabetical order.  F comes before S.  Therefore the first
    % one will be functional, second will be structural
    % EXCEPT this changed in a later version of SPM/MATLAB.  Now I need to
    % check which is which...
    
    % Match using series number
    info_structural = dicominfo(anatomical_filename_list{1});
    info_mean = dicominfo(mean_dicom_filename);
    sn_structural = (info_structural.SeriesNumber);
    sn_mean = (info_mean.SeriesNumber);
    
    % Loop through the output
    found_structural = false;
    found_mean = false;
    for index_output = 1:length(spm_output{1}.files)
        % Get the relevant numerical part of the filename
        [dirpart_output namepart_output extpart_output] = segment_filename(spm_output{1}.files{index_output}); %#ok<NASGU,ASGLU>
        numbers_in_output = numpart(namepart_output);
        % Remove 0s
        numbers_in_output(numbers_in_output == '0') = [];
        % Compare to structural and mean indices
        switch str2double(numbers_in_output(1))
            case sn_structural
                data_object.files.img.structural = spm_output{1}.files{index_output};
                found_structural = true;
            case sn_mean
                data_object.files.img.mean = spm_output{1}.files{index_output};
                found_mean = true;
        end
    end
    
    if ~found_structural || ~found_mean
        error('Problem locating output files from DICOM import, structural or mean missing.');
    end
   
    % Save a file for the anatomical data
    anatomical_import_log_fid = fopen(anatomical_import_log_filename,'w');
    fprintf(anatomical_import_log_fid,anatomical_import_log_format,spm_output{1}.files{2});
    fclose(anatomical_import_log_fid);
    
end