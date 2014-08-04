function PrepMean(boldData)
%PREPMEAN Creates a mean DICOM image from functional imaging data & converts it to IMG format.
%   This function averages together all functional data from a single scan over the time dimension to produce a mean
%   DICOM image of the data used in later preprocessing steps.
%
%   SYNTAX:
%   PrepMean(boldData)
%
%   INPUT:
%   boldData:       BOLDOBJ
%                   A single BOLD data object undergoing preprocessing.

%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20130710:   Updated to absorb a separate function that ran the conversion to IMG format.
%       20140720:   Moved conversion from DICOM to NIFTI format to its own separate function. Should have stayed like
%                   that to begin with...



%% Initialize
% Pull data from the data object
functionalFolder = boldData.Preprocessing.Folders.Functional;

% Initialize the mean functional file directory & DICOM file name
meanFolder = [functionalFolder '/Mean'];
meanDCM = [meanFolder '/mean.dcm'];
if ~exist(meanFolder, 'dir')
    mkdir(meanFolder)
else
    error('Junk data present in data folders. Run "cleanRawFolders" before preprocessing')
end

% Get images & info from the functional directory
dataFiles = get(fileData(functionalFolder, 'ext', '.dcm'), 'Path');
dcmInfo = dicominfo(dataFiles{1});

% Pre-allocate the data storage array
dicomData = zeros(floor(dcmInfo.Width), floor(dcmInfo.Height), length(dataFiles));



%% Average together Images & Write to a DICOM File
% Concatenate images
for a = 1:length(dataFiles)
    dicomData(:, :, a) = dicomread(dataFiles{a});
end

% Average the data together & write the file
meanData = mean(dicomData, 3);
dicomwrite(uint16(round(meanData)), meanDCM, dcmInfo, 'CreateMode', 'copy', 'WritePrivate', true);

% Store folder & file references in the data object
boldData.Preprocessing.Folders.Mean = meanFolder;
boldData.Preprocessing.Files.MeanDCM = meanDCM;
