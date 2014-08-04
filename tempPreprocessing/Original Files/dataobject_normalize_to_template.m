function data_out = dataobject_normalize_to_template(data_in,template_brain,eoptions_template, eoptions_weight, eoptions_smosrc, eoptions_smoref, eoptions_regtype, eoptions_cutoff, eoptions_nits, eoptions_reg, roptions_preserve, roptions_bb, roptions_vox, roptions_interp, roptions_wrap, roptions_prefix,roptions_mask,roptions_prefix_2)
% DATAOBJECT_NORMALIZE_TO_TEMPLATE
% Normalizes to template brain
% 
% data_out = batchspm_normalize_to_template(data_in,template_brain)
%
% template_brain    String of template brain image location
% 
% data_in           fMRI data structure, must have the following fields:
%
% data.files.img.biascorr                   Bias corrected anatomical image
% data.files.img.registered.functional_searchstring
%                                           Search string that provides all
%                                           functional images, must end in
%                                           *
% data.files.img.registered.mean            Mean functional image
% 
% data_out          fMRI data structure with the following new fields:
%
% data.files.img.normalized.biascorr
% data.files.img.normalized.functional_searchstring
% data.files.img.normalized.mean
%
% Also can be passed these SPM options:
% 
% eoptions_template, eoptions_weight, eoptions_smosrc, eoptions_smoref,
% eoptions_regtype, eoptions_cutoff, eoptions_nits, eoptions_reg
% roptions_preserve, roptions_bb, roptions_vox, roptions_interp,
% roptions_wrap, roptions_prefix

% Default SPM params
if ~exist('eoptions_template','var') || isempty(eoptions_template)
    eoptions_template = {[template_brain ',1']};
end
if ~exist('eoptions_weight','var') || isempty(eoptions_weight)
    eoptions_weight = '';
end
if ~exist('eoptions_smosrc','var') || isempty(eoptions_smosrc)
    eoptions_smosrc = 8;
end
if ~exist('eoptions_smoref','var') || isempty(eoptions_smoref)
    eoptions_smoref = 0;
end
if ~exist('eoptions_regtype','var') || isempty(eoptions_regtype)
    eoptions_regtype = 'mni';
end
if ~exist('eoptions_cutoff','var') || isempty(eoptions_cutoff)
    eoptions_cutoff = 25;
end
if ~exist('eoptions_nits','var') || isempty(eoptions_nits)
    eoptions_nits = 16;
end
if ~exist('eoptions_reg','var') || isempty(eoptions_reg)
    eoptions_reg = 1;
end
if ~exist('roptions_preserve','var') || isempty(roptions_preserve)
    roptions_preserve = 0;
end
if ~exist('roptions_bb','var') || isempty(roptions_bb)
    roptions_bb = [-78 -112 -50
    78 76 85];
end
if ~exist('roptions_vox','var') || isempty(roptions_vox)
    roptions_vox = [2 2 2];
end
if ~exist('roptions_interp','var') || isempty(roptions_interp)
    roptions_interp = 1;
end
if ~exist('roptions_wrap','var') || isempty(roptions_wrap)
    roptions_wrap = [0 0 0];
end
if ~exist('roptions_prefix','var') || isempty(roptions_prefix)
    roptions_prefix = 'w';
end
if ~exist('roptions_mask','var') || isempty(roptions_mask)
    roptions_mask = 0;
end
if ~exist('roptions_prefix_2','var') || isempty(roptions_prefix_2)
    roptions_prefix_2 = 'r';
end

% Bias corrected anatomical image is the source image
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {[data_in.files.img.biascorr ',1']};
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.wtsrc = '';

% Get list of functional images
d = dir([data_in.files.img.registered.functional_searchstring '.img']);
dirpart = segment_filename(data_in.files.img.registered.functional_searchstring);
% Put each mean image in a cell array ended with ,1
functional_cellarray = cell(size(d));
for index = 1:length(d)
    functional_cellarray(index) = {[dirpart d(index).name ',1']};
end
% Get segments if they exist
try
    segment_files = data_in.files.img.segment;
    has_segments = true;
    for index = 1:length(segment_files)
        segment_files(index) = {[segment_files{index} ',1']};
    end
catch exception_e
    if strcmp(second_exception.identifier,'MATLAB:nonExistentField')
        segment_files = {};
        has_segments = false;
    else
        throw(exception_e);
    end
end


% Mean image and functional images are the resampled images
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = cat(1, ...
    {[data_in.files.img.biascorr ',1']}, ...
    {[data_in.files.img.registered.mean ',1']}, ...
    segment_files, ...
    functional_cellarray ...
    );

% Other parameters
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = eoptions_template;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.weight = eoptions_weight;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smosrc = eoptions_smosrc;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smoref = eoptions_smoref ;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.regtype = eoptions_regtype ;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.cutoff = eoptions_cutoff ;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.nits = eoptions_nits ;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = eoptions_reg ;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.preserve = roptions_preserve ;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.bb = roptions_bb ;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.vox = roptions_vox; 
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = roptions_interp ;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.wrap = roptions_wrap ;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.prefix = roptions_prefix ;

% Runt te SPM job
spm_output_0 = spm_jobman('run',matlabbatch);

% Normalize to template
matlabbatch_2{1}.spm.spatial.coreg.write.ref = eoptions_template;
matlabbatch_2{1}.spm.spatial.coreg.write.source = spm_output_0{1}.files;
matlabbatch_2{1}.spm.spatial.coreg.write.roptions.interp = roptions_interp;
matlabbatch_2{1}.spm.spatial.coreg.write.roptions.wrap = roptions_wrap;
matlabbatch_2{1}.spm.spatial.coreg.write.roptions.mask = roptions_mask;
matlabbatch_2{1}.spm.spatial.coreg.write.roptions.prefix = roptions_prefix_2;

% Runt te SPM job
spm_output = spm_jobman('run',matlabbatch_2);

% Save output
data_out = data_in;
% Save in "normalized" sub-structure
data_out.files.img.normalized.biascorr = spm_output{1}.rfiles{1}(1:(end-2));
data_out.files.img.normalized.mean = spm_output{1}.rfiles{2}(1:(end-2));
if has_segments
    data_out.files.img.normalized.segments = spm_output{1}.rfiles(3:(length(segment_files)+2));
    for index = 1:length(segment_files)
        data_out.files.img.normalized.segments(index) = {data_out.files.img.normalized.segments{index}(1:(end-2))};
    end
end
[dirpart filepart] = segment_filename(spm_output{1}.rfiles{3+length(segment_files)}(1:(end-2)));
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
data_out.files.img.normalized.functional_searchstring = [dirpart filepart(1:find_index) '*'];