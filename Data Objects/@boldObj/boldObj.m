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

%% DEPENDENCIES
%
%   AFNI
%   File Management Package
%   IMG Utilities
%   MATLAB Image Processing Toolbox
%   SPM
%   
%   @BrainPlot
%   @humanObj
%   @Progress
%   @Window
%
%   assignInputs
%   assignOutputs
%   istrue
%   sigFig
%   str2rgb
%   struct2var
%   writeimg

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
%       20140829:   Cleaned up the code here in the class definition file and improved the documentation. Converted the
%                   Preprocess function into a static method that creates new data objects. Rewrote the constructor
%                   method so that it's now capable of creating full BOLD data objects from user inputs. Moved the
%                   Blur, Detrend, ToIMG, and ZScore methods to this class definition file.
%       20140902:   Implemented some status properties that take their values from standardized preprocessing parameter
%                   log entries. Implemented a data cache to store data loaded from MatFiles. Moved the ToMatrix method 
%                   code here to the class definition file. Updated the version number of this software to 2 to reflect 
%                   these (breaking) changes.

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
    properties (Dependent)
        
        IsBlurred
        
    end
    
    properties (SetAccess = protected)
        TE                      % The echo time of the scan session (in milliseconds).
        TR                      % The repetition time of the scan session (in milliseconds).
    end
    
    properties (Access = protected)
        DataCache
    end
    
    properties (Constant, Hidden)
        LatestVersion = 2;      % The current software version behind BOLD data objects.
    end
    
    
    
    %% Constructor Method
    methods
        function boldData = boldObj(varargin)
            %BOLDOBJ - Constructs a BOLD data object for storing and analyzing functional MRI data.
            
            % Construct a new BOLD data object based on the parameters provided
            if (nargin == 0); return
            elseif nargin == 1 && isstruct(varargin{1})
                boldData = boldObj(struct2var(varargin{1}));
            else
                inStruct = struct(...
                    'Acquisition', [],...
                    'Bandwidth', [],...
                    'Data', [],...
                    'FilterShift', [],...
                    'IsFiltered', [],...
                    'IsGlobalRegressed', [],...
                    'IsZScored', [],...
                    'Preprocessing', [],...
                    'Scan', [],...
                    'ScanState', [],...
                    'Subject', [],...
                    'TE', [],...
                    'TR', [],...
                    'UseMatFileStorage', false);
                assignInputs(inStruct, varargin, 'structOnly');
                
                propNames = fieldnames(inStruct);
                for a = 1:length(propNames)
                    if ~isempty(inStruct.(propNames{a}))
                        boldData.(propNames{a}) = inStruct.(propNames{a});
                    end
                end
            end
        end
    end
    
    
    
    %% General Utilities
    methods
        GenerateNuisance(boldData)                                      % Generate & store nuisance signals
        varargout   = Mask(boldData, maskData, confPct, replaceWith)    % Mask BOLD data
        paramStruct = Parameters(boldData)                              % Get data object preprocessing parameters
        varargout   = Plot(boldData, varargin)                          % Plot BOLD data as an image montage
    end
    
    methods
        function isBlurred = get.IsBlurred(boldData)
            isBlurred = false;
            if boldData.IsPreprocessed('Blurring', 'IsBlurred')
                isBlurred = true;
            end
        end
    end
    
    
    
    %% Object Conversion Methods
    methods
        varargout = ToArray(boldData, dataStr)                  % Extract data from a data object & return it as an array
        
        function ToIMG(boldData, savePath)
            %TOIMG Converts BOLD data matrices to NIFTI .img format.
            %   This function converts the functional images in BOLD data objects to IMG files that are used by other
            %   programs, such as GIFT. It extracts the 4-dimensional numerical array (functional volumes over time) and
            %   creates one IMG file for every time point available.
            %
            %   The outputted IMG files are numbered sequentially according to the time point their volume represents.
            %   They are stored in folders organized by subject and scan numbers (the preferred format for GIFT). All of
            %   these subject and scan folders can be found inside one top-level folder called "Preprocessed IMG Files",
            %   which is placed in either a user-specified directory or wherever BOLD objects were stored after
            %   preprocessing.
            %
            %   INPUT
            %   boldData:       BOLDOBJ
            %                   A single BOLD data object containing functional data that should be converted to IMG 
            %                   files.
            %
            %   OPTIONAL INPUT:
            %   savePath:       STRING
            %                   A string indicating the directory where all IMG files will be stored. If no path string
            %                   is provided, this location will default to wherever the inputted data objects were
            %                   stored after preprocessing was performed.
            %
            %                   DEFAULT: boldData.Preprocessing.Parameters.General.OutputPath
            
            % Error check & convert
            boldData.AssertSingleObject;
            boldObj.ArrayToIMG(boldData.ToArray, savePath);
        end
        function [boldMatrix, idsNaN] = ToMatrix(boldData, removeNaNs)
            %TOMATRIX - Extracts a flattened BOLD functional data matrix and removes dead voxels, if called for.
            %
            %   SYNTAX:
            %   boldMatrix = ToMatrix(boldData)
            %   boldMatrix = ToMatrix(boldData, removeNaNs);
            %   [boldMatrix, idsNaN] = ToMatrix(...);
            %
            %   OUTPUT:
            %   boldMatrix:     2D ARRAY
            %                   The functional image data stored inside the BOLD data object flattened into a
            %                   two-dimensional array. This array is formatted as [VOXELS x TIME]. Each row represents a
            %                   single voxel. Each column represents a single time point. To restore the original
            %                   functional data array, use RESHAPE with the original data dimensions as the size input.
            %
            %                   EXAMPLE:
            %                       % Create a 2D array out of the functional data
            %                       funData = ToMatrix(boldData);
            %                       % Restore the original array
            %                       funData = reshape(funData, [91, 109, 91, 218]);
            %
            %   OPTIONAL OUTPUT:
            %   idsNaN:         [BOOLEANS]
            %                   The indices of NaN voxels. This parameter is a vector of Booleans of length equal to the
            %                   number of rows of the flattened functional data matrix (before NaN time series removal).
            %                   Elements of this vector are true when corresponding elements in the first column of the
            %                   BOLD matrix are NaN. If this output is requested without providing a value for the
            %                   'removeNaNs' argument, then that argument defaults to true and NaNs are automatically
            %                   removed from the data.
            %
            %                   The primary use of this variable is to restore the original size of the flattened data
            %                   matrix, which is a necessary step prior to reshaping it into a volume array (see the
            %                   example above).
            %
            %   INPUT:
            %   boldData:       BOLDOBJ
            %                   A single BOLD data object. Arrays of BOLD objects are not supported.
            %
            %   OPTIONAL INPUT:
            %   removeNaNs:     BOOLEAN
            %                   Remove any voxels with time series composed entirely of NaNs. These frequently represent
            %                   non-brain space in volume (such as the volume surrounding the brain or the ventricles).
            %                   Removing these filler values significantly reduces the size of the data array. If this
            %                   parameter is not supplied as an input argument, then it defaults to true only if the
            %                   'idsNaN' output is requested by the caller. Otherwise, if only one output is requested
            %                   ('boldMatrix'), this defaults to false and NaNs are not removed from the data matrix.
            %                   Manually specifying this argument overrides these default behaviors. DEFAULT:
            %                       true    - If two outputs are requested (i.e. including idsNaN)
            %                       false   - If only one output is requested
            
            % Deal with missing inputs
            if nargin == 1
                if (nargout == 1); removeNaNs = false;
                else removeNaNs = true;
                end
            end

            % Ensure that only one object is converted at a time
            boldData.AssertSingleObject;

            % Pull functional data from the object & flatten it to two dimensions
            boldMatrix = boldData.ToArray;
            boldMatrix = reshape(boldMatrix, [], size(boldMatrix, 4));

            % Remove NaNs from the data matrix if called for
            idsNaN = isnan(boldMatrix(:, 1));
            if istrue(removeNaNs); boldMatrix(idsNaN, :) = []; end
        end
    end
    
    methods (Static)
        function ArrayToIMG(boldArray, savePath)
            %ARRAYTOIMG - Converts 4D functional data arrays to NIFTI .img files.
            %
            %   SYNTAX:
            %   boldObj.ArrayToIMG(array, savePath)
            %
            %   INPUTS:
            %   array:      4D ARRAY
            %               A 4-dimensional data array (space x time formatted as [X Y Z T]) representing 3D functional 
            %               images over time. Each outputted IMG file corresponds with a volume at a single time point.
            %
            %   savePath:   STRING
            %               A string indicating the top-level directory where all IMG files will be stored.
            
            if ~exist(savePath, 'dir'); mkdir(savePath); end
            szBOLD = size(boldArray);
            pbar = Progress('-fast', 'Converting BOLD Array to IMG Files');
            for a = 1:szBOLD(4)
                currentSaveStr = sprintf('%s/%03d.img', savePath, a);
                writeimg(currentSaveStr, boldArray(:, :, :, b), 'double', [2 2 2], szBOLD(1:3));
                pbar.Update(a/szBOLD(4));
            end
            pbar.close;
        end
    end
    
    
    
    %% Image & Signal Processing Methods
    methods
        Filter(boldData, varargin)              % FIR Filter the BOLD data time series
        Regress(boldData, signal)               % Regress signals from the BOLD data
        Resample(boldData, fs)
        
        function Blur(boldData, hsize, sigma)
            %BLUR - Spatially Gaussian blur BOLD image series.
            %
            %   SYNTAX:
            %   Blur(boldData, hsize, sigma)
            %
            %   INPUTS:
            %   boldData:       BOLDOBJ
            %                   A single BOLD data object.
            %
            %   hsize:          INTEGER or [INTEGER, INTEGER]
            %                   An integer or 2-element vector of integers representing the size (in [HEIGHT, WIDTH]
            %                   pixels) of the Gaussian used to blur the data. A single scalar input generates a
            %                   symmetric Gaussian.
            %
            %   sigma:          DOUBLE
            %                   The standard deviation (in pixels) of the Gaussian used to blur the data. This must be a
            %                   single double-precision value.
            
            % Error check
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Blur the functional data
            funData = boldData.ToArray;
            fspec = fpsecial('gaussian', hsize, sigma);
            for a = 1:size(boldData, 4)
                funData(:, :, :, a) = imfilter(funData(:, :, :, a), fspec);
            end
            
            % Blur the segment images
            segmentStrs = fieldnames(boldData.Data.Segments);
            for a = 1:length(segmentStrs)
                boldData.Data.Segments.(segmentStrs{a}) = imfilter(boldData.Data.Segments.(segmentStrs{a}), fspec);
            end
            
            % Store the blurred data
            boldData.Data.Functional = funData;
            
            % Change data object preprocessing parameters
            boldData.Preprocessing.Parameters.Blurring = struct(...
                'IsBlurred', true,...
                'Size', hsize,...
                'Sigma', sigma);
            boldData.IsZScored = false;
        end
        function Detrend(boldData, order)
            %DETREND - Detrend BOLD data time series using a polynomial of the specified order.
            %
            %   SYNTAX:
            %   Detrend(boldData, order)
            %
            %   INPUTS:
            %   boldData:   BOLDOBJ
            %               A BOLD data object containing a functional image time series to be detrended.
            %
            %   order:      INTEGER
            %               Any positive integer representing the order of the polynomial used for detrending. 
            %               EXAMPLES:
            %                   1 - Linear detrend
            %                   2 - Quadratic detrend
            %                   3 - Cubic detrend
            %                   .
            %                   .
            %                   .
            
            % Error check
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Get & flatten the functional data
            [funData, idsNaN] = boldData.ToMatrix;
            szBOLD = size(boldData.Data.Functional);
            
            % Detrend the functional time series
            for a = 1:size(funData, 1)
                polyCoeffs = polyfit(1:szBOLD(end), funData(a, :), order);
                funData(a, :) = funData(a, :) - polyval(polyCoeffs, 1:szBOLD(end));
            end
            
            % Restore the volume array & store it in the data object
            volData = nan(length(idsNaN), szBOLD(end));
            volData(~idsNaN, :) = funData;
            boldData.Data.Functional = reshape(volData, szBOLD);
            
            % Change data object preprocessing parameters
            Detrend@humanObj(boldData, order);
            boldData.Data.IsZScored = false;
        end
        function ZScore(boldData)
            %ZSCORE - Scales BOLD voxel time courses to zero mean and unit variance.
            %   This function converts BOLD voxel time series with arbitrary amplitude units to standard scores.
            %   Standard scoring re-expresses data as a fraction of the data's standard deviation. In this case, for any
            %   given BOLD voxel data point, the average amplitude over all time is subtracted away and the data point
            %   is then divided by the standard deviation of the voxel signal.
            %
            %
            %   SYNTAX:
            %   ZScore(boldData)
            %
            %   INPUT:
            %   boldData:       BOLDOBJ
            %                   A BOLD data object with functional time series to be standard scored.
            
            % Error check
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Pull the functional data from the data object
            [funData, idsNaN] = boldData.ToMatrix;
            szBOLD = size(boldData.Data.Functional);
            
            % Z-Score the data & store it in the data object
            funData = zscore(funData, 0, 2);
            volData = nan(length(idsNaN), szBOLD(end));
            volData(~idsNaN, :) = funData;
            boldData.Data.Functional = reshape(volData, szBOLD);
            boldData.IsZScored = true;
        end
    end    
    
    
    
    %% Preprocessing Methods
    methods
        PrepBRIKToIMG(boldData)                 % Convert BRIK files into NIFTI format
        PrepCondition(boldData, varargin)       % Condition the BOLD signals for analysis
        PrepDCMToIMG(boldData)
        PrepImportIMG(boldData)                 % Import IMG files to the MATLAB workspace
        PrepInitialize(boldData, varargin)      % Initialize a BOLD data object for preprocessing
        PrepMean(boldData)                      % Create a mean functional DICOM & IMG file
        PrepMotion(boldData)                    % Correct for motion using SPM
        PrepMotionSliceTime(boldData)           % Correct for motion & slice timing using AFNI
        PrepNormalize(boldData, varargin)       % Normalize the data to MNI space
        PrepRegister(boldData, varargin)        % Register functional images to anatomical images
        PrepSegment(boldData, varargin)         % Segment the anatomical image
    end
    
    methods (Static)
        Preprocess(paramStruct)                 % Preprocess raw BOLD data & create new data objects
    end
       
    
    
    %% Static Utility Functions
    methods (Static)
        output = loadobj(input)                 % Allow older incompatible stored data objects to be loaded
    end
    
    methods (Static, Access = protected)
        CleanRawFolders(inPath, varargin)       % Clean out raw data folders during preprocessing
        boldStruct = upgrade(boldStruct)
    end
    
    
    
end