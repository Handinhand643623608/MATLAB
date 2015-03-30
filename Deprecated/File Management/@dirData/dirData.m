classdef dirData < hgsetget
%DIRDATA An abstract class for creating file and folder data objects.



%% CHANGELOG
%   Written by Josh Grooms on 20130201
%       20130611:   Added a help & reference section.
    
    

    %% Directory Object Properties
    properties (SetAccess = protected)
        Name                % The name of a file or folder
        DateModified        % The date & time of a folder or file's last modification
        Path                % The full path of a folder or file
        Size                % The size of a file (in bytes)
    end
    
    
    
    %% Protected Methods
    methods (Abstract, Access = protected)
        aggregateInfo(obj)
    end
end