classdef (Abstract) humanObj < hgsetget
%HUMANOBJ An abstract class that sets up BOLD, EEG, and relation data objects.
%   This class exists only to provide a backbone for subclasses containing human neuroimaging data. It provides
%   universal properties and methods that should be included in all data objects.

%% CHANGELOG
%   Written by Josh Grooms
%       20130707:   Removed property "ScanDate", which should now be included under the "Acquisition" property.
%       20130708:   Cleaned up commenting that is now outdated
%       20130906:   Renamed "GlobalRegressed" property to "GSR" for consistency.
%       20140711:   Implemented set-access restrictions for several important common properties so that accidentally 
%                   overwriting them is more difficult. Moved the implementation of some common subclass methods here to
%                   make code maintenance a little easier (STORE, TOSTRUCT).
%       20140714:   Implemented methods to upgrade older saved data objects after the class definitions here and in
%                   any subclasses have changed (even if the changes are dramatic). Changed the FILTERED, GSR, and
%                   ZSCORED property names to reflect newer coding standards for clarity (now prepended with IS).
    
%% TODOS
%   - Fix problems with implementation of MATFILE
%       > Expand indexing capabilities inside of .mat files
%       > Implement dynamic data loading to allow seamless data modification without overwriting the original


    %% Properties Common to All Human Data
    
    properties (Dependent)
        
        
        
    end
    
    
    properties (AbortSet, SetAccess = protected)
    
        % General
        Data                % The data being stored within the object
        Scan                % Integer indicating the scan number of a subject's data set
        ScanState           % String indicating whether data is from resting or task states
        Subject             % Integer indicating the subject number of the data set
        
        % Acquisition & processing 
        Acquisition         % All parameters related to the acquisition of raw data
        Bandwidth           % The high and low-pass cutoffs for the filtered data (in Hz)
        FilterShift         % Double indicating the the phase shift imposed by FIR filtering (in seconds)
        IsFiltered          % Boolean indicating whether the data has been filtered
        IsGlobalRegressed   % Boolean indicating whether the global signal has been regressed
        IsZScored           % Boolean indicating whether the data is scaled to zero mean & unit variance
        Preprocessing       % All parameters related to the preprocessing of raw data
        
        % Storage
        SoftwareVersion     % The software version behind the data object construction
        StorageDate         % Date string of data storage date
        StoragePath         % Path string indicating where the data is stored
        
    end
    
    
    properties (Abstract, Constant, Hidden)
        LatestVersion;
    end
    
    
    
    %% Universal Methods
    
    methods
        % Store a data object on the hard drive
        Store(dataObject, varargin);
        % Convert a data object into a data structure
        dataStruct = ToStruct(dataObject);
        % Z-Score the primary data inside the data object
        ZScore(dataObject)
        % Load MATFILE data from the hard drive
        function LoadData(dataObject)
            %LOADDATA - Loads MATFILE data archives referenced by the data object.
            if isa(dataObject.Data, 'matlab.io.MatFile')
                dataObject.Data = load(dataObject.Data.Properties.Source);
            end
        end
        
    end
    
    methods (Static, Access = protected)
        % Get the current software version
        function version = currentSoftwareVersion 
            humanMeta = ?humanObj;
            propNames = {humanMeta.PropertyList.Name}';
            version = humanMeta.PropertyList(strcmpi(propNames, 'LatestVersion')).DefaultValue;
        end
        % Upgrade a loaded data object for compatibility with current software
        dataStruct = upgrade(dataStruct)
    end
    
    
    
    %% Abstract Methods
    
    % Data object generation & updating
    methods (Abstract)
        % Pull important data out of a data object
        [dataArray, legend] = ToArray(dataObject, dataStr);
    end
    
    % Image & signal processing
    methods
        % Linear or quadratic temporal detrending
        Detrend(dataObject, varargin)
        % Temporal filtering
        Filter(dataObject, varargin)
        % Preprocess human data objects from raw data files
        Preprocess(dataObject, paramStruct)        
    end
    
    methods (Abstract, Static)
        % Manually create a human data object
%         dataObject = create(varargin);
        % Control the loading of older data objects
        output = loadobj(input)
    end
    
    
    
end