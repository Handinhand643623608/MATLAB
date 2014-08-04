function input_data = dataobject_registration(input_data,regdirection,eoptions_cost_fun,eoptions_sep,eoptions_tol,eoptions_fwhm,roptions_interp,roptions_wrap,roptions_mask,roptions_prefix)
% DATAOBJECT_REGISTRATION
% Registers all relevent images in anatomical space to functional space
%
% data = batchspm_registration(data, regdirection, ...)
%
% regdirection is zero to register from anatomical (including ROIs) to
% functional, one to register from functional (including mean image) to
% anatomical.
%
% data must have the following fields:
%
% If registering to functional:
% data.files.img.mean
% data.files.img.segment
% data.files.img.biascorr
%
% If registering to anatomical:
% data.files.img.mean
% data.files.img.biascorr
% data.files.img.corrected_fuctional_searchstring
%
% Optional if registering to functional:
% data.files.img.ROI.anatomical_space
%
% The output adds the following fields to data:
%
% ... is SPM paramaters
% eoptions_cost_fun,eoptions_sep,eoptions_tol,eoptions_fwhm,
% roptions_interp,roptions_wrap,roptions_mask,roptions_prefix
%
% In the case of registration to functional, the output gains the fields
% data.files.img.registered.anatomical
% data.files.img.registered.roi
%
% In the case of registration to anatomical, the output gains the fields
% data.files.img.registered.functional_searchstring
% data.files.img.registered.mean
%
%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 3130 $)
%-----------------------------------------------------------------------

% This is the SPM default parameters:
if ~exist('eoptions_cost_fun','var') || isempty(eoptions_cost_fun)
    eoptions_cost_fun = 'nmi';
end
if ~exist('eoptions_sep','var') || isempty(eoptions_sep)
    eoptions_sep = [4 2];
end
if ~exist('eoptions_tol','var') || isempty(eoptions_tol)
    eoptions_tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
end
if ~exist('eoptions_fwhm','var') || isempty(eoptions_fwhm)
    eoptions_fwhm = [7 7];
end
if ~exist('roptions_interp','var') || isempty(roptions_interp)
    roptions_interp = 1;
end
if ~exist('roptions_wrap','var') || isempty(roptions_wrap)
    roptions_wrap = [0 0 0];
end
if ~exist('roptions_mask','var') || isempty(roptions_mask)
    roptions_mask = 0;
end
if ~exist('roptions_prefix','var') || isempty(roptions_prefix)
    roptions_prefix = 'r';
end

% Valid regdirections are 0, 1
if (regdirection ~= 0) && (regdirection ~= 1)
    error('Input ''regdirection'' must be 0 or 1.');
end

% Extract necesssary variables
img_mean = input_data.files.img.mean;
img_biascorr = input_data.files.img.biascorr;
switch regdirection
    case 0
        % Segments and ROIs needed only if going from anatomical to structural
        img_segment = input_data.files.img.segment;
        % If there are no ROIs, make it empty
        try
            roi_anatomical_space = input_data.files.img.ROI.anatomical_space;
        catch
            [lasterrtext lasterrcode] = lasterr;
            if strcmp(lasterrcode,'MATLAB:nonExistentField')
                roi_anatomical_space = cell(0);
            else
                error(lasterrtext);
            end
        end
    case 1
        % Functional searchstring needed only if going from structural to
        % anatomical
        img_functional_searchstring = input_data.files.img.corrected_functional_searchstring;
end

switch regdirection
    case 0
        % The reference image is the mean functional image
        matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {[img_mean ',1']};
        % The image to reslice is the anatomical image, bias corrected
        matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[img_biascorr ',1']};
        % The other images are the ROIs and the segmented image
        % Organize other images to reslice
        estwrite_other = [img_segment;roi_anatomical_space];
        % Add the ',1' to the end of each
        for index = 1:length(img_segment)
            estwrite_other(index) = {[estwrite_other{index} ',1']};
        end
        % Store in batch command
        matlabbatch{1}.spm.spatial.coreg.estwrite.other = estwrite_other;
    case 1
        % The reference image is the anatomical image
        matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {[img_biascorr ',1']};
        % The image to reslice is the mean functional image
        matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[img_mean ',1']};
        % The other images are the functional images themselves
        % Get list of functional images
        if ~strcmpi(img_functional_searchstring(end-3:end),'.img')
            d = dir([img_functional_searchstring '.img']);
        else
            d = dir([img_functional_searchstring]);
        end
        dirpart = segment_filename(img_functional_searchstring);
        % Put each mean image in a cell array ended with ,1
        functional_cellarray = cell(size(d));
        for index = 1:length(d)
            functional_cellarray(index) = {[dirpart d(index).name ',1']};
        end
        % Store in batch command
        matlabbatch{1}.spm.spatial.coreg.estwrite.other = functional_cellarray;
end

% SPM Parameters
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = eoptions_cost_fun; %'nmi';
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = eoptions_sep; %[4 2];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = eoptions_tol; %[0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = eoptions_fwhm; %[7 7];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = roptions_interp; %1;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = roptions_wrap; %[0 0 0];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = roptions_mask; %0;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = roptions_prefix; %'r';

% Run the SPM batch
spm_output = spm_jobman('run',matlabbatch);

% Remove ',1' if it exists
for comma_one_index = 1:length(spm_output{1}.rfiles)
    if isequal(spm_output{1}.rfiles{index}((end-2):end),',1')
        spm_output{1}.rfiles{index}((end-2):end) = [];
    end
end

% Save results
switch regdirection
    case 0
        % Anatomical image
        input_data.files.img.registered.anatomical = spm_output{1}.rfiles{1};
        % Functional image (may be empty cell array)
        input_data.files.img.registered.roi = cell(length(spm_output{1}.rfiles) - 1,1);
        for index = 1:(length(spm_output{1}.rfiles) - 1)
            % Get the file info
            reg_roi_filename = {spm_output{1}.rfiles{index + 1}};
            reg_roi_filename = reg_roi_filename{1};
            input_data.files.img.registered.roi(index) = {reg_roi_filename};
        end
    case 1
        % Mean functional image
        input_data.files.img.registered.mean = spm_output{1}.rfiles{1};
        % Functional image searchstring
        [dirpart filepart] = segment_filename(spm_output{1}.rfiles{2});
        % Find first non-number at end of filepart
        non_num_found = false;
        find_index = length(filepart) + 1;
        while ~non_num_found
            find_index = find_index - 1;
            if sum(double(filepart(find_index) == '0123456789')) == 0
                non_num_found = true;
            end
        end
        % Save
        input_data.files.img.registered.functional_searchstring = [dirpart filepart(1:find_index) '*'];        
end