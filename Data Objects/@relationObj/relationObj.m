classdef relationObj < humanObj
    %RELATIONOBJ Generates a standardized object contianing data regarding the relationship between
    %   EEG and BOLD signals. This object is a subclass of the "humanObj" abstract class.
    %
    %   WARNING: This code is still under core development and is not yet suitable for general use.
    %
    %   Syntax:
    %
    %   
    %   OUTPUTS:
    %   relationData:
    %   
    %   INPUTS: (values in parentheses are optional)
    %   'Bandwidth':
    %
    %   'DataPath':
    %
    %   'Parameters':
    %
    %   'Relation':
    %
    %   ('Scan'):
    %
    %   ('Subject'):
    %
    %   ('ScanState'):
    %
    %   Written by Josh Grooms
    %       20130428:   Added ability to import structures of data. Setup outline for future
    %                   wavelet transform coherence analyses. Wrote function to store objects.
    %       20130611:   Added "Modalities" property to easily determine which data are being
    %                   compared. Added a help & reference section.
    %       20130614:   Added "Averaged" property to easily determine if data have been averaged
    %                   together. Removed all coherence code in preparation for making "relationObj"
    %                   an abstract class to govern specific analyses.
    %       20130906:   Removed "ParentEEG" and "ParentBOLD" properties and added "ParentData" to
    %                   allow for flexible modality selection.
    
    
    properties %(SetAccess = protected)
        Averaged
        ParentData
        Modalities
        Relation
        Parameters
    end
    
    
%     %% Constructor Method
%     methods
%         function relationData = relationObj(varargin)
%             %RELATIONOBJ Constructs the relation object using the various input parameters.
%             if nargin ~= 0
%                 if isstruct(varargin{1})
%                     % Import an older-style data structure
%                     relationData = convertDataStruct(relationData, varargin{:});
%                 else
%                     % Assign properties based on inputs
%                     relationData = assignProperties(relationData, varargin{:});
%                     % Run the relationship analysis
%                     switch lower(relationData(1, 1).Relation)
%                         case 'correlation'
%                             relationData = correlation(relationData);
%                         case 'coherence'
%                             relationData = coherence(relationData);
%                         case 'mutualinformation'
%                             relationData = mutualInformation(relationData);
%                         case 'waveletcoherence'
%                             relationData = waveletCoherence(relationData);
%                         otherwise
%                             error(['Analysis method "' relationData.Relation '" does not exist.']);
%                     end
%                 end
%             end
%         end
%     end
    
            
%     
%     %% Public Methods
%     methods
%         % Analysis methods
%         relationData = mean(relationData);        
%         plot(relationData, varargin)        
%     end
%     
%     
%     %% Protected Methods
%     methods (Access = protected)
%         % Assign object properties based on manual inputs
%         initialize(relationData, varargin);
%         % Convert from an old-style data structure
%         relationData = convertDataStruct(relationData, varargin);
%     end
end