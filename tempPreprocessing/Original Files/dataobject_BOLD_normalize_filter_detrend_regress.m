function data_object = dataobject_BOLD_normalize_filter_detrend_regress(data_object, num_TR_to_remove, spatially_g_blur_sigma, spatially_g_blur_size, GM_lower_cutoff, WM_lower_cutoff, CSF_lower_cutoff, mean_cutoff_for_masking, filtlen, highpass_cutoff, lowpass_cutoff, detrend_order, pca_cutoff, num_components_regress,use_csf,old_method,blur_masks,override_masks,index_to_run)
% DATAOBJECT_BOLD_NORMALIZE_FILTER_DETREND_REGRESS
% Preprocesses the data_object structure including spatial gaussian blur,
% filtering and noise removal through detrending and regression using principle component
% analysis.  It also removes the initial part of the signal.
%
% function data_object = preprocess_FilterDetrend(data_object,
%   num_TR_to_remove, spatially_g_blur_sigma, spatially_g_blur_size,
%   GM_lower_cutoff, WM_lower_cutoff, CSF_lower_cutoff,
%   mean_cutoff_for_masking, filtlen, highpass_cutoff, lowpass_cutoff,
%   detrend_order, pca_cutoff, num_components_regress,use_csf,old_method,
%   blur_masks,override_masks)
%
% num_TR_to_remove
% Number of TR removed prior to analysis
%
% spatially_g_blur_sigma
% Sigma for spatial gaussian blur
%
% spatially_g_blur_size
% Size of spatial gaussian blur
%
% GM_lower_cutoff
% WM_lower_cutoff
% CSF_lower_cutoff
% Minimum cutoff value for a voxel to be placed in the binary (1 or 0) gray
% matter or white matter masks.  Normalized 0 to 1.
%
% mean_cutoff_for_masking
% Minimum cutoff value for a voxel to be considered within the brain.  Normalized 0 to 1.
%
% filtlen
% Length of the filter
%
% highpass_cutoff
% The lower limit on the FIR filter used.
%
% lowpass_cutoff
% The upper limit on the FIR filter used.
%
% detrend_order
% Order of function used to detrend.
%
% pca_cutoff
% Only principal components with std greater than this cutoff will be kept
%
% num_components_regress
% The number of principal components to regress out
%
% use_csf
% Whether to use the CSF signal or not to regress
%
% old_method
% Whether to use the old method of regressing motion parameters and signals
%
% blur_masks
% Whether to apply a spatially_g_blur to the masks as well
%
% index_to_run
% Which trial within the data object to run


large_dataset_cutoff_size = 1e12;

% % Default parameters
if ~exist('num_TR_to_remove','var') || isempty(num_TR_to_remove)
    num_TR_to_remove = 0;
end
if ~exist('spatially_g_blur_sigma','var') || isempty(spatially_g_blur_sigma)
    spatially_g_blur_sigma = 2;
end
if ~exist('spatially_g_blur_size','var') || isempty(spatially_g_blur_size)
    spatially_g_blur_size = 3;
end
if ~exist('GM_lower_cutoff','var') || isempty(GM_lower_cutoff)
    GM_lower_cutoff = 0.35;
end
if ~exist('WM_lower_cutoff','var') || isempty(WM_lower_cutoff)
    WM_lower_cutoff = 0.4;
end
if ~exist('CSF_lower_cutoff','var') || isempty(CSF_lower_cutoff)
    CSF_lower_cutoff = 0.45;
end
if ~exist('mean_cutoff_for_masking','var') || isempty(mean_cutoff_for_masking)
    mean_cutoff_for_masking = 0.2;
end
if ~exist('filtlen','var') || isempty(filtlen)
    filtlen = 300;
end
if ~exist('highpass_cutoff','var') || isempty(highpass_cutoff)
    highpass_cutoff = 0.01;
end
if ~exist('lowpass_cutoff','var') || isempty(lowpass_cutoff)
    lowpass_cutoff = 0.08;
end
if ~exist('detrend_order','var') || isempty(detrend_order)
    detrend_order = 2;
end
if ~exist('pca_cutoff','var') || isempty(pca_cutoff)
    pca_cutoff = 0.0001;
end
if ~exist('num_components_regress','var') || isempty(num_components_regress)
    num_components_regress = 15;
end
if ~exist('use_csf','var') || isempty(use_csf)
    use_csf = false;
end
if ~exist('old_method','var') || isempty(old_method)
    old_method = true;
end
if ~exist('blur_masks','var') || isempty(blur_masks)
    blur_masks = true;
end
if ~exist('override_masks','var') || isempty(override_masks)
    override_masks = false;
