function PrepImport(boldData)
%PREPIMPORT Imports IMG files into numerical arrays that MATLAB can use.
%   This function imports anatomical, functional, mean, and segment .img files and stores them in
%   numerical data arrays inside the human data structure. All data are converted to type "double"
%   during the import process. This function requires the full preprocessing procedure through
%   normalization to be completed.
%
%   SYNTAX:
%   PrepImport(boldData)
%
%   INPUT:
%   boldData:       BOLDOBJ
%                   A single BOLD data object undergoing preprocessing.



%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20130708:   Bug fix for variable name typo.
%       20140721:   Changed the way IMG files were being identified here and in other related SPM preprocessing
%                   functions. File references are now passed along from stage to stage in the pipeline, eliminating the
%                   need for searching through directories.



%% Initialize
% Pull information from data structure
functionalIMG = boldData.Preprocessing.Files.IMG.Functional;
anatomicalIMG = boldData.Preprocessing.Files.IMG.BiasCorrected;
meanIMG = boldData.Preprocessing.Files.IMG.Mean;
segmentIMG = boldData.Preprocessing.Files.IMG.Segments;

segmentStrs = {'WM', 'GM', 'CSF'};



%% Load the IMG Files
% Load the anatomical & mean data
anatomicalData = load_nii(anatomicalIMG); anatomicalData = double(anatomicalData.img);
meanData = load_nii(meanIMG); meanData = double(meanData.img);

% Pre-allocate the functional data array
tempData = load_nii(functionalIMG{1}); tempData = double(tempData.img);
szData = size(tempData);
functionalData = zeros([szData length(functionalIMG)]);
clear temp*

% Load the functional data
for a = 1:length(functionalIMG)
    currentData = load_nii(functionalIMG{a}); currentData = double(currentData.img);
    functionalData(:, :, :, a) = currentData;
end
clear current*

% Load the segmentation data
for a = 1:length(segmentIMG)
    currentData = load_nii(segmentIMG{a}); currentData = double(currentData.img);
    segmentData.(segmentStrs{a}) = currentData;
end



%% Store the Loaded Data in the Data Structure
boldData.Data.Functional = functionalData;
boldData.Data.Anatomical = anatomicalData;
boldData.Data.Mean = meanData;
boldData.Data.Segments = segmentData;