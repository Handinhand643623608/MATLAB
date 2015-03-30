function dataStruct = dataStructInitialize(varargin)
%DATASTRUCTINITIALIZE Initialize the human data structure.
%   This function constructs the human data structure using user-specified inputs. Primarily, these
%   inputs are references to critical files and folders that will be needed for preprocessing.
%   Inputs can be supplied using Name/Value pairings or by inputting a filled-in parameter
%   structure. For this function, all inputs must be supplied.
%
%   SYNTAX:
%   dataStruct = dataStructInitialize('PropertyName', PropertyValue...)
%
%   OUTPUT:
%   dataStruct:             The initialized data structure containing references to needed files.
%   
%   INPUTS:
%   'AnatomicalFolder':     The path string to the current subject's anatomical data folder.
%
%   'FunctionalFolder':     The path string to the current subject's functional data folder.
%
%   'IMGFolder':            The path string to the current subject's IMG folder.
%
%   'NumSlicesPerFile':     The number of brain slices per DICOM file.
%
%   'TR':                   The TR of the BOLD data in seconds.
%
%   OPTIONAL INPUTS:
%   'MNIBrain':             The path string to the MNI anatomical brain. This is usually found in
%                           the MNI templates folder.
%                           DEFAULT: '/shella-lab/Josh/Globals/MNI/template/T1.nii'
%
%   'MNIFolder':            The path string to all MNI data (templates, ROIs, and segments).
%                           DEFAULT: '/shella-lab/Josh/Globals/MNI'
%
%   'ROIFolder':            The path string to the MNI ROI folder. This is usually a subdirectory of
%                           the MNI folder.
%                           DEFAULT: '/shella-lab/Josh/Globals/MNI/roi'
%
%   'SegmentsFolder':       The path string to the MNI segments folder. This is usually a
%                           subdirectory of the MNI folder.
%                           DEFAULT: '/shella-lab/Josh/Globals/MNI/segments'
%
%   Written by Josh Grooms on 20130630


%% Initialize
if isstruct(varargin{1})
    inStruct = varargin{1};    
    
    % Fill in values that can be derived
    if ~isfield(inStruct, 'MNIBrain') || isempty(inStruct.MNIBrain)
        inStruct.MNIBrain = [inStruct.MNIFolder '/template/T1.nii'];
        inStruct.ROIFolder = [inStruct.MNIFolder '/roi'];
        inStruct.SegmentsFolder = [inStruct.MNIFolder '/segments'];
    end
else
    inStruct = struct(...
        'AnatomicalFolder', [],...
        'FunctionalFolder', [],...
        'IMGFolder', [],...
        'MNIBrain', '/shella-lab/Josh/Globals/MNI/template/T1.nii',...
        'MNIFolder', '/shella-lab/Josh/Globals/MNI',...
        'NumSlicesPerFile', [],...
        'ROIFolder', '/shella-lab/Josh/Globals/MNI/roi',...
        'SegmentsFolder', '/shella-lab/Josh/Globals/MNI/segments',...
        'TR', []);
    assignInputs(inStruct, varargin, 'StructOnly',...
        {'AnatomicalFolder', 'FunctionalFolder', 'IMGFolder', 'MNIFolder', 'ROIFolder', 'SegmentsFolder'},...
        'regrexprep(varPlaceholder, ''(/$)'', '')');
end

% Initialize structure
dataStruct = struct('Files', [], 'Parameters', [], 'Data', []);


%% Transfer Data into Structure
propNames = fieldnames(inStruct);
for a = 1:length(propNames)    
    switch propNames{a}        
        case 'TR'
            dataStruct.Parameters.TR = inStruct.TR;            
        otherwise
            dataStruct.Files.(propNames{a}) = inStruct.(propNames{a});
    end
end
