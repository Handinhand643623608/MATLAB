classdef spectralObj < eegObj
    %SPECTRALOBJ Constructs a spectrum object out of an EEG data object using the user-specified
    %   inputs.
    %     
    %   Written by Josh Grooms on 20130910


    properties %(SetAccess = protected)
        Averaged
        Parameters
        ParentData
    end
    
    
    %% Constructor Method
    methods
        function spectralData = spectralObj(specStruct)
            %SPECTRALOBJ Constructs a spectrum object out of EEG data objects.
            if nargin ~= 0
                % Initialize the spectral data object
                spectralData = initialize(spectralData, specStruct);
                % Generate power spectra
                spectrum(spectralData)
            end
        end
    end
    
    %% Public Methods
    methods        
        % Average the spectral data together
        meanSpectralData = mean(spectralData);
        % Get spectral object generation parameters
        specStruct = parameters(spectralData);
        % Image the spectral data
        varargout = plot(spectralData);
        % Storage of the data object
        store(spectralData)
    end
    
    
    %% Class-Specific Methods
    methods (Access = protected)
        % Initialize the data object
        spectralData = initialize(spectralData, specStruct)
        % Generate power spectra for EEG data
        spectrum(spectralData)
    end
end