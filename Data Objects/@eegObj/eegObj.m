classdef eegObj < humanObj
%EEGOBJ Generates a standardized EEG data object containing various properties. 
%   This object is a subclass of the "humanData" abstract class and contains EEG-specific data, attributes, and methods.

%% DEPENDENCIES
%
%   File Management Package
%
%   @BrainPlot
%   @humanObj
%   @Progress
%   @spectralObj
%   @Window
%       
%   assignInputs
%   fileNames
%   sigFig
%   where

%% CHANGELOG
%   Written by Josh Grooms on 20130202
%       20130318:   Moved several construction elements to "assignProperties" function. Added new property for scan 
%                   state.
%       20130611:   Removed the "disp" function. Expanded the help & reference section.
%       20130625:   Wrote the "standardize" function to make EEG data arrays consistent across subjects and scans.
%       20130814:   Implemented an FIR filter function for EEG data. Added new properties to prepare for implementation
%                   of preprocessing methods. Reorganized methods into specific sections. Removed input options no
%                   longer being used. Implemented cluster signal regression.
%       20140617:   Implemented a method for linearly regressing one or more signals from EEG data. Updated some
%                   documentation.
%       20140620:   Implemented a shortcut method for extracting channel data from data objects.
%       20140711:   Moved several object methods and properties to the abstract HUMANOBJ class because of duplicate
%                   functionality with BOLD data objects. Moved the TOARRAY function from this class file to its own
%                   separate file so that functionality and documentation could be expanded.
%       20140714:   Implemented methods to upgrade older saved data objects after the class definitions here and in
%                   HUMANOBJ have changed (even if the changes are dramatic). Implemented standardized checks and error
%                   messages for single object inputs and for checking input types. Updated the code in several class
%                   methods.
%       20140829:   Cleaned up the code here in the class definition file and improved the documentation. Converted the
%                   Preprocess function to a static method. Rewrote the constructor method so that it's now capable of
%                   creating full EEG data objects from user inputs.
%       20140901:   Implemented a detrending method. Moved the code for z-scoring to this class definition file.
%       20140902:   Implemented some status properties that take their values from standardized preprocessing parameter
%                   log entries (mostly in the human object superclass). Implemented a data cache to store data loaded
%                   from MatFiles. Implemented a ToMatrix method that behaves similarly to the equivalent BOLD data 
%                   object method. Moved the Regress method code here to the class definition file. Updated the version 
%                   number of this software to 2 to reflect these changes.
%       20140925:   Implemented a subscript reference function for this class so that EEG channel data can be extracted
%                   quickly and easily. Channels can now be inputted as if they were matrix indices of the object.

