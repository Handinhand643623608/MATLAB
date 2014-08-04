function volume = dicomvolume(filename)
%DICOMVOLUME - Reads in a DICOM image mosaic and breaks it up to produce a volumetric array.
%
%   SYNTAX:
%   volume = dicomvolume(filename)
%
%   OUTPUT:
%   volume:         3D ARRAY
%                   A volumetric array produced from the image mosaic in a DICOM file. The dimensions of this image
%                   depend entirely on the original scanning parameters and are determined automatically through
%                   information contained in the DICOM header section. The orientation of the images in this volume
%                   array is the same as is produced by the MATLAB native function DICOMREAD. 
%
%   INPUT:
%   filename:       STRING
%                   A full path string to a DICOM image (a file with a .dcm extension). This file must contain a Siemens
%                   image mosaic in order for this function to be effective.
%
%   See also: DICOMINFO, DICOMREAD

%% CHANGELOG
%   Written by Josh Grooms on 20140728



%% 
% Read in the DICOM mosaic & header information
mosaic = dicomread(filename);
dcmInfo = spm_dicom_headers(filename);

% Get the number of slices in the mosaic from the private Siemens header section
tempHeaderNames = {dcmInfo{1}.CSAImageHeaderInfo.name};
tempHeaderInfo = dcmInfo{1}.CSAImageHeaderInfo(strcmpi(tempHeaderNames, 'numberofimagesinmosaic'));
numSlices = eval(tempHeaderInfo.item(1).val);

% Calculate parameters for parsing the mosaic by individual slices
numImageRows = ceil(sqrt(numSlices));
numImageCols = numImageRows;
stride = size(mosaic, 1)/numImageRows;

% Initialize the output volume array
volume = zeros(stride, stride, numImageRows*numImageCols);

% Calculate individual image pixel bounds
idxImageRow = 0:stride:size(mosaic, 1);
idxImageCol = 0:stride:size(mosaic, 2);

% Parse the mosaic & break it into individual images
c = 1;
for a = 1:length(idxImageRow) - 1
    for b = 1:length(idxImageCol) - 1     
        volume(:, :, c) = mosaic((idxImageRow(a) + 1):idxImageRow(a + 1), (idxImageCol(b) + 1):idxImageCol(b + 1));
        c = c + 1;
    end
end

% Get rid of extra slices in the mosaic
volume = volume(:, :, 1:numSlices);