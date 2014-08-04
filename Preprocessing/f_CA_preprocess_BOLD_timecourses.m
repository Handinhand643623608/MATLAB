function [BOLD_data fileStruct paramStruct] = f_CA_preprocess_BOLD_timecourses(BOLD_data, fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
subject = BOLD_data.info.subject;
scan = BOLD_data.info.scans;
TR = BOLD_data.info.TR;
gaussian_sigma = paramStruct.preprocess.BOLD.gaussian_sigma;
gaussian_size = paramStruct.preprocess.BOLD.gaussian_size;
remove_num_TR = paramStruct.preprocess.BOLD.remove_num_TR;
filt_length = round(paramStruct.preprocess.BOLD.filt_length ./ TR);
num_TR_removed = 0;
large_dataset = 1e12;

%% Preprocess the BOLD Time Courses
% Initialize loop-dependent parameters
functional_images = BOLD_data.BOLD(scan).functional;
mean_image = BOLD_data.BOLD(scan).mean;    
motion_filename = f_CA_filenames(fileStruct.paths.corrected_functional{subject}{scan}, 'txt');

% Collect BOLD mask data
[GM_image WM_image CSF_image] = deal(double(BOLD_data.masks.GM), double(BOLD_data.masks.WM), double(BOLD_data.masks.CSF));

% Collect the motion parameters from SPM's realignment
motion_params = textread(motion_filename{1});

% Normalize the mean image to values between 0-1
norm_mean_image = normalize_(mean_image);

% Use a spatial Gaussian blur on the functional images
functional_images = spatially_g_blur(functional_images, gaussian_sigma, gaussian_size);

% Blur the masks
if paramStruct.preprocess.BOLD.blur_masks
    GM_image = spatially_g_blur(GM_image, gaussian_sigma, gaussian_size);
    WM_image = spatially_g_blur(WM_image, gaussian_sigma, gaussian_size);
    CSF_image = spatially_g_blur(CSF_image, gaussian_sigma, gaussian_size);
end

% Normalize & scale the masks
norm_GM_image = (normalize_(GM_image) > paramStruct.preprocess.BOLD.GM_cutoff) .* (norm_mean_image > paramStruct.preprocess.BOLD.mean_cutoff);
norm_WM_image = (1 - norm_GM_image) .* (normalize_(WM_image) > paramStruct.preprocess.BOLD.WM_cutoff) .* (norm_mean_image > paramStruct.preprocess.BOLD.mean_cutoff);
norm_CSF_image = (1 - (norm_GM_image + norm_WM_image)) .* (normalize_(CSF_image) > paramStruct.preprocess.BOLD.CSF_cutoff) .* (norm_mean_image > paramStruct.preprocess.BOLD.mean_cutoff);

% Remove initial part of signal from MR images & motion parameters
functional_images = functional_images(:, :, :, (remove_num_TR + 1):end);
motion_params = motion_params((remove_num_TR + 1):end, :);
num_TR_removed = num_TR_removed + remove_num_TR;

% Filter the image time courses & motion parameters
[filt_param1 filt_param2] = fir1(filt_length, paramStruct.preprocess.BOLD.bandpass*2*TR);
filt_functional_images = filter(filt_param1, filt_param2, functional_images, [], 4);
filt_motion_params = filter(filt_param1, filt_param2, motion_params, [], 1);

% Crop the images and motion parameters by the filter length
filt_functional_images = filt_functional_images(:, :, :, (filt_length + 1):end);
filt_motion_params = filt_motion_params((filt_length + 1):end, :);
num_TR_removed = num_TR_removed + filt_length;

% Detrend the functional signals
filt_functional_images = detrend_dataset(filt_functional_images, paramStruct.preprocess.BOLD.detrend_order, norm_mean_image > paramStruct.preprocess.BOLD.mean_cutoff);

% Z-Score the time courses
filt_functional_images = zscore(filt_functional_images, [], 4);

% Remove noise & perform regressions
if paramStruct.preprocess.BOLD.use_old_method
    functional_sig = timecourse_signal(filt_functional_images, norm_mean_image > paramStruct.preprocess.BOLD.mean_cutoff, 'a');
    WM_sig = timecourse_signal(filt_functional_images, norm_WM_image > paramStruct.preprocess.BOLD.mean_cutoff, 'a');
    CSF_sig = timecourse_signal(filt_functional_images, norm_CSF_image > paramStruct.preprocess.BOLD.mean_cutoff, 'a');

    % Create the nuisance matrix
    if paramStruct.preprocess.BOLD.regress_CSF
        nuisance_mat = [filt_motion_params functional_sig WM_sig CSF_sig];
    else
        nuisance_mat = [filt_motion_params functional_sig WM_sig];
    end

    % Regress out the nuisance matrix
    for j = 1:size(nuisance_mat, 2)
        if numel(filt_functional_images) >= large_dataset
            filt_functional_images = regress_sig_large_dataset(filt_functional_images, nuisance_mat(:, j), norm_mean_image);
        else
            filt_functional_images = regress_sig(filt_functional_images, nuisance_mat(:, j), norm_mean_image);
        end
    end

else

    % Use the PCA method instead of the old one
    WM_sigs = reshape(filt_functional_images, [size(filt_functional_images, 1)*size(filt_functional_images, 2)*size(filt_functional_images, 3), size(filt_functional_images, 4)]);
    WM_sigs = WM_sigs(norm_WM_image(:) > paramStruct.preprocess.BOLD.mean_cutoff, :);
    if paramStruct.preprocess.BOLD.regress_CSF
        CSF_sigs = reshape(filt_functional_images, [size(filt_functional_images, 1)*size(filt_functional_images, 3)*size(filt_functional_images, 3), size(filt_functional_images, 4)]);
        CSF_sigs = CSF_sigs(norm_CSF_image(:) > paramStruct.preprocess.BOLD.mean_cutoff, :);
    end

    % Create the matrix used to do PCA (WM & CSF signals, & motion parameters)
    if paramStruct.preprocess.BOLD.regress_CSF
        nuisance_mat = [filt_motion_params, WM_sigs', CSF_sigs'];
    else
        nuisance_mat = [filt_motion_params, WM_sigs'];
    end

    % Find the PCs of the nuisance matrix
    nuisance_PC = nuisance_mat * princomp(nuisance_mat);

    % Find the standard deviations of the PCs of the nuisance matrix along the component dimension
    nuisance_std = std(nuisance_PC, [], 1);

    % Keep only components whose standard deviations are greater than the input cutoff
    nuisance_PC = nuisance_PC(:, 1:sum(nuisance_std > paramStruct.preprocess.BOLD.PCA_var_cutoff));

    % Regress PC time courses from signal
    for j = 1:paramStruct.preprocess.BOLD.remove_num_PC
        if numel(filt_functional_images >= large_dataset)
            filt_functional_images = regress_sig_large_dataset(filt_functional_images, nuisance_PC(:, j), norm_mean_image);
        else
            filt_functional_images = regress_sig(filt_functional_images, nuisance_PC(:, j), norm_mean_image);
        end
    end
end

% Post-PCA normalization
filt_functional_images = normalize_tcourses_fast(filt_functional_images);

% Replace the old data with the new data
BOLD_data.BOLD(scan).functional = filt_functional_images;
BOLD_data.BOLD(scan).mean = norm_mean_image;

% Replace the old masks with the new ones
BOLD_data.masks.GM = GM_image;
BOLD_data.masks.WM = WM_image;
BOLD_data.masks.CSF = CSF_image;

% Include some data in parameters sections for other preprocessing
BOLD_data.info.num_timepoints = size(filt_functional_images, 4);
paramStruct.preprocess.EEG.target_timepoints = size(filt_functional_images, 4);

% Save the data
data_path = [fileStruct.paths.preprocessed '/MAT Files'];
fileStruct.paths.MAT_files = data_path;
if exist(data_path, 'dir') ~=7
    mkdir([data_path '/BOLD'])
end
save([data_path '/BOLD/tempBOLD_preprocessed_' num2str(subject) '_' num2str(scan) '.mat'], 'BOLD_data', '-v7.3')
save(fileStruct.files.masterStructs, 'fileStruct', 'paramStruct');

% Garbage collect
delete([fileStruct.paths.main '/temp*.mat']);