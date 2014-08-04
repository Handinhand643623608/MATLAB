%% CA_masterStructs

%% Initialization
% Initialize a file structure for analysis
fileStruct.paths = struct(...
    'main', 'C:\Users\Josh\SkyDrive\svnSandbox',...                             % <--- Input the main path for outputs
    'raw', 'C:\Users\Josh\Documents\Josh\Raw Data',...                          % <--- Raw EEG & fMRI data path
    'segments', 'C:\Users\Josh\SkyDrive\Globals\MNI\segments');                 % <--- MNI segments path
fileStruct.files = struct(...
    'MNI', 'C:\Users\Josh\SkyDrive\MATLAB Code\Globals\MNI\template\T1.nii');   % <--- MNI template brain file

% Initialize a parameter structure for analysis
paramStruct.general = struct(...
    'subjects', [1 2 3 4 5 6 7],...                                     % <--- Option for choosing specific subjects (input 'auto' for automatic processing of all subjects/scans)
    'scans', {{[1 2] [1 2] [1 2] [1 2] [1 2] [1 2 3] [1 2]}},...        % <--- Option for selecting specific scans (can only be used if subjects field is not set to 'auto')
    'append', 0);
paramStruct.initialize.BOLD = struct(...
    'TR', 2,...                             % <--- BOLD TR (in seconds)
    'TE', 0.03,...                          % <--- BOLD TE (in milliseconds)
    'voxel_size', 2,...                     % <--- BOLD voxel size (in millimeters)
    'num_slices', 33);                      % <--- Number of slices in each scan

%% Preprocessing
% Initialize time course preprocessing parameters
paramStruct.preprocess.BOLD = struct(...
    'remove_num_TR', 0,...          % <--- Remove this number of TRs from the begining of each BOLD time course
    'gaussian_sigma', 2,...         % <--- Sigma for the spatial Gaussian blur
    'gaussian_size', 3,...          % <--- Voxel size of the spatial Gaussian blur
    'GM_cutoff', 0.1,...            % <--- Cutoff for normalized GM mask (0 < cutoff < 1)
    'WM_cutoff', 0.15,...           % <--- Cutoff for normalized WM mask 
    'CSF_cutoff', 0.2,...           % <--- Cutoff for normalized CSF mask
    'mean_cutoff', 0.2,...          % <--- Cutoff for normalized mean image
    'filt_length', 45,...           % <--- FIR filter length in seconds
    'bandpass', [0.01 0.08],...     % <--- Bandpass filter cutoffs ([highpass lowpass])    
    'detrend_order', 2,...          % <--- Order of detrending function (2 = quadratic)
    'PCA_var_cutoff', [],...        % <--- PCA variance cutoff
    'remove_num_PC', [],...         % <--- Number of principal components to regress
    'regress_CSF', true,...         % <--- Regress CSF signal?
    'use_old_method', true,...      % <--- Use old, non-PCA method?
    'blur_masks', true);            % <--- Blur the GM, WM, & CSF masks?

% Initialize the EEG preprocessing parameters
paramStruct.preprocess.EEG = struct(...
    'BCG_label', 'HL1',...
    'prct_thresholds', [50 60 70 80 90 40 30 20 10],...
    'MR_correct_channel', 'auto',...
    'has_BCG', [0 1 1 1 0 1 1 1],...                        % <--- Subjects that have BCG recorded are marked with a '1'
    'new_Fs', 300,...                                       % <--- New sampling frequency for EEG
    'bandpass', [0.01 0.08],...                             % <--- Bandpass filter cutoffs ([highpass lowpass])
    'filter_type', 'fir1',...                               % <--- Filter type to use on EEG data
    'filt_params', 50,...                                   % <--- Filter window length (in seconds) (can be an array for other filters with different parameters)
    'detrend_order', 2);

%% EEG Correlation Network
paramStruct.corrNetwork = struct(...
    'subjects', [],...
    'scans', [],...
    'cutoffs', []);

%% EEG-BOLD Cross-Correlation
% Initialize the parameter structure for cross-correlation
paramStruct.xcorr.EEG_BOLD = struct(...
    'subjects', [],...                  % <--- Choose specific subjects
    'scans', [],...                     % <--- Choose specific scans for specific subjects
    'tshifts', [-20:2:10],...           % <--- Choose time shifts (in seconds) to examine cross-correlations
    'electrodes', {{'FPZ' 'P8'}},...    % <--- Choose specific electrodes to cross-correlate with BOLD time courses
    'image_slices', [48:4:64], ...      % <--- Choose specific slices of cross-correlations to image
    'image_tshifts', [1:3:16]);

%% EEG Welch Power Spectra
paramStruct.powerSpectra = struct(...
    'subjects', [],...
    'scans', [],...
    'electrodes', {{'FPZ' 'P8'}},...
    'rawFreqRange', [0:(100/99):100],...
    'dcFreqRange', [0:(0.1/99):0.1],...
    'segmentLength', 60000,...
    'overlapPct', 99.5);

%% EEG Volume Conduction
paramStruct.volumeConduct = struct(...
    'subjects', [],...
    'scans', [],...
    'tshifts', -25,...
    'corrType', 'coeff');

%% ICA Time Course Aggregation
paramStruct.ICA = struct(...
    'subjects', [],...
    'scans', [],...
    'componentIdents', {{'CSF', 'DMN', 'TPN', 'Visual'}});            % <--- Identity of the networks from ICA (in the same order as they appear in the component images)
    
fileStruct.paths.timeCourses = 'C:\Users\Josh\Documents\Josh\Thesis Work\Complete Analysis\Preprocessed Data\ICA Results\Time Course Files';

%% EEG-IC Cross-Correlation
paramStruct.xcorr.EEG_IC = struct(...
    'subjects', [],...
    'scans', [],...
    'timeShifts', [-20:2:10],...
    'alpha', 0.05,...
    'corrType', 'coeff');

%% Save the Structures
savePath = [fileStruct.paths.main '\Structures'];
fileStruct.files.masterStructs = [savePath '\masterStructs.mat'];
save([savePath '\masterStructs_incomplete.mat'], 'fileStruct', 'paramStruct')
clear all
clc