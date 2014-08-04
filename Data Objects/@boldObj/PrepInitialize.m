function PrepInitialize(boldData, varargin)
%PREPINITIALIZE Initialize the BOLD data object for preprocessing.
%   This function inintializes the BOLD data object using user-specified inputs. Primarily, these inputs are references
%   to critical files and folders that will be needed for preprocessing. Inputs can be supplied using Name/Value
%   pairings or by inputting a filled-in parameter structure.
%
%   This function is designed to accept a BOLD data object (with parameters embedded) as the single input. However,
%   parameters inside of the object can be overridden by inputting new parameters as "Name/Value" pairs after the object
%   input.
%
%   For this and all other preprocessing functions, outputs are not required because objects are linked across
%   workspaces.
%
%   SYNTAX:
%   PrepInitialize(boldData)
%   PrepInitialize(boldData, 'PropertyName', PropertyValue...)
%   
%   INPUTS:
%   'AnatomicalFolderStr':  STRING
%                           The unique string identifying the current subject's anatomical data folder.
%                           DEFAULT: 't1_MPRAGE'
%
%   'DataPath':             STRING
%                           The path string to the directory where all subject folders (containing all scan folders) is
%                           located.
%                           DEFAULT: '/shella-lab/Josh/Data/Raw'
%
%   'FunctionalFolderStr':  STRING
%                           The unique string identifying the current subject's functional data folder.
%                           DEFAULT: 'ep2d_'
%
%   'IMGFolderStr':         STRING
%                           The name of current subject's IMG folder. This is what the folder will be called once
%                           created.
%                           DEFAULT: 'IMG'
%
%   'MNIBrain':             STRING
%                           The path string to the MNI anatomical brain. This is usually found in the MNI templates
%                           folder.
%                           DEFAULT: '/shella-lab/Josh/Globals/MNI/template/T1.nii'
%
%   'MNIFolder':            STRING
%                           The path string to all MNI data (templates, ROIs, and segments).
%                           DEFAULT: '/shella-lab/Josh/Globals/MNI'
%
%   'ROIFolder':            STRING
%                           The path string to the MNI ROI folder. This is usually a subdirectory of the MNI folder.
%                           DEFAULT: '/shella-lab/Josh/Globals/MNI/roi'
%
%   'SegmentsFolder':       STRING
%                           The path string to the MNI segments folder. This is usually a subdirectory of the MNI
%                           folder.
%                           DEFAULT: '/shella-lab/Josh/Globals/MNI/segments'
%
%   'SubjectFolderStr':     STRING
%                           A unique string used to identify subject data folders. The search algorithm uses REGEXP to
%                           find this string, so generalities in the form of metacharacters and wildcards are
%                           acceptable.
%                           DEFAULT: '1..A'



%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20130708:   Developed method to get the correct number of slices per image mosaic in Siemens DICOM image files.
%                   Implemented transfer of TE/TR from acquisition parameters to uppermost object properties. Added
%                   storage of voxel dimensions.
%       20130710:   Updated documentation. Removed option for inputting a parameter structure.



%% Initialize
% Get the user-specified initialization parameters
if nargin == 1
    inStruct = boldData.Preprocessing.Parameters.Initialization;
else
    inStruct = struct(...
        'AnatomicalFolderStr', 't1_MPRAGE_',...
        'DataPath', '/shella-lab/Josh/Data/Raw',...
        'FunctionalFolderStr', 'ep2d_',...
        'IMGFolderStr', 'IMG',...
        'MNIBrain', '/shella-lab/Josh/Globals/MNI/template/T1.nii',...
        'MNIFolder', '/shella-lab/Josh/Globals/MNI',...
        'ROIFolder', '/shella-lab/Josh/Globals/MNI/roi',...
        'SegmentsFolder', '/shella-lab/Josh/Globals/MNI/segments',...
        'SubjectFolderStr', '1..A_');
    assignInputs(inStruct, varargin, 'StructOnly',...
        {'AnatomicalFolder', 'FunctionalFolder', 'IMGFolder', 'MNIFolder', 'ROIFolder', 'SegmentsFolder'},...
        'regrexprep(varPlaceholder, ''(/$)'', '')');
end



%% Get File & Directory Information
% Get the current subject's data folder
allSubjectFolders = get(fileData(inStruct.DataPath, 'Folders', 'on', 'Search', inStruct.SubjectFolderStr), 'Path');
boldData.Preprocessing.Folders.Root = allSubjectFolders{boldData.Subject};

% Get the current scan functional data folder
allScansFolders = get(fileData(boldData.Preprocessing.Folders.Root, 'Folders', 'on', 'Search', inStruct.FunctionalFolderStr), 'Path');
boldData.Preprocessing.Folders.Functional = allScansFolders{boldData.Scan};

% Get the current subject's anatomical folder
anatomicalFolder = get(fileData(boldData.Preprocessing.Folders.Root, 'Folders', 'on', 'Search', inStruct.AnatomicalFolderStr), 'Path');
boldData.Preprocessing.Folders.Anatomical = anatomicalFolder{1};

% Determine where to store IMG files, once generated
imgFolder = [boldData.Preprocessing.Folders.Functional '/' inStruct.IMGFolderStr];
if ~exist(imgFolder, 'dir')
    mkdir(imgFolder)
end
boldData.Preprocessing.Folders.IMG.Root = imgFolder;



%% Pull Valuable Information from DICOM Files in the Functional Folder
tempDCMFile = get(fileData(boldData.Preprocessing.Folders.Functional, 'ext', '.dcm'), 'Path');
dcmInfo = dicominfo(tempDCMFile{1});
fieldsOfInterest = {'AcquisitionDate', 'AcquisitionMatrix', 'EchoTime', 'FlipAngle',...
    'MagneticFieldStrength', 'NumberOfPhaseEncodingSteps', 'RepetitionTime', 'ScanningSequence',...
    'SliceThickness'};
for a = 1:length(fieldsOfInterest)
    boldData.Acquisition.(fieldsOfInterest{a}) = dcmInfo.(fieldsOfInterest{a});
end

% Get voxel dimensions (in mm)
boldData.Acquisition.VoxelSize = [dcmInfo.PixelSpacing' dcmInfo.SliceThickness];

% If DICOMs are Siemens mosaics, get the number of slices per file from private header information
if strcmpi(dcmInfo.Manufacturer, 'siemens') && strcmpi(dcmInfo.ImageType(end-5:end), 'mosaic')
    tempDCMInfo = spm_dicom_headers(tempDCMFile{1});
    tempHeaderNames = {tempDCMInfo{1}.CSAImageHeaderInfo.name};
    tempHeaderInfo = tempDCMInfo{1}.CSAImageHeaderInfo(strcmpi(tempHeaderNames, 'numberofimagesinmosaic'));
    boldData.Acquisition.NumberOfSlices = eval(tempHeaderInfo.item(1).val);
else
    error('Unable to read DICOM imaging parameters. Scanners not made by Siemens are not yet supported')
end



%% Transfer Remaining Data into the Object
propNames = fieldnames(inStruct);
for a = 1:length(propNames)
    switch propNames{a}
        case 'MNIBrain'
            boldData.Preprocessing.Files.MNIBrain = inStruct.MNIBrain;
        case {'MNIFolder', 'ROIFolder', 'SegmentsFolder'}
            tempPropName = regexprep(propNames{a}, 'Folder', '');
            boldData.Preprocessing.Folders.(tempPropName) = inStruct.(propNames{a});
    end
end

% Transfer important acquisition properties to object properties
boldData.TR = boldData.Acquisition.RepetitionTime;
boldData.TE = boldData.Acquisition.EchoTime;
