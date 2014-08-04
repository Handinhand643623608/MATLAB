function output = loadobj(input)
%LOADOBJ - The update procedure for human data objects loaded off of the hard drive.
%
%   SYNTAX:
%   dataObject = humanObj.loadobj(objFromFile)
%
%   OUTPUT:
%   output:     HUMANOBJ or ANYTHING
%               An object of absolutely any type that is defined in MATLAB (including user-defined types) and is stored
%               inside of a .mat file. If the inputted object is a human data object (of type humanObj), then this
%               output argument is also a human data object, but the two may not be identical to one another. For
%               example, if an older data object is loaded, then this function and any implemented overrides in
%               subclasses may modify or perform updates on the object before it is presented to the MATLAB workspace. 
%
%   INPUT:
%   input:      HUMANOBJ or ANYTHING
%               An object of absolutely any type that is defined in MATLAB (including user-defined types) and is stored
%               inside of a .mat file. If this object is a human data object (of type humanObj), then it is run through
%               this function's update procedure as necessary. Otherwise, this input becomes the LOADOBJ output without
%               any modifications. 

%% CHANGELOG
%   Written by Josh Grooms on 20140714



%% Error Checking
% Make no changes to the input if it isn't a human data object
if ~isa(input, 'humanObj')
    output = input;
    return;
end



for a = 1:numel(input)
    
    % Check for a lack of software versioning (applies to long-standing data object code from before 20140714)
    if isempty(input.SoftwareVersion)
        input.SoftwareVersion = 0;
    end
    
    
    switch input.SoftwareVersion
        
        case 0
            % Make some property syntax changes
            output.IsZScored = input.ZScored;
            output.IsFiltered = input.Filtered;
            output.IsGlobalRegressed = input.GSR;
            
            
    end
    
end
        
        
        
    
