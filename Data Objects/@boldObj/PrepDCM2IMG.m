function PrepDCM2IMG(boldData)
%PREPDCM2IMG - Convert DICOM files to NIFTI format, ignoring checks for oblique data sets.
%
%   SYNTAX:
%   PrepDCM2IMG(boldData)
%   boldData.PrepDCM2IMG
%
%   INPUT:
%   boldData:       BOLDOBJ
%                   A single BOLD data object undergoing preprocessing.

%% CHANGELOG
%   Written by Josh Grooms on 20140722



%% Initialize
% Get folder references from the data object
anatomicalFolder = boldData.Preprocessing.Folders.Anatomical;
functionalFolder = boldData.Preprocessing.Folders.Functional;
imgFolder = boldData.Preprocessing.Folders.IMG.Root;

% Get data information from the data object
numSlices = boldData.Acquisition.NumberOfSlices;
funVoxelSize = boldData.Acquisition.VoxelSize;



%% Convert Anatomical DICOM Files to NIFTI Format
% Identify anatomical DICOM files
anatomicalFiles = get(fileData(anatomicalFolder, 'ext', '.dcm'), 'Path');

% Get some information from the DICOM headers
anatomicalInfo = dicominfo(anatomicalFiles{1});
anatomicalData = zeros(anatomicalInfo.Height, anatomicalInfo.Width, length(anatomicalFiles));

% Load anatomical images 
for a = 1:length(anatomicalFiles)
    anatomicalData(:, :, a) = dicomread(anatomicalFiles{a});
end
   
% Anatomical images are sliced sagittally by default, so we need to permute & reorient the images
anatomicalData = permute(anatomicalData, [3 2 1]);
anatomicalData = flipdim(anatomicalData, 2);
anatomicalData = flipdim(anatomicalData, 3);

% Create & save the NIFTI file
anatomicalVoxelSize = [anatomicalInfo.PixelSpacing', anatomicalInfo.SliceThickness];
imgStruct = make_nii(anatomicalData, anatomicalVoxelSize);
anIMGFile = [imgFolder '/AnatomicalVolume.img'];
save_nii(imgStruct, anIMGFile);



%% Convert Functional DICOM Files to NIFTI Format
% Identify functional DICOM files
functionalFiles = get(fileData(functionalFolder, 'ext', '.dcm'), 'Path');

% Initialize a storage array for NIFTI file paths
funIMGFiles = cell(length(functionalFiles), 1);

for a = 1:length(functionalFiles)
    
    % Reuse the DICOM file name for the NIFTI file
    [~, funFileName, ~] = fileparts(functionalFiles{a});
    
    % Read in the DICOM data & break mosaics into volume arrays
    functionalData = dicomread(functionalFiles{a});
    functionalData = breakMosaic(functionalData, numSlices);
    functionalData = permute(functionalData, [2 1 3]);
    functionalData = flipdim(functionalData, 2);
    
    % Create & save the NIFTI file
    imgStruct = make_nii(functionalData, funVoxelSize);
    funIMGFiles{a} = [imgFolder '/' funFileName '.img'];
    save_nii(imgStruct, funIMGFiles{a});
    
end



%% Store File References in the Data Object
boldData.Preprocessing.Files.DCM.Anatomical = anatomicalFiles;
boldData.Preprocessing.Files.DCM.Functional = functionalFiles;
boldData.Preprocessing.Files.IMG.Anatomical = {anIMGFile};
boldData.Preprocessing.Files.IMG.Functional = funIMGFiles;



end



% Convert functional image mosaics into volume arrays
function volume = breakMosaic(mosaic, numSlices)
    
    % Initialize some variables
    numRows = ceil(sqrt(numSlices));
    numCols = numRows;
    stride = size(mosaic, 1)/numRows;
    idxRow = 0:stride:size(mosaic, 1);
    idxCol = idxRow;
    
    % Initialize the volume array output
    volume = zeros(stride, stride, numRows*numCols);
    
    % Convert the image mosaic into a volume array
    c = 1;
    for a = 1:length(idxRow) - 1
        for b = 1:length(idxCol) - 1
            volume(:, :, c) = mosaic(idxRow(a)+1:idxRow(a+1), idxCol(b)+1:idxCol(b+1));
            c = c + 1;
        end
    end
    
    % Remove extra slices contained in the mosaic
    volume = volume(:, :, 1:numSlices);
    
end