function output_data = dataobject_IMG_import(input_data,inputtype,bounding_box)
% DATAOBJECT_IMG_IMPORT
% Fills a data structure with 3D data if your data is in the format of IMG
% files.  Data must be bias corrected to use this function.
%
% If data are in BRIK file format, use dataobject_BRIK_import instead
%
% output_data = preprocess_fill_3D(input_data, inputtype, bounding_box)
%
% inputtype must be 'n' for normalized to template data, 'r' for registered
% data or 'c' for regular data
%
% bounding_box is optional. if present as a 3x2 structure it will bound all
% images by
% (bounding_box(1,1):bounding_box(1,2),bounding_box(2,1):bounding_box(2,2),
% bounding_box(3,1):bounding_box(3,2))

if ~exist('inputtype','var')
    inputtype = 'n';
else
    if ~strcmp(inputtype,'n') && ~strcmp(inputtype,'r') && ~strcmp(inputtype,'c')
        error('''inputtype'' must be n, r, c');
    end
end

output_data = input_data;

% Get the filenames, parse out ',1' at end if necessary
switch inputtype
    case 'n'
        anatomical_string = input_data.files.img.normalized.biascorr;
    case 'r'
        anatomical_string = input_data.files.img.biascorr;
    case 'c'
        anatomical_string = input_data.files.img.biascorr;
end
if strcmp(anatomical_string((end-1):end),',1')
    anatomical_string = anatomical_string(1:(end-2));
end
switch inputtype
    case 'n'
        mn_string = input_data.files.img.normalized.mean;
    case 'r'
        mn_string = input_data.files.img.registered.mean;
    case 'c'
        mn_string = input_data.files.img.mean;
end
if strcmp(mn_string((end-1):end),',1')
    mn_string = mn_string(1:(end-2));
end
% Load in mean and anatomical images
anatomical = load_nii(anatomical_string);
anatomical = anatomical.img;
if exist('bounding_box','var')
    for dim_index = 1:size(bounding_box,1)
        anatomical = crop_by_index(dim_index,anatomical,bounding_box(dim_index,1):bounding_box(dim_index,2));
    end
end

mn = load_nii(mn_string);
mn = mn.img;
if exist('bounding_box','var')
    for dim_index = 1:size(bounding_box,1)
        mn = crop_by_index(dim_index,mn,bounding_box(dim_index,1):bounding_box(dim_index,2));
    end
end

output_data.data.anatomical = {anatomical};
output_data.data.mn = {mn};

% Get list of functional images
switch inputtype
    case 'n'
        functional_searchstring = input_data.files.img.normalized.functional_searchstring;
    case 'r'
        functional_searchstring = input_data.files.img.registered.functional_searchstring;
    case 'c'
        functional_searchstring = input_data.files.img.corrected_functional_searchstring;
end

if ~strcmpi(functional_searchstring(end-3:end),'.img') && ~strcmpi(functional_searchstring(end-3:end),'.nii')
    functional_searchstring = [functional_searchstring '.img'];
end

functional_dir = dir(functional_searchstring);
[dirpart namepart extpart] = segment_filename(functional_searchstring); %#ok<NASGU,ASGLU>
% Allocate
switch numel(size(output_data.data.mn{1}))
    case 3
        % [size(output_data.data.mn{1},1),size(output_data.data.mn{1},2),size(output_data.data.mn{1},3),length(functional_dir)]
        if exist('bounding_box','var')
            functional = zeros(bounding_box(1,2)-bounding_box(1,1)+1,bounding_box(2,2)-bounding_box(2,1)+1,bounding_box(3,2)-bounding_box(3,1)+1,length(functional_dir));
        else
            functional = zeros(size(output_data.data.mn{1},1),size(output_data.data.mn{1},2),size(output_data.data.mn{1},3),length(functional_dir));
        end
    case 2
        if exist('bounding_box','var')
            functional = zeros(bounding_box(1,2)-bounding_box(1,1)+1,bounding_box(2,2)-bounding_box(2,1)+1,length(functional_dir));
        else
            functional = zeros(size(output_data.data.mn{1},1),size(output_data.data.mn{1},2),length(functional_dir));
        end
end
% Loop through all functional images and add
for index_func = 1:length(functional_dir)
    this_img = load_nii([dirpart functional_dir(index_func).name]);
    this_img = this_img.img;
    if exist('bounding_box','var')
        for dim_index = 1:size(bounding_box,1)
            this_img = crop_by_index(dim_index,this_img,bounding_box(dim_index,1):bounding_box(dim_index,2));
        end
    end
    switch numel(size(output_data.data.mn{1}))
        case 3
            functional(:,:,:,index_func) = this_img;
        case 2
            functional(:,:,index_func) = this_img;
    end
end
% Store
output_data.data.bold = {functional};

% Regions of interest
% Segments
% Check if they exist
try
    switch inputtype
        case 'n'
            segments = input_data.files.img.normalized.segments;
        otherwise
            segments = input_data.files.img.segment;
    end
    has_segments = ~isempty(segments);
catch id
    if strcmp(id.identifier,'MATLAB:nonExistentField')
        has_segments = false;
    else
        error(id.identifier,id.message);
    end
end
% Add ROIs
% Check if has ROIs
try
    roi = input_data.files.img.ROI.anatomical_space;
    has_rois = ~isempty(roi);
catch id
    if strcmp(id.identifier,'MATLAB:nonExistentField')
        has_rois = false;
    else
        error(id.identifier,id.message);
    end
end
% Concatenate if had both
if has_rois && has_segments
    all_roi = cat(1,segments,roi);
    clear segments;
    clear roi;
else
    if has_rois
        all_roi = roi;
        clear roi;
    else
        if has_segments
            all_roi = segments;
            clear segments;
        else
            all_roi = {};
        end
    end
end
% Give names
roi_names = cell(size(all_roi));
for roi_index = 1:length(all_roi)
    [dirpart namepart extpart] = segment_filename(all_roi{roi_index}); %#ok<ASGLU,NASGU>
    roi_names(roi_index) = {namepart};
end
% Save
output_data.data.roi_names = {roi_names};


% Crop out ',1's if exist
for index_roi = 1:length(all_roi)
    if strcmp(all_roi{index_roi}((end-1):end),',1')
        all_roi{index_roi} = all_roi{index_roi}(1:(end-1));
    end
end
% Put in data structure
switch numel(size(output_data.data.mn{1}))
    case 3
        roi = zeros(size(output_data.data.mn{1},1),size(output_data.data.mn{1},2),size(output_data.data.mn{1},3),length(all_roi));
    case 2
        roi = zeros(size(output_data.data.mn{1},1),size(output_data.data.mn{1},2),length(all_roi));
end
for index_roi = 1:length(all_roi)
    nii_data = load_nii(all_roi{index_roi});
    if exist('bounding_box','var')
        for dim_index = 1:size(bounding_box,1)
            nii_data.img = crop_by_index(dim_index,nii_data.img,bounding_box(dim_index,1):bounding_box(dim_index,2));
        end
    end
    % Permute NII ROIs
    % nii_data.img = permute(nii_data.img,[2,1,3]);
    switch numel(size(output_data.data.mn{1}))
        case 3
            %             size(roi(:,:,:,index_roi))
            %             size(nii_data.img)
            %             functional_one = functional(:,:,:,1);
            %             save in_function_data roi nii_data anatomical functional_one
            % save import_crash_3
            roi(:,:,:,index_roi) = nii_data.img;
        case 2
            roi(:,:,index_roi) = nii_data.img;
    end
end
% Store
output_data.data.roi = {roi};