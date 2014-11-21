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
%                   log entries. Implemented a data cache to store data loaded from MatFiles. Moved the ToMatrix and 
%                   Regress method code here to the class definition file. Updated the version number of this software 
%                   to 2 to reflect these changes.
%       20140929:   Changed the TR & TE fields to dependent properties that pull from the acquisition structure.
%       20141002:   Bug fixes for the BLUR and IDENTIFYSEGMENTS methods. 
%		20141118:	Moved the logic for the methods GenerateNuisance and Mask to this class definition file. Modified
%					the Mask method so that it only accepts logical arrays as masks and doesn't accept string inputs at
%					all anymore.

%% DEPENDENCIES
%
%   AFNI
%   File Management Package
%   IMG Utilities
%   MATLAB Image Processing Toolbox
%   SPM
%   Structure Utilities
%   
%   @BrainPlot
%   @humanObj
%   @Progress
%   @Window
%
%   assignInputs
%   assignOutputs
%   corr3
%   istrue
%   maskImageSeries
%   searchdir
%   sigFig
%   str2rgb
%   struct2var
%   writeimg

%% TODOS
% Immediate Todos
% - Implement a volume rendering method.
% - Implement data reorientation (i.e. sagittal, coronal, transverse views)
% - Make segment identification more robust
% - Look into improving detrending speed
%
% Future Todos
% - Automate the ICA process
% - Implement session numbers


    
    %% Set the Object Properties    
    properties (Dependent)
        IsBlurred               % Boolean indicating whether the functional data has been spatially blurred.
        NumTimePoints           % The total number of time points in the functional image series.
        TE                      % The echo time of the scan session (in milliseconds).
        TR                      % The repetition time of the scan session (in milliseconds).
    end
    
    properties (Access = protected, Hidden)
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
					'Postprocessing', [],...
                    'Scan', [],...
                    'ScanState', [],...
					'SoftwareVersion', [],...
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
		
		function GenerateNuisance(boldData)
		% GENERATENUISANCE - Estimate and store BOLD nuisance signals.
		%
		%   SYNTAX:
		%   GenerateNuisance(boldData)
		%	boldData.GenerateNuisance()
		%
		%   INPUTS:
		%   boldData:       BOLDOBJ
		%                   A single BOLD data object.
		
			% Error checking
			boldData.AssertSingleObject;
			boldData.LoadData;
			
			% Store a list of nuisance parameters (order here is critical for other functions)
			nuisanceNames = {'Global', 'WM', 'CSF'};
			
			% Get & flatten the functional data
			funData = boldData.ToArray;
			funData = mask(funData, boldData.Data.Masks.Mean, NaN);
			funData = reshape(funData, [], boldData.NumTimePoints);
			funData = funData';
			
			% Regress constant terms & motion parameters first
			motionSigs = boldData.Data.Nuisance.Motion';
			motionSigs = cat(2, ones(size(motionSigs, 1), 1), motionSigs);
			funData = funData - motionSigs * (motionSigs \ funData);
			
			for a = 1:length(nuisanceNames)
				% Generate the nuisance signals & store them in the data object
				if (strcmpi(nuisanceNames{a}, 'global'))
					nuisanceData = nanmean(funData, 2);
					boldData.Data.Nuisance.Global = nuisanceData';
				else
					segMask = boldData.Data.Masks.(nuisanceNames{a})(:);
					nuisanceData = nanmean(funData(:, segMask), 2);
					boldData.Data.Nuisance.(nuisanceNames{a}) = nuisanceData';
				end

				% Regress the current nuisance signal so that the next one isn't influenced by it
				funData = funData - nuisanceData * (nuisanceData \ funData);
			end
		end
		function Mask(boldData, m, r)
		% MASK - Masks BOLD functional images with the inputted logical array.
			if (nargin == 2); r = NaN; end
			boldData.Data.Functional = mask(boldData.ToArray(), m, r);
		end

        varargout   = Plot(boldData, varargin)                          % Plot BOLD data as an image montage            

		% Property get & set methods
        function isBlurred      = get.IsBlurred(boldData)
            isBlurred = boldData.IsPostprocessed('Blurring', 'IsBlurred');
		end
        function numPoints      = get.NumTimePoints(boldData)
            numPoints = size(boldData.Data.Functional, 4);
        end
        function te             = get.TE(boldData)
            te = boldData.Acquisition.EchoTime;
        end
        function tr             = get.TR(boldData)
            tr = boldData.Acquisition.RepetitionTime;
        end

    end
    
    
    
    %% Object Conversion Methods
    methods
        varargout = ToArray(boldData, dataStr)                  % Extract data from a data object & return it as an array
        
        function ToIMG(boldData, outputPath)
		% TOIMG - Converts BOLD data matrices to NIFTI .img format.
		%   This function converts the functional images in BOLD data objects to IMG files that are used by other
		%   programs, such as GIFT. It extracts the 4-dimensional numerical array (functional volumes over time) and
		%   creates one IMG file for every time point available.
		%
		%   The outputted IMG files are numbered sequentially according to the time point their volume represents. They
		%   are stored in folders organized by subject and scan numbers (the preferred format for GIFT). All of these
		%   subject and scan folders can be found inside one top-level folder called "Preprocessed IMG Files", which is
		%   placed in either a user-specified directory or wherever BOLD objects were stored after preprocessing.
		%
		%   INPUT
		%   boldData:       BOLDOBJ
		%                   A single BOLD data object containing functional data that should be converted to IMG files.
		%
		%   OPTIONAL INPUT:
		%   outputPath:     STRING
		%                   A path string referencing the directory where all outputted IMG files will be stored.
            
            % Error check & convert
            boldData.AssertSingleObject;
            boldObj.ArrayToIMG(boldData.ToArray(), outputPath);
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
		%                   single voxel. Each column represents a single time point. To restore the original functional
		%                   data array, use RESHAPE with the original data dimensions as the size input.
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
		%                   Elements of this vector are true when corresponding elements in the first column of the BOLD
		%                   matrix are NaN. If this output is requested without providing a value for the 'removeNaNs'
		%                   argument, then that argument defaults to true and NaNs are automatically removed from the
		%                   data.
		%
		%                   The primary use of this variable is to restore the original size of the flattened data
		%                   matrix, which is a necessary step prior to reshaping it into a volume array (see the example
		%                   above).
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
		%                   Manually specifying this argument overrides these default behaviors.
		%					DEFAULT:
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
        function ArrayToIMG(boldArray, outputPath)
		% ARRAYTOIMG - Converts 4D functional data arrays to NIFTI .img files.
		%
		%   SYNTAX:
		%   boldObj.ArrayToIMG(array, savePath)
		%
		%   INPUTS:
		%   array:          4D ARRAY
		%                   A 4-dimensional data array ([Space x Time] formatted as [X Y Z T]) representing 3D
		%                   functional images over time. Each outputted IMG file corresponds with a volume at a single
		%                   time point.
		%
		%   outputPath:     STRING
		%                   A string indicating the top-level directory where all IMG files will be stored.

            if ~exist(outputPath, 'dir'); mkdir(outputPath); end
            szBOLD = size(boldArray);
            pbar = Progress('-fast', 'Converting BOLD Array to IMG Files');
            for a = 1:szBOLD(4)
                currentSaveStr = sprintf('%s/%03d.img', outputPath, a);
                writeimg(currentSaveStr, boldArray(:, :, :, b), 'double', [2 2 2], szBOLD(1:3));
                pbar.Update(a/szBOLD(4));
            end
            pbar.close;
        end
    end
    
    
    
    %% Image & Signal Processing Methods
    methods
        Filter(boldData, varargin)              % FIR Filter the BOLD data time series
        Resample(boldData, fs)
        
        function Blur(boldData, hsize, sigma, applyToSegments)
		% BLUR - Spatially Gaussian blur BOLD image series.
		%
		%   SYNTAX:
		%   Blur(boldData, hsize, sigma)
		%	Blur(boldData, hsize, sigma, applyToSegments)
		%	boldData.Blur(hsize, sigma)
		%	boldData.Blur(hsize, sigma, applyToSegments)
		%
		%   INPUTS:
		%   boldData:           BOLDOBJ
		%                       A single BOLD data object.
		%
		%   hsize:              INTEGER or [INTEGER, INTEGER]
		%                       An integer or 2-element vector of integers representing the size (in [HEIGHT, WIDTH]
		%                       pixels) of the Gaussian used to blur the data. A single scalar input generates a
		%                       symmetric Gaussian.
		%
		%   sigma:              DOUBLE
		%                       The standard deviation (in pixels) of the Gaussian used to blur the data. This must
		%                       be a single double-precision value.
		%
		%   OPTIONAL INPUTS:
		%   applyToSegments:    BOOLEAN
		%                       A Boolean indicating whether or not to blur the anatomical segment images using the
		%                       same parameters as for the functional data.

            % Deal with missing inputs
            if nargin == 3; applyToSegments = true; end
            
            % Error check
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Blur the functional data
            funData = boldData.ToArray;
            fspec = fspecial('gaussian', hsize, sigma);
            for a = 1:size(boldData, 4)
                funData(:, :, :, a) = imfilter(funData(:, :, :, a), fspec);
            end
            
            % Blur the segment images
            if (applyToSegments)
                segmentStrs = fieldnames(boldData.Data.Segments);
                for a = 1:length(segmentStrs)
                    boldData.Data.Segments.(segmentStrs{a}) = imfilter(boldData.Data.Segments.(segmentStrs{a}), fspec);
                end
            end
            
            % Store the blurred data
            boldData.Data.Functional = funData;
            
            % Change data object preprocessing parameters
            boldData.Postprocessing.Blurring = struct(...
                'IsBlurred', true,...
                'Size', hsize,...
                'Sigma', sigma);
            boldData.IsZScored = false;
        end
        function Detrend(boldData, order)
		% DETREND - Detrend BOLD data time series using a polynomial of the specified order.
		%
		%   SYNTAX:
		%   Detrend(boldData, order)
		%	boldData.Detrend(order)
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
        end
        function Regress(boldData, signal)
		% REGRESS - Linearly regress signals from BOLD functional time series.
		%   This function performs a simple linear regression between a set of signals and all BOLD voxel time series,
		%   finding the best fit (in the least-squares sense) for the signals to the data. It then scales the signals
		%   according to the fitting parameters and subtracts them from the BOLD time series. Thus, the BOLD data that
		%   exists after this method is called are the residual time series left over from the regression.
		%
		%   Linear regression is currently a popular method of removing artifacts from the BOLD data and accounting for
		%   signals that are not likely to be neuronal in origin. Partial correlation, for instance, uses this approach
		%   to control for a set of variables while estimating how two other data sets covary.
		%
		%   However, assuming simple linear relationships between complicated data (i.e. physiological data) is rarely
		%   exactly correct. Care must be taken to ensure that the data fitting is approximately valid. If it is not,
		%   more complex methods of regression may be called for.
		%
		%
		%   SYNTAX:
		%   Regress(boldData, signal)
		%	boldData.Regress(signal)
		%
		%   INPUTS:
		%   boldData:       BOLDOBJ
		%                   A single BOLD data object.
		%
		%   signal:     1D ARRAY or 2D ARRAY
		%               A vector or array of signals to be regressed from the BOLD functional data. This argument must
		%               be provided in the format [SIGNALS x TIME], where time points span the columns of the matrix.
		%               The number of signals (i.e. number of rows) here can be any number, but the number of time
		%               points must equal the number of time points in the BOLD data.
		%
		%               It is not necessary to provide a signal of all ones in this array (i.e. to account for constant
		%               terms), although you may provide one if you wish. This function automatically adds in a constant
		%               signal if one is not present.
            
            % Error check
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Perform the regression & store the residuals
            funData = humanObj.RegressTimeSeries(boldData.ToMatrix, signal);
            boldData.Data.Functional = reshape(funData, size(boldData.Data.Functional));
            boldData.IsZScored = false;
        end
        function ZScore(boldData)
		%ZSCORE - Scales BOLD voxel time courses to zero mean and unit variance.
		%   This function converts BOLD voxel time series with arbitrary amplitude units to standard scores. Standard
		%   scoring re-expresses data as a fraction of the data's standard deviation. In this case, for any given BOLD
		%   voxel data point, the average amplitude over all time is subtracted away and the data point is then divided
		%   by the standard deviation of the voxel signal.
		%
		%
		%   SYNTAX:
		%   ZScore(boldData)
		%	boldData.ZScore()
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
    
    methods (Static)
        StartICA(icaParams)
    end
    
    
    
    %% fMRI Preprocessing Methods
    methods
        PrepBRIKToIMG(boldData)                 % Convert BRIK files into NIFTI format
        PrepCondition(boldData)                 % Condition the BOLD signals for analysis
        PrepDCMToIMG(boldData)
        PrepImportData(boldData)                % Import preprocessed data to the MATLAB workspace
        PrepInitialize(boldData)                % Initialize a BOLD data object for preprocessing
        PrepMean(boldData)                      % Create a mean functional DICOM & IMG file
        PrepMotion(boldData)                    % Correct for motion using SPM
        PrepMotionSliceTime(boldData)           % Correct for motion & slice timing using AFNI
        PrepNormalize(boldData)                 % Normalize the data to MNI space
        PrepRegister(boldData)                  % Register functional images to anatomical images
        PrepSegment(boldData)                   % Segment the anatomical image
        PrepSliceTime(boldData)
        
        function PrepRegressNuisance(boldData)
		% PREPREGRESSNUISANCE - Regress nuisance parameters from BOLD functional data and detrend the time series.
            
            % Error checking
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Get stage parameters from the data object
            regParams = boldData.Preprocessing.NuisanceRegression;
            
            % Detrend the data first, then generate nuisance parameters
            boldData.Detrend(regParams.DetrendOrder);
			boldData.GenerateNuisance();
            
            % Build a list of parameters to regress from the functional time series
            regSignal = ones(1, boldData.NumTimePoints);
            if (regParams.RegressMotion); regSignal = cat(1, regSignal, boldData.Data.Nuisance.Motion); end
            if (regParams.RegressGlobal); regSignal = cat(1, regSignal, boldData.Data.Nuisance.Global); end
            if (regParams.RegressWhiteMatter); regSignal = cat(1, regSignal, boldData.Data.Nuisance.WM); end
            if (regParams.RegressCSF); regSignal = cat(1, regSignal, boldData.Data.Nuisance.CSF); end
            
            % Perform the regression
            boldData.Regress(regSignal);
            
        end
    end
    
    methods (Static)
        Preprocess(params)                      % Preprocess raw BOLD data & create new data objects
        paramStruct = PrepParameters            % Get data object preprocessing parameters
    end
    
    
    
    %% Anatomical Segment Postprocessing Methods
    methods
        
        function GenerateSegmentMasks(boldData)
		% GENERATESEGMENTMASKS - Converts segmented anatomical images in binary volumetric data masks.
            
            % Initial error checking
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Get needed parameters & ensure segments have been identified
            params = boldData.Preprocessing.SegmentThresholds;
            segData = boldData.Data.Segments;
            if (~isstruct(segData)); error('Segments must already be identified to generate segment masks.'); end
            
            % Generate masks out of anatomical segments
            segNames = fieldnames(segData);
            for a = 1:length(segNames)
                switch segNames{a}
                    case 'CSF';     boldData.Data.Masks.CSF = segData.CSF > params.CSFCutoff;
                    case 'GM';      boldData.Data.Masks.GM = segData.GM > params.GrayMatterCutoff;
                    case 'WM';      boldData.Data.Masks.WM = segData.WM > params.WhiteMatterCutoff;
                    otherwise;      error('An unrecognized segment name was found in the BOLD segment data field.');
                end
            end            
            
        end
        function IdentifySegments(boldData)
		% IDENTIFYSEGMENTS - Attempts to automatically identify preprocessed anatomical segments.
		%   This function attempts to autonomously resolve the identities of the imported anatomical segments created
		%   during the BOLD preprocessing procedure. It does this by loading the standard MNI segment templates (which
		%   must have been present for preprocessing) and calculating the correlation coefficients between those volumes
		%   and the ones that exist in the inputted data object. The final segment identities correspond to whichever
		%   pairwise correlation coefficient is highest.
		%
		%   WARNING: 
		%	This function may not always correctly resolve segment identities. It is imperative that segments are 
		%	manually inspected once the preprocessing procedure concludes.
		%
		%   SYNTAX:
		%   IdentifySegments(boldData)
		%   boldData.IdentifySegments()
		%
		%   INPUTS:
		%   boldData:   BOLDOBJ
		%               A single BOLD data object undergoing preprocessing.
            
            % Initial error checks
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Get the current BOLD anatomical segments & do some error checking
            numSegs = 3;
            segData = boldData.Data.Segments;
            if (isstruct(segData)); error('Segments have already been identified for this data object.'); end
            if (size(segData, 4) ~= numSegs); error('Only three different anatomical segments should have been identified.'); end
            
            % Locate the standardized MNI segment IMG files
            segFilesMNI = searchdir(boldData.Preprocessing.DataPaths.SegmentsFolder, [], 'Ext', '.nii');
            if (length(segFilesMNI) ~= 3); error('Only segment IMGs should be located in the MNI segments folder.'); end
            
            % Initialize storage for correlation coefficients
            imgCorr = struct('CSF', zeros(1, numSegs), 'GM', zeros(1, numSegs), 'WM', zeros(1, numSegs));
            
            % Calculate the correlation coefficients between each MNI segment & each preprocessed anatomical segment
            for a = 1:length(segFilesMNI)
                [~, name, ~] = fileparts(segFilesMNI{a});
                segMNI = load_nii(segFilesMNI{a});
                segMNI = segMNI.img;
                
                for b = 1:size(segData, 4)
                    
                    switch name
                        case 'csf';     imgCorr.CSF(b) = corr3(segMNI, segData(:, :, :, b));
                        case 'grey';    imgCorr.GM(b) = corr3(segMNI, segData(:, :, :, b));
                        case 'white';   imgCorr.WM(b) = corr3(segMNI, segData(:, :, :, b));
                        otherwise; error('Segment file name is not recognized.');
                    end
                end
            end
            
            % Identify the anatomical segments (GM & WM tend to correlate very well with templates)
            [~, idxGM] = max(imgCorr.GM);
            [~, idxWM] = max(imgCorr.WM);
            
            % Do a quick error check to ensure all segments will get stored (even if they are incorrectly identified)
            if (idxGM == idxWM)
                warning('Segment identities were unable to be resolved automatically. They will have to be manually assigned.');
                return;
            end
            
            % If the GM & WM indices are unique, assume the CSF index is unique one
            idxCSF = setdiff(1:numSegs, [idxGM, idxWM]);
            
            % Re-initialize the segment data storage field & sort the segments
            boldData.Data.Segments = struct(...
                'CSF',  segData(:, :, :, idxCSF),...
                'GM',   segData(:, :, :, idxGM),...
                'WM',   segData(:, :, :, idxWM));
            
        end
        function MaskSegments(boldData, maskImage)
		% MASKSEGMENTS - Masks segmented anatomical images.
            
            % Error checking
            boldData.AssertSingleObject;
            boldData.LoadData;
            if (~islogical(maskImage)); error('Only a 3D array of Booleans can be used to mask segment images.'); end
            
            % Mask the anatomical segments
            segData = boldData.Data.Segments;
            if isstruct(segData)
                segNames = fieldnames(segData);
                for a = 1:length(segNames)
                    segData.(segNames{a}) = segData.(segNames{a}) .* maskImage;
                end
            else
                for a = 1:size(segData, 4)
                    segData(:, :, :, a) = segData(:, :, :, a) .* maskImage;
                end
            end
            
            % Store the masked segments
            boldData.Data.Segments = segData;
        end
        function NormalizeSegments(boldData)
		% NORMALIZESEGMENTS - Normalizes anatomical segment data to fractional probability values.
		%
		%   SYNTAX:
		%   NormalizeSegments(boldData)
		%   boldData.NormalizeSegments()
		%
		%   INPUT:
		%   boldData:   BOLDOBJ
		%               A single BOLD data object with a complete set of anatomical segments. Typically this object will
		%               be nearing the end of its preprocessing procedure, and as such it is required that all segments
		%               be properly identified and sorted into individual fields of the segment data structure.
            
            % Initial error checking
            boldData.AssertSingleObject;
            boldData.LoadData;
            
            % Get the segment data & check that it's been identified
            segData = boldData.Data.Segments;
            if (~isstruct(segData)); error('Segments must already be identified to perform normalization.'); end
            
            % Normalize the segments & store in the data object
            segNames = fieldnames(segData);
            for a = 1:length(segNames)
                data = segData.(segNames{a});
                minSeg = min(data(:));
                segData.(segNames{a}) = (data - minSeg) ./ (max(data(:)) - minSeg);
            end
            boldData.Data.Segments = segData;
            
        end
        
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