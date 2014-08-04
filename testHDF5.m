%% testHDF5


%% Initialize
% General Parameters
dataFile = 'test.bold';
dataSet = '/RS/Infraslow/GSR/1/1/Functional';
chunkSize = [1 1 1 218];
attStr = 'TR';

% Low level (ll) parameters
llFileFlag = 'H5F_ACC_EXCL';
llPID = 'H5P_DEFAULT';
llDataTypeID = H5T.copy('H5T_NATIVE_DOUBLE');
H5F.create(

% Load data
load masterStructs
if ~exist('boldData', 'var')
    load boldObject-1_RS_dcGRZ_20130623
    testData = boldData(1).Data.Functional;
end
cd('E:\Graduate Studies\Lab Work\Data Sets\HDF5 Data');

% Other, dependent parameters
szBOLD = size(boldData(1).Data.Functional;
attToWrite = boldData(1).(attStr);


%% High Level Interface

h5create(dataFile, dataSet, szBOLD, chunkSize);
h5write(dataFile, dataSet, boldData(1).Data.Functional);
h5writeatt(dataFile, dataSet, attStr, attToWrite);


%%%% Low Level Interface

%% Create the HDF5 data file
fileID = H5F.create(dataFile, llFileFlag, llPID, llPID);
    % Syntax:
    %   fileID = H5F.create(fileName, fileFlag, createPropListID, accessPropListID)
    % 
    % Output:
    %   fileID
    %
    % Inputs:
    %   fileName:           The string name of the file (HDF5) being created.
    %
    %   fileFlag:           A string specifying whether to overwrite the file ('H5F_ACC_TRUNC') or
    %                       fail ('H5F_ACC_EXCL') if it already exists.
    %
    %   createPropListID:   A string specying the file creation property list identifier.
    %                       Options:
    %                           
    %
    %   accessPropListID:

attID = H5A.create(fileID, attStr, llDataTypeID, dataSpaceID, 

if isequal(szBOLD(1:2), [91 109]), szBOLD(1:2) = fliplr(szBOLD(1:2)); end    
dataSpaceID = H5S.create_simple(length(szBOLD), szBOLD, []);

plistID = H5P.create('H5P_DATASET_CREATE');
H5P.set_chunk(plistID, chunkSize);

dataSetID = H5D.create(fileID,...
    dataSet,...
    dataTypeID,...
    dataSpaceID,...
    plistID);

H5D.write(dataSetID,...
    'H5ML_DEFAULT',...
    'H5S_ALL',...
    'H5S_ALL',...
    plistID,...
