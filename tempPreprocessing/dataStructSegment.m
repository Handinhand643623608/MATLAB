function dataStruct = dataStructSegment(dataStruct, varargin)
%DATASTRUCTSEGMENT Segments MRI structural images into CSF, WM, and GM components.
%
%   SYNTAX:
%   dataStruct = dataStructSegment(dataStruct, 'PropertyName', PropertyValue...)
%
%   OUTPUT:
%   dataStruct:             The human data structure with references to the segment images.
%
%   INPUT:
%   dataStruct:             A human data structure.
%
%   OPTIONAL INPUTS:
%   'BiasReg':              Bias Regularization: a modeled correction for variations in image
%                           intensity caused by all MR scanners. 
%                           DEFAULT: 0.0001
%                           OPTIONS:
%                               0       - No regularization
%                               0.00001 - Extremely light regularization
%                               0.0001  - Very light regularization
%                               0.001   - Light regularization
%                               0.01    - Medium regularization
%                               0.1     - Heavy regularization
%                               1       - Very heavy regularization
%                               10      - Extremely heavy regularization
%
%   'BiasFWHM':             FWHM of Gaussian Bias Smoothness: an estimate of the smoothness of
%                           intensity non-uniformity (bias) in millimeters used for bias correction.
%                           DEFAULT: 60
%                           OPTIONS:
%                               30-150  - An integer between 30 & 150 (inclusive) in steps of 10 
%                                         only.
%                               
%   'Cleanup':              A boolean dictating whether or not to clean up gray and white matter
%                           partitions using other segmentation results. 
%                           WARNING: This can result in pieces of brain missing from data.
%                           DEFAULT: false
%
%   'MaskImage':            An image to be used as a mask during segmentation.
%                           DEFAULT: {''}
%
%   'NumGauss':             Number of Gaussians Per Tissue Type: the number of Gaussians used to
%                           represent the image intensity distribution per tissue type. This
%                           variable is given as a vector of length 4. Each element is an integer
%                           representing the quantity of Gaussians per tissue type in the following
%                           order: gray matter, white matter, CSF, everything else.
%                           DEFAULT: [2 2 2 4]
%
%   'OutputCorrected':      A boolean indicating whether or not to output a bias-corrected version
%                           of the image.
%                           DEFAULT: true
%
%   'OutputCSF':            A vector of booleans of length 3 indicating whether or not to output an
%                           image of CSF segmentation results. Each element of the vector represents
%                           the type(s) of image(s) to be saved. They are ordered as follows:
%                           modulated normalized, unmodulated normalized, native space.
%                           DEFAULT: [false false true]
%
%   'OutputGM':             A vector of booleans of length 3 indicating whether or not to output an
%                           image of gray matter segmentation results. Each element of the vector
%                           represents the type(s) of image(s) to be saved. They are ordered as
%                           follows: modulated normalized, unmodulated normalized, native space.
%                           DEFAULT: [false false true]
%
%   'OutputWM':             A vector of booleans of length 3 indicating whether or not to output an
%                           image of white matter segmentation results. Each element of the vector
%                           represents the type(s) of image(s) to be saved. They are ordered as
%                           follows: modulated normalized, unmodulated normalized, native space.
%                           DEFAULT: [false false true]
%
%   'SampleDistance':       Sampling Distance: the approximate distance between sampled points when
%                           estimating parameters for the bias correction model. Smaller values use
%                           more of the data, but slows down correction.
%                           DEFAULT: 3
%
%   'WarpReg':              Warping Regularization: a scalar governing the tradeoff between cost
%                           functions controlling the registration of segments to the data image.
%                           Higher values result in smoother deformations during registration.
%                           DEFAULT: 1
%
%   'WarpCutoff':           Warp Frequency Cutoff: a scalar lower bound on discrete cosine transform
%                           (DCT) bases used to describe segment warping during registration.
%                           Smaller values allow more detailed deformations, but greatly increase
%                           computational load. 
%                           DEFAULT: 25
%
%   Written by Josh Grooms on 20130629


%% Initialize
% Initialize defaults & settings
if isstruct(varargin{1})
    assignInputs(varargin{1}, 'varsOnly');
