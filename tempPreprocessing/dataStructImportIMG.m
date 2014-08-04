function dataStruct = dataStructImportIMG(dataStruct)
%DATASTRUCTIMPORTIMG Imports IMG files into numerical arrays that MATLAB can use.
%   This function imports anatomical, functional, mean, and segment .img files and stores them in
%   numerical data arrays inside the human data structure. All data are converted to type "double"
%   during the import process. This function requires the full preprocessing procedure through
%   normalization to be completed.
%
%   SYNTAX:
%   dataStruct = dataStructImportIMG(dataStruct)
%
%   OUTPUT:
%   dataStruct:     The human data structure with imported data.
%
%   INPUT:
%   dataStruct:     A human data structure.
%
%   Written by Josh Grooms on 20130703


%% Initialize
% Pull information from data structure
imgFolder = dataStruct.Files.IMGFolder;
searchStr = dataStruct.Files.IMG.Normalized.FunctionalStr;
anatomicalFile = dataStruct.Files.IMG.Normalized.BiasCorrected;
meanFile = dataStruct.Files.IMG.Normalized.Mean;
segmentFiles = dataStruct.Files.IMG.Normalized.Segments;
segmentStrs = {'WM', 'GM', 'CSF'};

% Get a list of the functional data files
functionalFiles = get(fileData(imgFolder, 'ext', '.img', 'search', searchStr), 'Path');


%% Load the IMG Files
% Load the anatomical & mean data
anatomicalData = load_nii(anatomicalFile); anatomicalData = double(anatomicalData.img);
meanData = load_nii(meanFile); meanData = double(meanData.img);

% Pre-allocate the functional data array
tempData = load_nii(functionalFiles{1}); tempData = double(currentData.img);
szData = size(tempData);
functionalData = zeros([szData length(functionalFiles)]);
clear temp*

% Load the functional data
for a = 1:length(functionalFiles)
    currentData = load_nii(functionalFiles{a}); currentData = double(currentData.img);
    functionalData(:, :, :, a) = currentData;
end
clear current*

% Load the segmentation data
for a = 1:length(segmentFiles)
    currentData = load_nii(segmentFiles{a}); currentData = double(currentData.img);
    segmentData.(segmentStrs{a}) = currentData;
end


%% Store the Loaded Data in the Data Structure
dataStruct.Data.BOLD = functionalData;
dataStruct.Data.Anatomical = anatomicalData;
dataStruct.Data.Mean = meanData;
dataStruct.Data.Segments = segmentData;