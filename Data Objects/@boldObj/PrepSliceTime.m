function PrepSliceTime(boldData)
% PREPSLICETIME - Corrects slice timing artifacts in slow TR fMRI data using SPM.
%   This function corrects slice timing artifacts that are commonly present in BOLD fMRI data, especially when the
%   repetition time (TR) is high for the scanning sequence. Such artifacts are the result of scanning different slices
%   of the brain at appreciably different times, making what are truly simultaneous events appear spread out over time
%   throughout the image volume. This procedure corrects these aberrations by phase shifting voxel signals backward in
%   time with respect to a reference slice.
%
%   WARNING:
%   Slice timing correction should only be applied to data if the TR is sufficiently high. For faster imaging sequences
%   (e.g. < 1s) this procedure is far less necessary because the maximum timing difference (TR/2) between adjacent
%   slices will be small compared to the hemodynamic response width. Furthermore, slice timing corrections are known to
%   potentially introduce artifacts into data.
%
%
%   SYNTAX:
%   PrepSliceTime(boldData)
%   boldData.PrepSliceTime
%
%   INPUT:
%   boldData:           BOLDOBJ
%                       A single BOLD data object undergoing preprocessing.
%
%   PARAMETER DEFINITIONS:
%   'NumSlices':        INTEGER
%                       The number of slices in an fMRI volume. This is usually the number of array elements in the 3rd
%                       dimension of the fMRI data array.
%                       DEFAULT: []
%                       OPTIONS:
%                           [ ] - Automatically determined from DICOM header information
%                            X  - Any integer representing the number of slices present in the data volume array
%
%   'OutputPrefix':     STRING
%                       The string that will be prepended to the file names of images that have undergone this slice
%                       timing correction procedure.
%                       DEFAULT: 'a'
%
%   'ReferenceSlice':   INTEGER
%                       The slice to use as the reference for corrections applied to all other slices.
%                       DEFAULT = []
%                       OPTIONS:
%                           [ ] - Automatically determined from the slice acquisition ordering
%                            X  - Any integer representing the reference slice number
%
%   'SliceOrder':       [ INTEGER ]
%                       The ordering of slice acquisition in the volume array. In other words, this is the order in
%                       which individaul brain slices were originally imaged by the scanner. A typical EPI sequence like
%                       those used for BOLD functional connectivity studies images slices in an interleaved ordering
%                       with the intent of minimizing crosstalk between adjacent slices. However, this is not universal
%                       and other schemes are used.
%                       
%                       Slice ordering is specified as a vector of length N, where N = NumSlices for the volume array.
%                       This vector must have a range (i.e. [MIN MAX]) of [1 N] and contain no repeating numbers. The
%                       number 1 here refers to the first (bottom-most) slice of of the 3D data array found in the
%                       NIFTI files that SPM uses. N then refers to the last or top-most slice.
%
%                       For the Siemens Trio scanner at CABI only, this parameter can be automatically determined using
%                       the slice acquisition timings logged in the DICOM header information.
%
%                       DEFAULT: []
%
%                       OPTIONS:
%                           [ ]                 - Automatically determined from DICOM header information (only for the 
%                                                 Siemens Trio 3T scanner at CABI, unconfirmed for other scanners)
%                           [ INTEGER ]         - Explicitly list the slice acquisition ordering
%
%                       EXAMPLES:
%                           [1:N]               - Ascending     (bottom to top of data array)
%                           [N:-1:1]            - Descending    (top to bottom of data array)
%                           [1:2:N, 2:2:N]      - Interleaved   (bottom to top of data array)
%                           [N:-2:1, N-1:-2:1]  - Interleaved   (top to bottom of data array)
%
%                           % Interleaved (middle outward of data array)
%                           for (a = 1:N)
%                               round((N - a) / 2 + (rem((N - a), 2) * (N - 1) / 2)) + 1;
%                           end
%
%   'TA':               DOUBLE
%                       The acquisition time (TA, in seconds) of the image acquisition sequence. This is usually
%                       calculated as (TR - (TR / NumSlices)) and represents how much time is required to scan one
%                       complete volume. If empty, this parameter will be calculated automatically using the other
%                       parameters.
%                       DEFAULT: [] 
%                       OPTIONS:
%                           [ ] - Automatically calculated using the TR and number of slices
%                            X  - Any double-precision number representing the TA in seconds
%
%   'TR':               DOUBLE
%                       The repetition time (TR, in seconds) of the image acquisition sequence. This should be a
%                       well-known scanning parameter and represents how much time lies between scanning a single slice
%                       and returning to rescan that slice once the rest of the volume volume (e.g. the whole head or a
%                       specific set of slices) has been imaged. Thus, it represents the acquisition time plus some 
%                       interscan interval. If empty, this parameter will be determined automatically from the data.
%
%                       DEFAULT: []
%                       OPTIONS:
%                           [ ]  - Automatically determined from DICOM header information
%                            X   - Any double-precision number representing the TR in seconds

%% CHANGELOG
%   Written by Josh Grooms on 20140930



%% Initialize
% Get the working data set & stage parameters
data = boldData.Preprocessing.WorkingData;
params = boldData.Preprocessing.SliceTiming;

% Automatically determine the number of slices in the data (CABI Siemens Trio 3T only)
if isempty(params.NumSlices); params.NumSlices = boldData.Acquisition.NumberOfSlices; end

% Automatically determine the acquisition ordering of slices (CABI Siemens Trio 3T only)
if isempty(params.SliceOrder)
    [~, params.SliceOrder] = sort(boldData.Acquisition.SliceAcquisitionTimes);
end

% Automatically determine the reference slice
if isempty(params.ReferenceSlice); params.ReferenceSlice = find(params.SliceOrder == 1); end

% Automatically determine the TR
if isempty(params.TR); params.TR = boldData.TR/1000;
elseif (params.TR > 50)
    warning('Unusually large TR of %d detected. Was this accidentally specified in milliseconds?.');
end

% Automatically determine the TA
if isempty(params.TA)
    params.TA = params.TR - (params.TR / params.NumSlices);
end



%% Perform Slice Timing Correction
funData = cellfun(@(x) [x ',1'], data.Functional, 'UniformOutput', false);
matlabbatch{1}.spm.temporal.st = struct(...
    'nslices',      params.NumSlices,...
    'prefix',       params.OutputPrefix,...
    'refslice',     params.ReferenceSlice,...
    'scans',        {{funData}},...
    'so',           params.SliceOrder,...
    'ta',           params.TA,...
    'tr',           params.TR);
    
% Run the slice timing correction procedure
spmOutput = spm_jobman('run', matlabbatch);



%% Store the Results
boldData.Preprocessing.SliceTiming = params;
boldData.Preprocessing.WorkingData.Functional = spmOutput{1}.files;

    