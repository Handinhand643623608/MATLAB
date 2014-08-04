function dataStructAFNIPreprocess(dataStruct, varargin)
%DATASTRUCTAFNIPREPROCESS Executes motion & slice timing correction in AFNI.
%   This function corrects for motion artifacts and slice timing acquisition effects using AFNI
%   software. It is currently only compatible with computers running the Linux operating system.
%
%   SYNTAX:
%   dataStructAFNIPreprocess(dataStruct)
%
%   INPUT:
%   dataStruct:     The human data structure.
%
%   Written by Josh Grooms on 20130630


%% Intialize
% Get parameters from the data structure
functionalFolder = dataStruct.Files.FunctionalFolder;
functionalDicoms = get(fileData(functionalFolder, 'ext', '.dcm'), 'Path');
numFileSlices = dataStruct.Files.NumSlicesPerFile;
TR = dataStruct.Parameters.TR*1000;


% Calculate number of slices in data
dcmInfo = dicominfo(dataStruct.Files.MeanDicom);
numSlices = numFileSlices*((double(dcmInfo.Width)*double(dcmInfo.Height))/...
    prod(double(dcmInfo.AcquisitionMatrix(dcmInfo.AcquisitionMatrix ~= 0))));

% Determine AFNI parameters
ignoreIndex = 15;
if mod(numSlices, 2) == 0
    order = 'alt+z2';
else
    order = 'alt+z';
end

% Generate an output file name
outputFile = dcmInfo.ProtocolName;

% Delete old files with the same name
extStrs = {'.BRIK', '.HEAD', '.1D'};
for a = 1:length(extStrs)
    delete([functionalFolder '/' outputFile '*' extStrs{a}])
    delete([functionalFolder '/' 'mean/' outputFile '*' extStrs{a}])
end

% Store the current directory to easily switch back after processing
origDir = pwd;


%% AFNI Preprocess the BOLD Data
% Convert functioanl data to AFNI format
cd(functionalFolder);
systemCommand = sprintf('to3d -epan -time:zt %d %d %f %s -prefix %s *.dcm',...
    numSlices, length(functionalDicoms), TR, order, outputFile);
system(systemCommand);

% Convert mean image to AFNI format
cd('mean')
systemCommand = sprintf('to3d -epan -time:zt %d %d %f %s -prefix %s *.dcm',...
    numSlices, 0, TR, order, 'mean');

% Slice timing correction in AFNI
systemCommand = sprintf('3dTshift -Fourier -ignore %d -prefix %s_tshift %s+orig',...
    ignoreIndex, outputName, outputName);
system(systemCommand);

% Return to the original directory
cd(origDir)
