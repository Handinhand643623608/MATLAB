classdef boldObj < humanObj
%BOLDOBJ Generates a standardized BOLD data object containing various properties.
%   This object is a subclass of the "humanData" abstract class and contains BOLD-specific data, attributes, and
%   methods. It also implements the ability to import and preprocess raw fMRI data (only from the Siemens 3T scanner at
%   CABI for now).
%
%   This BOLD data object is intended to be created whenever new data are being preprocessed. To preprocess new data,
%   acquire and modify the class parameter structure, then input it into the class constructor method. To create an
%   empty data object, simply supply no parameters to the constructor.
%   
%   DETAILED INSTRUCTIONS:
%   To use this object to import and preprocess the data, follow these instructions:
%       1. Call up all available preprocessing parameters as a structure.
%            
%          SYNTAX:
%          paramStruct = parameters(boldObj)
%
%       2. Modify the parameter structure as needed. 
%
%          Usually, you will only need to modify the fields labeled "General" and "Initialization" prior to
%          preprocessing. These fields contain file paths and commonly changed parameters that you must supply. The
%          remaining fields of this structure contain parameters related to the various stages of preprocessing.
%          Starting values are supplied for you; they are for the most part the default parameters that SPM supplies for
%          a given procedure. 
%
%          To read about what each parameter in the structure means, consult the help documentation for the function it
%          is used in. Each parameter exists in a substructure named similarly to the function it is used in (e.g.
%          "Conditioning" parameters are used in the "PrepCondition" method). All preprocessing-related methods are
%          prepended with a "Prep" designation.
%
%       3. Instantiate a BOLD data object using the parameter structure as the sole input to the constructor. When
%          preprocessing raw BOLD data, no outputs are returned; the preprocessing methods save a new data object to the
%          hard drive for every subject that is processed. 
%
%          SYNTAX:
%          boldObj(paramStruct)
%
%   NOTES ON PREPROCESSING:
%   Preprocessing of raw data automatically generates a BOLD data object for each individual subject. Each object
%   contains all of that subject's individual scans by generating an object vector of length equal to the subject's
%   final scan number. These objects are also automatically saved to the hard drive. Optionally, these data objects can
%   be converted into a structure format during or after preprocessing using the associated TOSTRUCT method.
%
%   All raw data folders should be consistently named and placed inside of a single folder so that the preprocessing
%   algorithm can find the data. Some kind of string that identifies these folders needs to be supplied to the parameter
%   structure so that the correct data are used. 

%% OBJECT DEPENDENCIES
%
%   AFNI
%   File Management Package
%   IMG Utilities
%   MATLAB Image Processing Toolbox
%   SPM
%   
%   @brainPlot
%   @humanObj
%   @progress
%   @windowObj
%
%   assignInputs
%   assignOutputs
%   istrue
%   sigFig
%   str2rgb
%   struct2var
%   writeimg
%
%   colinBrain.mat

%% CHANGELOG
%   Written by Josh Grooms on 20130318
%       20130324:   Added function to construct masks using RSNs isolated by ICA.
%       20130623:   Added function to import regressed nuisance signals from human_data structures.
%       20130707:   Added ability to preprocess raw BOLD data by invoking this object. 
%       20130708:   Removed automatic z-scoring of data on object construction.
%       20130710:   Reorganized object methods into specific sections. Added preprocessing methods to object. Outlined 
%                   new signal processing methods for future development.
%       20130730:   Implemented a function to convert the BOLD data object into old human_data structures. Removed 
%                   several superfluous input options that are no longer used. Updated & filled in object documentation.
%       20130919:   Implemented a detrending function for BOLD voxel time series. Implemented spatial Gaussian blurring 
%                   of BOLD image series.
%       20140612:   Reorganized class documentation so that the help section isn't overwhelmed by the other notes.
%                   Removed several deprecated methods that are no longer used or are so outdated that they need a
%                   complete rewrite. Made big improvements to the documentation for this class, both here and
%                   throughout the associated methods. 
%       20140617:   Implemented a utility for extracting functional data from a data object and flattening it to a
%                   two-dimensional array. This will be helpful for a number of other functions and scripts.
%       20140618:   Implemented a shortcut method for extracting frequently needed data from objects. This new method
%                   also has the ability to aggregate BOLD nuisance and ICA data.
%       20140623:   Implemented a new static method for converting 4D arrays into IMG files. 
%       20140625:   Fixed the Plot function by removing all dependencies on my personal file structure.
%       20140630:   Changed some of the functionality of the TOMATRIX method to now automatically remove NaN voxels and
%                   provide their indices as an output argument.
%       20140711:   Moved several object methods and properties to the abstract HUMANOBJ class because of duplicate
%                   functionality with EEG data objects.
%       20140720:   Implemented LOADOBJ and UPGRADE functions so that old data objects can be made compatible with
%                   recent changes to human data object classes.