%% TODOS
%   - Rewrite the power spectrum generation methods.
%   - Test all rewritten functionality.



    %% EEG Object Properties
    properties (SetAccess = protected)
        Channels                % Cell array of strings of EEG channel labels.
        Fs                      % The sampling frequency (in Hz) of the EEG data.
    end
    
    properties (Access = protected)
        DataCache
    end
    
    properties (Constant, Hidden)
        LatestVersion = 2;      % The current software version behind EEG data objects.
    end
    
    
    
    %% Constructor Method
    methods
        function eegData = eegObj(varargin)
            %EEGOBJ - Constructs an EEG data object for storing and analyzing electrophysiological data.
            
            % Fill in object properties depending on input types
            if (nargin == 0); return
            elseif (nargin == 1) && (isstruct(varargin{1}))
                eegData = eegObj(struct2var(varargin{1}));
            else
                inStruct = struct(...
                    'Acquisition', [],...
                    'Bandwidth', [],...
                    'Channels', [],...
                    'Data', [],...
                    'FilterShift', [],...
                    'Fs', [],...
                    'IsFiltered', [],...
                    'IsGlobalRegressed', [],...
                    'IsZScored', [],...
                    'Preprocessing', [],...
                    'Scan', [],...
                    'ScanState', [],...
                    'Subject', [],...
                    'UseMatFileStorage', false);
                assignInputs(inStruct, varargin, 'structOnly');
                
                propNames = fieldnames(inStruct);
                for a = 1:length(propNames)
                    if ~isempty(inStruct.(propNames{a}))
                        eegData.(propNames{a}) = inStruct.(propNames{a});
                    end
                end
            end
        end
    end
    
    
    
    %% General Utilities
    methods        
        varargout   = Plot(eegData, varargin)
        paramStruct = Parameters(eegData)
        
        function GenerateClusterSignals(eegData, maxNumClusters)
            %GENERATECLUSTERSIGNALS - Generates average signals by clustering EEG time series.
            %   This function produces and stores a set of average EEG signals using hierarchical clustering. Signals
            %   are grouped according to how well their time series correlate with one another. A single user input
            %   provides optional control over the number of individual clusters that are allowed to form.
            %
            %   Identifying average signals may be useful when trying to reduce the dimensionality of an EEG data set or
            %   when trying to identify common mode components. Either case relies on the fact that electrophysiological
            %   recordings often contain redundant information, especially when acquired from surface electrodes.
            %   Identifying such components can be critical to certain analyses and removing them can reduce
            %   computational demands.
            %
            %   SYNTAX:
            %   GenerateClusterSignals(eegData)
            %
            %   INPUT:
            %   eegData:            EEGOBJ
            %                       A single EEG data object.
            %
            %   OPTIONAL INPUT:
            %   maxNumClusters:     INTEGER
            %                       The maximum number of clusters that will be allowed to form. 
            %                       DEFAULT: 5
            
            % Error check
            if nargin == 1; maxNumClusters = 5; end
            eegData.AssertSingleObject;
            
            % Pull the EEG data from the object & remove dead channels
            ephysData = eegData.ToArray;
            idsNaN = isnan(ephysData(:, 1));
            ephysData(idsNaN, :) = [];

            % Set up & run the hierarchical clustering procedure
            linkParams = linkage(ephysData, 'average', 'correlation');
            idsCluster = nan(length(idsNaN), 1);
            idsCluster(~idsNaN) = cluster(linkParams, 'maxclust', maxNumClusters);
            
            % Average together EEG signals that were grouped into the same cluster
            clusterSigs = zeros(max(idsCluster), size(ephysData, 2));
            for a = 1:max(idsCluster)
                clusterSigs(a, :) = nanmean(ephysData(idsCluster == a, :), 1);
            end
            
            % Store the average signals in the data object
            eegData.Data.Global = clusterSigs;
        end
        function Standardize(eegData)
            %STANDARDIZE Makes the size of all EEG data matrices consistent.
            %   Certain subjects in the collected data set have a non-standard number of electrodes. This function adds
            %   rows of NaNs to the EEG data matrix where electrodes are missing in order to standardize the matrix
            %   layout across all data.
            %
            %   SYNTAX:
            %   Standardize(eegData)
            %
            %   INPUTS:
            %   eegData:    EEGOBJ
            %               A single, unstandardized EEG data object.
            
            % Prepare the data
            eegData.AssertSingleObject;
            eegData.LoadData;
            ephysData = eegData.ToArray;
            
            % Locate a list of all possible EEG channels
            classPath = where('BrainPlot.m');
            load([classPath '/eegInfo.mat'], 'channels');
            
            % Standardize the EEG data array
            stdData = zeros(length(channels), size(ephysData, 2));
            idsMember = ismember(channels, eegData.Channels);
            stdData(~idsMember, :) = NaN;
            stdData(idsMember, :) = ephysData;
            
            % Store the array in the data object
            eegData.Data.EEG = stdData;
            eegData.Channels = channels;
        end
        
        function data = subsref(eegData, s)
            % SUBSREF - Subscript reference shortcut to extract data from the EEG data object.
            
            if isequal(s(1).type, '()'); data = eegData.ToArray(s.subs);
            else data = builtin('subsref', eegData, s);
            end
        end
    end
    
    
    
    %% Object Conversion Methods
    methods
        [eegArray, legend] = ToArray(eegData, dataStr)      % Convert specific EEG data to a 2D array format
        
        function [eegMatrix, idsNaN] = ToMatrix(eegData, removeNaNs)
            %TOMATRIX - Extracts EEG channel data and automatically removes dead channels, if called for.
            %
            %   SYNTAX:
            %   eegMatrix = ToMatrix(eegData)
            %   eegMatrix = ToMatrix(eegData, removeNaNs);
            %   [eegMatrix, idsNaN] = ToMatrix(...);
            %
            %   OUTPUT:
            %   eegMatrix:      2D ARRAY
            %                   The channel data stored inside the EEG data object with or without dead channels
            %                   removed, depending on the REMOVENANS argument value. 
            %
            %   OPTIONAL OUTPUT:
            %   idsNaN:         [BOOLEANS]
            %                   The indices of NaN voxels. This parameter is a vector of Booleans of length equal to the
            %                   number of channels that the full EEG data array contains (before NaN time series
            %                   removal). Elements of this vector are true when corresponding elements in the first
            %                   column of the EEG matrix are NaN. If this output is requested without providing a value
            %                   for the REMOVENANS argument, then that argument defaults to TRUE and NaNs are
            %                   automatically removed from the data.
            %
            %   INPUT:
            %   eegData:        EEGOBJ
            %                   A single EEG data object. Arrays of EEG objects are not supported.
            %
            %   OPTIONAL INPUT:
            %   removeNaNs:     BOOLEAN
            %                   Remove any channels with time series composed entirely of NaNs. These frequently
            %                   represent dead channels in the data array. If this parameter is not supplied as an input
            %                   argument, then it defaults to true only if the IDSNAN output is requested by the
            %                   caller. Otherwise, if only one output is requested (EEGMATRIX), this defaults to
            %                   FALSE and NaNs are not removed from the data matrix. Manually specifying this argument
            %                   overrides these default behaviors. 
            %                   DEFAULT:
            %                       true    - If two outputs are requested (i.e. including idsNaN)
            %                       false   - If only one output is requested
            
            % Deal with missing inputs
            if nargin == 1
                if (nargout == 2); removeNaNs = true;
                else removeNaNs = false;
                end
            end
            
            % Error check
            eegData.AssertSingleObject;
            
            % Pull the EEG data matrix from the object
            eegMatrix = eegData.ToArray;
            
            % Identify & remove dead channel entries if called for
            idsNaN = isnan(eegMatrix(:, 1));
            if (removeNaNs); eegMatrix(idsNaN, :) = []; end
        end
    end
    
    
    
    %% Signal Processing Methods
    methods
        Filter(eegData, varargin)               % FIR filter EEG data
        
        function Detrend(eegData, order)
            %DETREND - Detrend EEG data time series using a polynomial of the specified order.
            %
            %   SYNTAX:
            %   Detrend(eegData, order)
            %
            %   INPUTS:
            %   eegData:    EEGOBJ
            %               An EEG data object containing electrode time series to be detrended.
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
            eegData.AssertSingleObject;
            eegData.LoadData;
            
            % Get the EEG data array
            ephysData = eegData.ToArray;
            
            % Detrend the EEG time series
            for a = 1:size(ephysData, 1)
                if ~isnan(ephysData(a, 1))
                    polyCoeffs = polyfit(1:size(ephysData, 2), ephysData(a, :), order);
                    ephysData(a, :) = ephysData(a, :) - polyval(polyCoeffs, 1:size(ephysData, 2));
                end
            end
            
            % Store the detrended data set in the data object
            eegData.Data.EEG = ephysData;
            
            % Change data object preprocessing parameters
            Detrend@humanObj(eegData, order);
            eegData.IsZScored = false;
            
        end
        function Resample(eegData, fs)
            %RESAMPLE - Resamples EEG temporal data to a new sampling frequency.
            %
            %   SYNTAX:
            %   Resample(eegData, fs)
            %
            %   INPUT:
            %   eegData:    EEGOBJ        
            %               A single EEG data object.
            %
            %   fs:         DOUBLE
            %               The new sampling frequency (in Hertz) for the EEG time series.
            
            % Error check
            eegData.AssertSingleObject;
            eegData.LoadData;
            
            % Get the EEG data matrix
            ephysData = eegData.ToMatrix;
            szEEG = size(ephysData);
            
            % Calculate the number of time points the resampled series will have
            numPoints = floor(szEEG(2) * (fs / eegData.Fs));
            rsEphysData = nan(szEEG(1), numPoints);
            
            % Resample the EEG data
            for a = 1:szEEG(1);
                if ~isnan(ephysData(a, 1))
                    rsEphysData(a, :) = resample(ephysData, numPoints, szEEG(2));
                end
            end
            
            % Resample any existing BCG data
            if ~isempty(eegData.Data.BCG); 
                eegData.Data.BCG = resample(eegData.Data.BCG, numPoints, szEEG(2));
            end
            
            % Resample any existing global data
            if ~isempty(eegData.Data.Global)
                szGlobal = size(eegData.Data.Global);
                rsGlobal = zeros(szGlobal(1), numPoints);
                for a = 1:szGlobal(1)
                    rsGlobal(a, :) = resample(eegData.Data.Global(c, :), numPoints, szGlobal(2));
                end
                eegData.Data.Global = rsGlobal;
            end
            
            % Store the results in the data object
            eegData.Data.EEG = rsEphysData;
            Resample@humanObj(eegData, eegData.Fs, fs);
            eegData.Fs = fs;
            eegData.IsZScored = false;
        end
        function Regress(eegData, signal)
            %REGRESS - Linearly regress signals from EEG time series.
            %   This function performs a simple linear regression between a set of signals and all EEG channel time
            %   series, finding the best fit (in the least-squares sense) for the signals to the data. It then scales
            %   the signals according to the fitting parameters and subtracts them from the EEG time series. Thus, the
            %   EEG data that exists after this method is called are the residual time series left over from the
            %   regression.
            %
            %   Linear regression is currently a popular method of removing artifacts from the EEG data and accounting
            %   for signals that are not likely to be neuronal in origin. Partial correlation, for instance, uses this
            %   approach to control for a set of variables while estimating how two other data sets covary.
            %
            %   However, assuming simple linear relationships between complicated data (i.e. physiological data) is
            %   rarely exactly correct. Care must be taken to ensure that the data fitting is approximately valid. If it
            %   is not, more complex methods of regression may be called for.
            %
            %   SYNTAX:
            %   Regress(eegData, signal)
            %
            %   INPUTS:
            %   eegData:    EEGOBJ
            %               A single EEG data object.
            %
            %   signal:     1D ARRAY or 2D ARRAY
            %               A vector or array of signals to be regressed from the EEG channel data. This argument must
            %               be provided in the format [SIGNALS x TIME], where time points span the columns of the
            %               matrix. The number of signals (i.e. number of rows) here can be any number, but the number
            %               of time points must equal the number of time points in the EEG data.
            %
            %               It is not necessary to provide a signal of all ones in this array (i.e. to account for
            %               constant terms), although you may provide one if you wish. This function automatically adds
            %               in a constant signal if one is not present.
            
            % Error check
            eegData.AssertSingleObject;
            eegData.LoadData;
            
            % Perform the regression & store the residuals
            eegData.Data.EEG = humanObj.RegressTimeSeries(eegData.Data.EEG, signal);
            eegData.IsZScored = false;
        end
        function ZScore(eegData)
            %ZSCORE - Scales EEG channel time courses to zero mean and unit variance.
            %
            %   SYNTAX:
            %   ZScore(eegData)
            %
            %   INPUT:
            %   eegData:    EEGOBJ
            %               A single EEG data object.
            
            % Error check
            eegData.AssertSingleObject;
            eegData.LoadData;
            
            % Z-Score & store the data
            ephysData = eegData.ToArray;
            ephysData = zscore(ephysData, 0, 2);
            eegData.Data.EEG = ephysData;
            eegData.IsZScored = true;
        end
    end
    
    
    
    
    %% Preprocessing Methods
    methods
        PrepCondition(eegData)
        PrepInitialize(eegData)
        PrepImportCNT(eegData)
    end
    
    methods (Static) 
        Preprocess(paramStruct)                 % Preprocess raw EEG data & create new data objects
    end
    
    
    
    %% Static Utility Functions
    methods (Static)
        eegObj = loadobj(objFromFile)    
    end
    
    methods (Static, Access = protected)
        % Upgrade a loaded data object for compatibility with current software
        eegStruct = upgrade(eegStruct);
    end
    
    
    
end


            
   

            


        
        
        
        
        