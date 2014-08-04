function dataStruct = dataStructMeanDicom(dataStruct)
%DATASTRUCTMEANDICOM Creates a mean DICOM image from functional imaging data.
%   This function averages together all functional data from a single scan over the time dimension
%   to produce a mean DICOM image of the data used in later preprocessing steps.
%
%   SYNTAX:
%   dataStruct = dataStructMeanDicom(dataStruct)
%
%   OUTPUT:
%   dataStruct:     The human data structure with a reference to the mean functional image file.
%
%   INPUT:
%   dataStruct:     A human data structure.
%
%   Written by Josh Grooms on 20130628

%% Initialize
functionalFolder = dataStruct.Files.FunctionalFolder;
meanFolder = [functionalFolder '/mean'];
numSlices = dataStruct.Files.NumSlicesPerFile;

% Make a folder for the mean data
if ~exist(meanFolder, 'dir')
    mkdir(meanFolder);
else
    error('Junk data present in data folders. Run "cleanRawFolders" before preprocessing')
end

% Get images & info from the functional directory
dataFiles = get(fileData(functionalFolder, 'ext', '.dcm'), 'Path');
dataFileInfo = dicominfo(dataFiles{1});
dataWidth = dataFileInfo.Width;
dataHeight = dataFileInfo.Height;

% Pre-allocate the data storage array
dicomData = zeros(floor(dataWidth), floor(dataHeight), floor(numSlices), floor(length(dataFiles)/numSlices));


%% Average together Images
% Concatenate images (copied from "readDicomDirectory", but I have no idea why it's done this way...)
b = 1;
c = 1;
for a = 1:length(dataFiles)
    dicomData(:, :, b, c) = dicomread(dataFiles{a});
        b = b + 1;
    if b > numSlices
        b = 1;
        c = c + 1;
    end
end

% Average the data together
meanData = mean(dicomData, 4);


%% Write the Mean Data to a DICOM File
dicomwrite(uint16(round(meanData)), [meanFolder '/mean.dcm'], 'CreateMode', 'copy', 'WritePrivate', true);
dataStruct.Files.MeanDicom = [meanFolder '/mean.dcm'];