else
    inStruct = struct(...
        'BiasReg', 0.0001,...
        'BiasFWHM', 60,...
        'Cleanup', false,...
        'MaskImage', {{''}},...
        'NumGauss', [2 2 2 4],...
        'OutputCorrected', true,...
        'OutputCSF', [0 0 1],...
        'OutputGM', [0 0 1],...
        'OutputWM', [0 0 1],...
        'RegType', 'mni',...
        'SampleDistance', 3,...
        'WarpReg', true,...
        'WarpCutoff', 25);
    assignInputs(inStruct, varargin);
end

% Get needed folder locations
anatomicalData = dataStruct.Files.IMG.Anatomical;
anatomicalFolder = dataStruct.Files.AnatomicalFolder;
segmentsFolder = dataStruct.Files.SegmentsFolder;
imgFolder = dataStruct.Files.IMGFolder;

% Construct the segments log file name
segmentsLog = [anatomicalFolder 'segmentsImport.txt'];


%% Run Anatomical Image Segmentation
if exist(segmentsLog, 'file')
    % If a log already exists for this subject, don't rerun segmentation
    segmentsLogData = textread(segmentsLog, '%s\n');
    
    % Copy the files over to this scan
    for a = 1:length(segmentsLogData)
        copyfile([segmentsLogData{a}(1:(end-3)) '*'], imgFolder);
    end    
    
    if OutputCorrected
        % If bias correction is being outputted, get that file too
        [~, correctedName, correctedExt] = fileparts(segmentsLogData{1});
        dataStruct.Files.IMG.BiasCorrected = [imgFolder correctedName '.' correctedExt];
        
        % Get the segments files
        for a = 2:length(segmentsLogData)
            [~, segmentsName, segmentsExt] = fileparts(segmentsLogData{a});
            dataStruct.Files.IMG.Segment(a-1) = {[imgFolder segmentsName '.' segmentsExt]};
        end
    else
        % Otherwise, get only the segments files
        for a = 1:length(segmentsLogData)
            [~, segmentsName, segmentsExt] = fileparts(segmentsLogData{a});
            dataStruct.Files.IMG.Segment(a) = {[imgFolder segmentsName '.' segmentsExt]};
        end
    end
    
    % Store file references in the data structure
    dataStruct.Files.IMG.Segment = dataStruct.Files.IMG.Segment';
    
else
    % If a log does not exit, run segmentation through SPM
    wmFile = get(fileData(segmentsFolder, 'ext', '.nii', 'Search', 'white'), 'Path');
    gmFile = get(fileData(segmentsFolder, 'ext', '.nii', 'Search', 'grey'), 'Path');
    csfFile = get(fileData(segmentsFolder, 'ext', '.nii', 'Search', 'csf'), 'Path');
    
    % Build the batch processing parameter structure
    matlabbatch{1}.spm.spatial.preproc = struct(...
        'data', {anatomicalData},...
        'opts', struct(...
            'biasfwhm', BiasFWHM,...
            'biasreg', BiasReg,...
            'msk', {MaskImage},...
            'ngaus', [NumGauss],...
            'regtype', RegType,...
            'samp', SampleDistance,...
            'tpm', {{wmFile; gmFile; csfFile}}),...
        'output', struct(...
            'biascor', [OutputCorrected],...
            'cleanup', [Cleanup],...
            'CSF', [OutputCSF],...
            'GM', [OutputGM],...
            'WM', [OutputWM]));
        
    % Run segmentation
    spmOutput = spm_jobman('run', matlabbatch);

    % Determine how many outputs there will be & pre-allocate data structure
    numOutputs = sum([OutputCSF, OutputGM, OutputWM]);
    dataStruct.Files.IMG.Segment = cell(numOutputs, 1);

    % Write the operations to a log file
    segmentsLogID = fopen(segmentsLog, 'w');
    if OutputCorrected
        dataStruct.Files.IMG.BiasCorrected = spmOutput{1}.biascorr{1};
        fprintf(segmentsLogID, '%s\n', spmOutput{1}.biascorr{1});
    end
    for a = 1:numOutputs
        fieldStr = ['c' num2str(a)];
        dataStruct.Files.IMG.Segments(a) = {spmOutput{1}.(fieldStr){1}};
        fprintf(segmentsLogID, '%s\n', spmOutput{1}.(fieldStr){1});
    end
    fclose(segmentsLogID);
end