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

%% DEPENDENCIES
%   REQUIRED ADDITIONAL CODE
%       @spectralObj
%       File Management Package
%       
%       assignInputs
%       fileNames
%       sigFig

    

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
            %EEGOBJ Constructs the EEG data object using the various input parameters or an input data structure.
            
            % Fill in object properties depending on input types
            if nargin ~= 0
                eegData = assignProperties(eegData, varargin{:});
            end
            
        end
    end
    
    
    
    %% General Utilities
    methods
        % Identify frequently anticorrelated EEG electrodes
        varargout = anticorrChannels(eegData, tolerance)
        % Standardize the EEG data matrices
        standardize(eegData)
        
        H = Plot(eegData, varargin)
    end
    
    
    
    %% Object Conversion Methods
    methods
        % Convert specific EEG data to a 2D array format
        [eegArray, legend] = ToArray(eegData, dataStr)
    end
    
    
    
    %% Signal Processing Methods
    methods
        
        
        
        % FIR filter EEG data
        Filter(eegData, varargin)
        % Generate power spectra
        powerSpectra(eegData, varargin)
        % Regress a set of signals from EEG time series
        Regress(eegData, signal)
        % Regress cluster signals
        regressCluster(eegData)
        % Resample the EEG data
        resample(eegData, varargin)
        % Scale data to zero mean & unit variance
        zscore(eegData)
    end
    
    
    
    
    %% Preprocessing Methods
    methods
        Preprocess(eegData)
        
        PrepImportCNT(eegData)
        
        
    end
    
    
    
    %% Static Utility Methods
    methods (Static)
        % 
        eegObj = loadobj(objFromFile)
        
    end
    
    
    
    %% Class-Specific Methods
    
    methods (Access = protected)
        % Assign properties based on manual inputs
        eegData = assignProperties(eegData, varargin);
        % Check for z-scored data
        checkZScore(eegData)
        % Allow only single EEG object input arguments
        function CheckSingleObject(eegData)
            if numel(eegData) > 1
                error('Only one EEG object may be inputted at a time.');
            end
        end
        % Allow only EEG data object types as an input
        function CheckCorrectObject(eegData)
            if ~isa(eegData, 'eegObj')
                error('Inputted data must be of type "eegObj".');
            end
        end
    end
    
    
    
    methods (Static, Access = protected)
        % Upgrade a loaded data object for compatibility with current software
        eegStruct = upgrade(eegStruct);
    end
end


            
   

            


        
        
        
        
        