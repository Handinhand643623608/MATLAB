function PrepInitialize(boldData)
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
%       20140929:   Major overhaul of this function to work with the preprocessing parameter structure overhaul. Added
%                   in pulling of slice acquisition order from the DICOM header file (useful for STC later).



%% Initialize
% Get some needed parameters from the data object
params = mergestructs(...
    boldData.Preprocessing.DataPaths,...
    boldData.Preprocessing.DataFolderIDs);



%% Get File & Directory Information
% Get the current subject's data folder
subjDirs = searchdir(params.RawDataPath, params.SubjectFolderID, 'Ext', 'folder');
scanData.RootFolder = subjDirs{boldData.Subject};

% Get the current subject's functional data folder & DICOM files
scanDirs = searchdir(scanData.RootFolder, params.FunctionalFolderID, 'Ext', 'folder');
scanData.FunctionalFolder = scanDirs{boldData.Scan};
scanData.RawFunctionalFiles = searchdir(scanData.FunctionalFolder, [], 'Ext', '.dcm');

% Get the current subject's anatomical data folder & DICOM files
anatDirs = searchdir(scanData.RootFolder, params.AnatomicalFolderID, 'Ext', 'folder');
scanData.AnatomicalFolder = anatDirs{1};
scanData.RawAnatomicalFiles = searchdir(scanData.AnatomicalFolder, [], 'Ext', '.dcm');

% Generate a directory for storing NIFTI files
scanData.IMGFolder = [scanData.FunctionalFolder '/IMG'];
if ~exist(scanData.IMGFolder, 'dir'); mkdir(scanData.IMGFolder); end



%% Pull Valuable Information from DICOM Files in the Functional Folder
% Get a reference to a DICOM file
dcmFiles = searchdir(scanData.FunctionalFolder, [], 'ext', '.dcm');
dcmFile = dcmFiles{floor(length(dcmFiles) / 2)};
dcmInfo = dicominfo(dcmFile);

% Define important fields found in the DICOM header section
fieldsOfInterest = {...
    'AcquisitionDate',...
    'AcquisitionMatrix',...
    'EchoTime',...
    'FlipAngle',...
    'MagneticFieldStrength',...
    'NumberOfPhaseEncodingSteps',...
    'Private_0019_1029',...             % The relative slice acquisition times (useful for determining slice acquisition order)
    'RepetitionTime',...
    'ScanningSequence',...
    'SliceThickness'};

% Pull acquisition data from the DICOM file header
acqData = struct;
for a = 1:length(fieldsOfInterest)
    headerData = dcmInfo.(fieldsOfInterest{a});
    switch fieldsOfInterest{a}
        case 'Private_0019_1029'
            acqData.SliceAcquisitionTimes = headerData;
        otherwise
            acqData.(fieldsOfInterest{a}) = headerData;
    end
end

% Get voxel dimensions (in mm)
acqData.VoxelSize = [dcmInfo.PixelSpacing' dcmInfo.SliceThickness];

% If DICOMs are Siemens mosaics, get the number of slices per file from private header information
if strcmpi(dcmInfo.Manufacturer, 'siemens') && strcmpi(dcmInfo.ImageType(end-5:end), 'mosaic')
    dcmInfoSPM = spm_dicom_headers(dcmFile);
    headerNames = {dcmInfoSPM{1}.CSAImageHeaderInfo.name};
    headerInfo = dcmInfoSPM{1}.CSAImageHeaderInfo(strcmpi(headerNames, 'numberofimagesinmosaic'));
    
    acqData.IsImageMosaic = true;
    acqData.NumberOfSlices = eval(headerInfo.item(1).val);
else
    error('Unable to read DICOM imaging parameters. Scanners not made by Siemens are not yet supported')
end



%% Store Data in the Data Object
boldData.Acquisition = acqData;
boldData.Preprocessing.ScanData = scanData;