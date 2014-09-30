function PrepImportIMG(boldData)
%PREPIMPORTIMG - Imports IMG files into numerical arrays that MATLAB can use.
%   This function imports anatomical, functional, mean, and segment .img files and stores them in numerical data arrays
%   inside the human data structure. All data are converted to type "double" during the import process. This function
%   requires the full preprocessing procedure through normalization to be completed.
%
%   SYNTAX:
%   PrepImportIMG(boldData)
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
%       20140929:   Major overhaul of this function to work with the preprocessing parameter structure overhaul.



%% Import the Preprocessed Data
% Get the working data set from the data object
data = boldData.Preprocessing.WorkingData;

% Import the anatomical image
anatData = load_nii(data.Anatomical{1});
anatData = double(anatData.img);

% Import the mean functional image
meanData = load_nii(data.Mean{1}(1:end - 2));
meanData = double(meanData.img);

% Pre-allocate an array for the functional data
tempFunData = load_nii(data.Functional{1}(1:end - 2));
tempFunData = double(tempFunData.img);
szData = size(tempFunData);
funData = zeros([szData length(data.Functional)]);
clear temp*;

% Import the functional images
for a = 1:length(data.Functional)
    tempData = load_nii(data.Functional{a}(1:end - 2));
    tempData = double(tempData.img);
    funData(:, :, :, a) = tempData;
end
clear temp*;

% Import the segmented anatomical images
segData = zeros([szData 3]);
for a = 1:length(data.Segments)
    tempData = load_nii(data.Segments{a}(1:end - 2));
    tempData = double(tempData.img);
    
    segData(:, :, :, a) = tempData;
end

% Store the data in the data object
boldData.Data.Anatomical = anatData;
boldData.Data.Functional = funData;
boldData.Data.Mean = meanData;
boldData.Data.Segments = segData;