end
if ~exist('index_to_run','var') || isempty(index_to_run)
    index_to_run = 1;
end

has_bold = dataobject_which_fields(data_object,'bold');

if has_bold

    % Keep a count of how many time points were removed
    num_TR_removed = 0;

    % Load required data
    I = double(data_object.data.bold{index_to_run}); % Functional + Time
    mn = double(data_object.data.mn{index_to_run}); % Mean of functional over time
    size_rois = size(data_object.data.roi{index_to_run});
    switch numel(size(I))
        case 3
            for index = 1:size_rois(end)
                string_to_search = (upper(data_object.data.roi_names{index_to_run}{index}));
                if ~isempty(strfind(string_to_search,'GRAY')) || ~isempty(strfind(string_to_search,'GM'))
                    GM = data_object.data.roi{index_to_run}(:,:,index); % Gray matter mask coregistered 2D
                end
                if ~isempty(strfind(string_to_search,'WHITE')) || ~isempty(strfind(string_to_search,'WM'))
                    WM = data_object.data.roi{index_to_run}(:,:,index); % White matter mask coregistered 2D
                end
                if ~isempty(strfind(string_to_search,'CEREBRO')) || ~isempty(strfind(string_to_search,'CSF'))
                    CSF = data_object.data.roi{index_to_run}(:,:,index); % Cerebrospinal fluid mask coregistered 2D
                end
            end
        case 4
            for index = 1:size_rois(end)
                string_to_search = (upper(data_object.data.roi_names{index_to_run}{index}));
                if ~isempty(strfind(string_to_search,'GRAY')) || ~isempty(strfind(string_to_search,'GM')) || ~isempty(strfind(string_to_search,'C2'))
                    GM = data_object.data.roi{index_to_run}(:,:,:,index); % Gray matter mask coregistered 2D
                end
                if ~isempty(strfind(string_to_search,'WHITE')) || ~isempty(strfind(string_to_search,'WM'))|| ~isempty(strfind(string_to_search,'C1'))
                    WM = data_object.data.roi{index_to_run}(:,:,:,index); % White matter mask coregistered 2D
                end
                if ~isempty(strfind(string_to_search,'CEREBRO')) || ~isempty(strfind(string_to_search,'CSF'))|| ~isempty(strfind(string_to_search,'C3'))
                    CSF = data_object.data.roi{index_to_run}(:,:,:,index); % Cerebrospinal fluid mask coregistered 2D
                end
            end
    end

    if ~exist('GM','var') || ~exist('WM','var')
        warning('Gray matter or white matter not found.');
    else
        GM = double(GM);
        WM = double(WM);
        if exist('CSF','var')
            CSF = double(CSF);
        end
    end


    if override_masks
        mGM = GM;
        mWM = WM;
        if exist('CSF','var')
            mCSF = CSF;
        end
    end

    % Get TR
    TR = data_object.parameters.bold_tr(index_to_run);

    % Load motion parameters
    try
        file_where_1D = data_object.files.functional_folder;
        mopar_dir = dir([file_where_1D '*.1D']);
    catch my_err
        if strcmp(my_err.identifier,'MATLAB:nonExistentField')
            file_where_1D = 'NO FOLDER SPECIFIED';
            mopar_dir = [];
        else
            disp(my_err.identifier)
            error(my_err.message,my_err.identifier);
        end
    end

    if numel(mopar_dir) ~= 1
        warning(['Motion parameters not loaded.  Did not find exactly one .1D file in ' file_where_1D]);
        mopar = [];
    else
        mopar = importdata([data_object.files.functional_folder mopar_dir(1).name]);
    end
    % x = mopar(:, 1); y = mopar(:, 2); z = mopar(:, 3);

    % Save the maximum deviation of motion parameters before any alteration is
    % done
    if ~isempty(mopar)
        data_object.parameters.quality.maximum_deviation(index_to_run) = max(max(mopar,[],1) - min(mopar,[],1));
    end

    % Normalize the mean functional image
    mn =  normalize_(mn);

    % Spatial gaussian blur
    I = spatially_g_blur(I,spatially_g_blur_sigma,spatially_g_blur_size);
    % Blur masks?
    if blur_masks
        if exist('GM','var')
            GM = spatially_g_blur(GM,spatially_g_blur_sigma,spatially_g_blur_size);
        end
        if exist('WM','var')
            WM = spatially_g_blur(WM,spatially_g_blur_sigma,spatially_g_blur_size);
        end
        if exist('CSF','var')
            CSF = spatially_g_blur(CSF,spatially_g_blur_sigma,spatially_g_blur_size);
        end
    end

    % Remove initial part of signal, also remove from motion parameters
    switch(numel(size(I)))
        case 3
            I = I(:, :, (num_TR_to_remove + 1):end);
        case 4
            I = I(:, :, :, (num_TR_to_remove + 1):end);
    end
    if ~isempty(mopar)
        mopar = mopar((num_TR_to_remove + 1):end, :);
    end
    num_TR_removed = num_TR_removed + num_TR_to_remove;

    % Normalize and scale the GM and WM maps
    if ~override_masks
        if exist('GM','var')
            mGM = (normalize_(GM) > GM_lower_cutoff).* (mn > mean_cutoff_for_masking);
        end
        if exist('WM','var')
            mWM = (1-mGM) .* (normalize_(WM) > WM_lower_cutoff) .* (mn > mean_cutoff_for_masking);
        end
        if exist('CSF','var')
            mCSF = (1-(mGM+mWM)) .* (normalize_(CSF) > CSF_lower_cutoff) .* (mn > mean_cutoff_for_masking);
        end
    end

    % Filter
    % Create FIR filter
    [num2, den2] = fir1(filtlen, [highpass_cutoff lowpass_cutoff]*2*TR);
    % Create filtered original image, also filter motion parameters
    switch(numel(size(I)))
        case 3
            If2 = filter(num2, den2, I, [], 3);
            % Crop the filter by the filter length, also crop motion parameters
            If2 = If2(:, :, (filtlen + 1):end);
        case 4
            If2 = filter(num2, den2, I, [], 4);
            % Crop the filter by the filter length, also crop motion parameters
            If2 = If2(:, :, :, (filtlen + 1):end);
    end
    if ~isempty(mopar)
        mopar2 = filter(num2, den2, mopar, [], 1);
    end

    if ~isempty(mopar)
        mopar2 = mopar2((filtlen + 1):end, :);
    end

    num_TR_removed = num_TR_removed + filtlen;

    % De-trend the signal so it's ready for PCA
    If2 = detrend_dataset(If2, detrend_order, mn > mean_cutoff_for_masking);

    % Normalize the signal to unit variance (std = 1), zero mean
    switch(numel(size(I)))
        case 3
            % Loop through every voxel in space
            for k = 1:size(mn,1)
                for l = 1:size(mn,2)
                    % If the value in the mean image is below the cutoff, ignore
                    if(mn(k, l) <= mean_cutoff_for_masking)
                        continue;
                    end
                    % Find the time course at this voxel
                    temp = If2(k, l, :);
                    % Divide the time course at the voxel by the standard deviation
                    temp = temp(:) / std(temp(:));
                    % Save the std normalized
                    If2(k, l, :) = temp;
                end
            end
        case 4
            % Loop through every voxel in space
            for k = 1:size(mn,1)
                for l = 1:size(mn,2)
                    for m = 1:size(mn,3)
                        % If the value in the mean image is below the cutoff, ignore
                        if(mn(k, l, m) <= mean_cutoff_for_masking)
                            continue;
                        end
                        % Find the time course at this voxel
                        temp = If2(k, l, m, :);
                        % Divide the time course at the voxel by the standard deviation
                        temp = temp(:) / std(temp(:));
                        temp = temp(:) - mean(temp(:));
                        % Save the std normalized
                        If2(k, l, m, :) = temp;
                    end
                end
            end
    end

    % Remove noise, regress out components with PCA
    % Find the mean time series for whole brain, white matter and csf
    szIf2 = size(If2);

    if old_method
        % Create the individual vectors to regress out
        wbsig = timecourse_signal(If2, mn > mean_cutoff_for_masking,'a');
        if exist('WM','var')
            wmsig = timecourse_signal(If2, mWM > mean_cutoff_for_masking,'a');
        else
            wmsig = [];
        end
        if exist('CSF','var')
            csfsig = timecourse_signal(If2, mCSF > mean_cutoff_for_masking,'a');
        end
        % Create the nuisance matrix
        if ~isempty(mopar)
            if use_csf
                numat = [mopar2 wbsig wmsig csfsig];
            else
                numat = [mopar2 wbsig wmsig];
            end
        else
            if use_csf
                numat = [wbsig wmsig csfsig];
            else
                numat = [wbsig wmsig];
            end
        end
        % Change variable names
        nuisance = numat;
        my_reg_im = If2;
        % Regress out the nuisance matrix directly (old method)
        for h = 1:size(nuisance,2)
            if numel(If2) >= large_dataset_cutoff_size
                my_reg_im = regress_sig_large_dataset(my_reg_im, nuisance(:, h), mn);
            else
                my_reg_im = regress_sig(my_reg_im, nuisance(:, h), mn);
            end
        end
    else
        if ~exist('WM','var')
            error('White matter mask required for PCA method.');
        end
        % Find the individual time signals for each voxel in the white matter and
        % csf
        switch numel(size(I))
            case 3
                wmsigs = reshape(If2, [szIf2(1)*szIf2(2), szIf2(3)]);
                if use_csf
                    csfsigs = reshape(If2, [szIf2(1)*szIf2(2), szIf2(3)]);
                end
            case 4
                wmsigs = reshape(If2, [szIf2(1)*szIf2(2)*szIf2(3), szIf2(4)]);
                if use_csf
                    csfsigs = reshape(If2, [szIf2(1)*szIf2(2)*szIf2(3), szIf2(4)]);
                end
        end
        wmsigs = wmsigs(mWM(:) > mean_cutoff_for_masking, :);
        if use_csf
            csfsigs = csfsigs(mCSF(:) > mean_cutoff_for_masking, :);
        end
        % Create the matrix used to do PCA.  This consists of white matter and CSF
        % signals and motion parameters
        if use_csf
            if ~isempty(mopar)
                numat = [mopar2, wmsigs',csfsigs'];
            else
                numat = [wmsigs',csfsigs'];
            end
        else
            if ~isempty(mopar)
                numat = [mopar2, wmsigs'];
            else
                numat = [wmsigs'];
            end
        end
        % Get the nuisance matrix
        nuisance = numat;
        % Find the principal components of the nuisance matrix
        nuisance_pca = nuisance * princomp(nuisance);
        % Find the standard deviations of the principal components of the nuisance
        % matrix along the component dimension
        stds = std(nuisance_pca, [], 1);
        % Keep only those components which have standard deviations greater than
        % the PCA_CUTOFF input
        nuisance_pca = nuisance_pca(:, 1:sum(stds > pca_cutoff));
        % Allocate a data structure to store the regressed signal
        my_reg_im = If2;
        % For the 'num_components_regress' number of principal components, regress
        % their time courses from the signal. (new method)
        for h = 1:num_components_regress
            if numel(my_reg_im) >= large_dataset_cutoff_size
                my_reg_im = regress_sig_large_dataset(my_reg_im, nuisance_pca(:, h), mn);
            else
                my_reg_im = regress_sig(my_reg_im, nuisance_pca(:, h), mn);
            end
        end
    end
    % Store in the original variable name again
    If2 = my_reg_im;

    % Post-PCA normalization
    If2 = normalize_tcourses_fast(If2);

    % Replace the old data with the new data
    data_object.data.bold{index_to_run} = If2;
    data_object.data.mn{index_to_run} = mn;
    switch numel(size(I))
        case 3
            for index = 1:size_rois(end)
                string_to_search = (upper(data_object.data.roi_names{index_to_run}{index}));
                if ~isempty(strfind(string_to_search,'GRAY')) || ~isempty(strfind(string_to_search,'GM'))
                    data_object.data.roi{index_to_run}(:,:,index) = mGM;
                end
                if ~isempty(strfind(string_to_search,'WHITE')) || ~isempty(strfind(string_to_search,'WM'))
                    data_object.data.roi{index_to_run}(:,:,index) = mWM;
                end
                if ~isempty(strfind(string_to_search,'CEREBRO')) || ~isempty(strfind(string_to_search,'CSF'))
                    if exist('CSF','var')
                        data_object.data.roi{index_to_run}(:,:,index) = mCSF;
                    end
                end
            end
        case 4
            for index = 1:size_rois(end)
                string_to_search = (upper(data_object.data.roi_names{index_to_run}{index}));
                if ~isempty(strfind(string_to_search,'GRAY')) || ~isempty(strfind(string_to_search,'GM'))
                    data_object.data.roi{index_to_run}(:,:,:,index) = mGM;
                end
                if ~isempty(strfind(string_to_search,'WHITE')) || ~isempty(strfind(string_to_search,'WM'))
                    data_object.data.roi{index_to_run}(:,:,:,index) = mWM;
                end
                if ~isempty(strfind(string_to_search,'CEREBRO')) || ~isempty(strfind(string_to_search,'CSF'))
                    if exist('CSF','var')
                        data_object.data.roi{index_to_run}(:,:,:,index) = mCSF;
                    end
                end
            end
    end

    data_object.parameters.quality.sample_shift(index_to_run) = num_TR_removed - floor(filtlen / 2);
    % Store the nuisance matrix too
    data_object.parameters.quality.nuisance = {nuisance};
    data_object.data.boldGlobSig = {wbsig};

else
    
    error('No BOLD data found!');
    
end
