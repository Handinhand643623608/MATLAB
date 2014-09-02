classdef eegObj < humanObj
%EEGOBJ Generates a standardized EEG data object containing various properties. 
%   This object is a subclass of the "humanData" abstract class and contains EEG-specific data, attributes, and methods.

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

    

    %% EEG Object Properties
    properties (SetAccess = protected)
        Channels                % Cell array of strings of EEG channel labels.
        Fs                      % The sampling frequency (in Hz) of the EEG data.
    end
    
    properties (Constant, Hidden)
        LatestVersion = 1;      % The current software version behind BOLD EEG objects.
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
        % Identify frequently anticorrelated EEG electrodes
        varargout = anticorrChannels(eegData, tolerance)
        
        H = Plot(eegData, varargin)
        
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
            
    end
    
    
    
    %% Object Conversion Methods
    methods
        [eegArray, legend] = ToArray(eegData, dataStr)      % Convert specific EEG data to a 2D array format
    end
    
    
    
    %% Signal Processing Methods
    methods
                
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
            
        Filter(eegData, varargin)               % FIR filter EEG data
        Regress(eegData, signal)                % Regress a set of signals from EEG time series
        Resample(eegData, fs)
        
        % Generate power spectra
        powerSpectra(eegData, varargin)
        
        
        % Regress cluster signals
        regressCluster(eegData)
        % Resample the EEG data
        resample(eegData, varargin)
        
        
    end
    
    
    
    
    %% Preprocessing Methods
    methods
        
        PrepImportCNT(eegData)
        
    end
    
    methods (Static) 
        Preprocess(paramStruct)                 % Preprocess raw EEG data & create new data objects
    end
    
    
    %% Static Utility Methods
    methods (Static)
        
        eegObj = loadobj(objFromFile)
        
    end
    
    
    
    %% Class-Specific Methods
    
    methods (Static, Access = protected)
        % Upgrade a loaded data object for compatibility with current software
        eegStruct = upgrade(eegStruct);
    end
end


            
   

            


        
        
        
        
        