function data_object = dataobject_segment(data_object,output_GM,output_WM,output_CSF,output_biascor,output_cleanup,opts_ngaus,opts_regtype,opts_warpreg,opts_warpco,opts_biasreg,opts_biasfwhm,opts_samp,opts_msk)
% DATAOBJECT_SEGMENT
%
% Segments a structural image in a data_object structure.
%
% data_object = batchspm_segment(data_object, ...)
%
% ... is the SPM parameters
% output_GM,output_WM,output_CSF,output_biascor,output_cleanup,opts_ngaus,
% opts_regtype,opts_warpreg,opts_warpco,opts_biasreg,opts_biasfwhm,
% opts_samp,opts_msk
%
%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 3130 $)
%-----------------------------------------------------------------------

if ~exist('output_GM','var') || isempty(output_GM)
    output_GM = [0 0 1];
end
if ~exist('output_WM','var') || isempty(output_WM)
    output_WM = [0 0 1];
end
if ~exist('output_CSF','var') || isempty(output_CSF)
    output_CSF = [0 0 1];
end
if ~exist('output_biascor','var') || isempty(output_biascor)
    output_biascor = 1;
end
if ~exist('output_cleanup','var') || isempty(output_cleanup)
    output_cleanup = 0;
end
if ~exist('opts_ngaus','var') || isempty(opts_ngaus)
    opts_ngaus = [2;2;2;4];
end
if ~exist('opts_regtype','var') || isempty(opts_regtype)
    opts_regtype = 'mni';
end
if ~exist('opts_warpreg','var') || isempty(opts_warpreg)
    opts_warpreg = 1;
end
if ~exist('opts_warpco','var') || isempty(opts_warpco)
    opts_warpco = 25;
end
if ~exist('opts_biasreg','var') || isempty(opts_biasreg)
    opts_biasreg = 0.0001;
end
if ~exist('opts_biasfwhm','var') || isempty(opts_biasfwhm)
    opts_biasfwhm = 60;
end
if ~exist('opts_samp','var') || isempty(opts_samp)
    opts_samp = 3;
end
if ~exist('opts_msk','var') || isempty(opts_msk)
    opts_msk = {''};
end

% Extract needed folder locations
structural = data_object.files.img.structural;
segments_folder = data_object.files.segments_folder;
anatomical_folder = data_object.files.anatomical_folder;
IMG_folder = data_object.files.IMG_folder;

% Save and read file format
segments_import_log_format = '%s\n';
segments_import_log_filename = [anatomical_folder 'segments_import.txt'];

if exist(segments_import_log_filename,'file')
    
    % Instead of re-running segmentation, load the existing file
    
    % Load the data in the log which must exist
    segments_import_log_data = textread(segments_import_log_filename,segments_import_log_format);
    % Copy the files over
    for index = 1:length(segments_import_log_data)
        copyfile([segments_import_log_data{index}(1:(end-3)) '*'],IMG_folder);
    end
    if output_biascor
        % Get the new filename for the coil bias corrected anatomical image
        [ccd_dir ccd_name ccd_ext] = segment_filename(segments_import_log_data{1});
        % Save the new filename of the coil bias corrected anatomical image
        data_object.files.img.biascorr = [IMG_folder ccd_name '.' ccd_ext];
    end
    % Loop through the masks
    
    % Maskes for segmentation of structural image.
    if output_biascor
        for index = 2:length(segments_import_log_data)
            % Get the new filename for the coil bias corrected anatomical image
            [md_dir md_name md_ext] = segment_filename(segments_import_log_data{index});
            % Save the new filename of the coil bias corrected anatomical image
            data_object.files.img.segment(index-1) = {[IMG_folder md_name '.' md_ext ]};
        end
    else
        for index = 1:length(segments_import_log_data)
            % Get the new filename for the coil bias corrected anatomical image
            [md_dir md_name md_ext] = segment_filename(segments_import_log_data{index});
            % Save the new filename of the coil bias corrected anatomical image
            data_object.files.img.segment(index) = {[IMG_folder md_name '.' md_ext ]};
        end
    end
    
    data_object.files.img.segment = data_object.files.img.segment';
    
else
    
    % Fill in batch data structure for SPM
    % Set input structural image
    matlabbatch{1}.spm.spatial.preproc.data = {structural};
    % SPM parameters
    matlabbatch{1}.spm.spatial.preproc.output.GM = output_GM;
    matlabbatch{1}.spm.spatial.preproc.output.WM = output_WM;
    matlabbatch{1}.spm.spatial.preproc.output.CSF = output_CSF;
    matlabbatch{1}.spm.spatial.preproc.output.biascor = output_biascor;
    matlabbatch{1}.spm.spatial.preproc.output.cleanup = output_cleanup;
    % Set segment images
    % Determine segmentation files
    wm_dir = [dir([segments_folder '*wm*.nii']),dir([segments_folder '*white*.nii'])];
    gm_dir = [dir([segments_folder '*gm*.nii']),dir([segments_folder '*gray*.nii']),dir([segments_folder '*grey*.nii'])];
    csf_dir = [dir([segments_folder '*csf*.nii']),dir([segments_folder '*cerebro*.nii'])];
    matlabbatch{1}.spm.spatial.preproc.opts.tpm = {
        [segments_folder wm_dir(1).name]
        [segments_folder gm_dir(1).name]
        [segments_folder csf_dir(1).name]
        };
    % SPM parameters
    matlabbatch{1}.spm.spatial.preproc.opts.ngaus = opts_ngaus;
    matlabbatch{1}.spm.spatial.preproc.opts.regtype = opts_regtype;
    matlabbatch{1}.spm.spatial.preproc.opts.warpreg = opts_warpreg;
    matlabbatch{1}.spm.spatial.preproc.opts.warpco = opts_warpco;
    matlabbatch{1}.spm.spatial.preproc.opts.biasreg = opts_biasreg;
    matlabbatch{1}.spm.spatial.preproc.opts.biasfwhm = opts_biasfwhm;
    matlabbatch{1}.spm.spatial.preproc.opts.samp = opts_samp;
    matlabbatch{1}.spm.spatial.preproc.opts.msk = opts_msk;
    
%     save function_dataobject_segment_data.mat    
%     disp('Before jobman')
    clear function;
    % Run the SPM batch
    spm_output = spm_jobman('run',matlabbatch);
%     disp('After jobman')
    
    % Save the output
    num_outputs = sum([output_GM output_WM output_CSF]);
    data_object.files.img.segment = cell(num_outputs,1);
    % Maskes for segmentation of structural image.
    for index = 1:num_outputs
        eval(['data_object.files.img.segment(index) = {spm_output{1}.c' num2str(index) '{1}};']);
    end
    % Save the data that's non-dependent on functional so it can be re-used
    segments_import_log_fid = fopen(segments_import_log_filename,'w');
    % Coil bias corrected structural image
    if output_biascor
        data_object.files.img.biascorr = spm_output{1}.biascorr{1};
        % Write the bias corrected image for future use
        fprintf(segments_import_log_fid,segments_import_log_format,spm_output{1}.biascorr{1});
    end
    % Write the segemts for future use
    for index = 1:num_outputs
        eval(['fprintf(segments_import_log_fid,segments_import_log_format,spm_output{1}.c' num2str(index) '{1});']);
    end
    fclose(segments_import_log_fid);
end