%% TODOS
% Immediate Todos
% - Implement SPM slice timing correction
%   > Prevents having to use a Linux machine for preprocessing.
% - Implement a volume rendering method.
% - Simplify the preprocessing procedure
%   > Maybe implement a GUI for parameter selection
%   > Remove the need for instantiating a parameter structure before preprocessing
% - Fix hard-coded preprocessing dependency on IMG folder name.
%   > Maybe just hard-code all folders like this to simplify the parameter structure?
%
% Future Todos
% - Automate the ICA process
% - Implement session numbers


    
    %% Set the Object Properties
    properties (SetAccess = protected)
        TE                      % The echo time of the scan session (in milliseconds).
        TR                      % The repetition time of the scan session (in milliseconds).
    end
    
    properties (Constant, Hidden)
        LatestVersion = 1;      % The current software version behind BOLD data objects.
    end
    
    
    
    %% Constructor Method
    methods
        function boldData = boldObj(paramStruct)
            %BOLDOBJ Imports, preprocesses, & stores BOLD data as a data object.
            
            % If a parameter structure is given, preprocess raw BOLD data. Otherwise, create an empty object.
            if nargin ~= 0
                if isstruct(paramStruct)
                    Preprocess(boldData, paramStruct);
                else
                    error('Input must be a structure specifying the preprocessing parameters');
                end
            end
        end
    end
    
    
    
    %% General Utilities
    methods
        boldData = Create(varargin)
        % Generate & store nuisance signals
        GenerateNuisance(boldData)
        % Mask BOLD data
        varargout = Mask(boldData, maskData, confPct, replaceWith)
        % Get data object preprocessing parameters
        paramStruct = Parameters(boldData)
        % Plot BOLD data as an image montage
        varargout = Plot(boldData, varargin)
    end
    
    
    
    %% Object Conversion Methods
    methods
        % Extract data from a data object & return it as an array
        varargout = ToArray(boldData, dataStr)
        % Convert BOLD matrix data to IMG files (useful for ICA)
        ToIMG(boldData, savePath)
        % Extract the BOLD functional data & flatten it to a 2D array
        [boldMatrix, idsNaN] = ToMatrix(boldData, removeNaNs)
        % Convert BOLD data objects into data structures
        boldStruct = ToStruct(boldData)
    end
    
    
    
    %% Image & Signal Processing Methods
    methods
        % Spatial Gaussian blurring
        Blur(boldData, hsize, sigma)
        % Detrend the BOLD data time series
        Detrend(boldData, order)
        % FIR Filter the BOLD data time series
        Filter(boldData, varargin)
        % Regress signals from the BOLD data
        Regress(boldData, signal)
        % Z-Score the BOLD data time series
        ZScore(boldData)
    end    
    
    
    
    %% Preprocessing Methods
    methods
        % Preprocess new BOLD data
        Preprocess(boldData, paramStruct)                               
        % Initialize a BOLD data object for preprocessing
        PrepInitialize(boldData, varargin)
        % Create a mean functional DICOM & IMG file
        PrepMean(boldData)
        % Segment the anatomical image
        PrepSegment(boldData, varargin)
        % Correct for motion & slice timing using AFNI
        PrepMotionSliceTime(boldData)
        % Convert BRIK files into NIFTI format
        PrepBRIK2NIFTI(boldData)
        % Register functional images to anatomical images
        PrepRegister(boldData, varargin)
        % Normalize the data to MNI space
        PrepNormalize(boldData, varargin)
        % Import IMG files to the MATLAB workspace
        PrepImport(boldData)
        % Condition the BOLD signals for analysis
        PrepCondition(boldData, varargin)
    end
    
        
    
    %% Static Methods
    methods (Static)
        % Convert 4D functional data to IMG files
        function toIMG(boldArray, savePath)
            %TOIMG Converts functional data over time to NIFTI .img files.
            szBOLD = size(boldArray);
            for a = 1:szBOLD(4)
                currentSaveStr = sprintf('%s/%03d.img', savePath, a);
                writeimg(currentSaveStr, boldArray(:, :, :, b), 'double', [2 2 2], szBOLD(1:3));
            end
            
        end
        % Allow older incompatible stored data objects to be loaded
        output = loadobj(input)
    end
    
    
    
    %% Static Preprocessing Methods
    methods (Static, Access = protected)
        % Clean out raw data folders during preprocessing
        CleanRawFolders(inPath, varargin)
        
        boldStruct = upgrade(boldStruct)
    end
end