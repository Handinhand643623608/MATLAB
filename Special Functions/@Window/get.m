function propVal = get(windowHandle, propName)
%GET Get property values from the window object.
%
%   SYNTAX:
%   propVal = get(windowHandle, propName)
%
%   OUTPUT:
%   propVal:        UNKNOWN
%                   The value associated with the input object property.
%
%   INPUTS:
%   windowHandle:   WINDOWOBJ
%                   The input window object.
%
%   propName:       STRING
%                   The property name whose value is desired.



%% CHANGELOG
%   Written by Josh Grooms on 20130803



%% Get Property Values from the Window Object
if nargin == 1
    disp(windowHandle)
else
    allPropNames = properties(windowHandle);
    destObj = windowHandle.FigureHandle;
    switch lower(propName)
        case allPropNames
            destObj = windowHandle;
        case {'position', 'size'}
            propName = 'OuterPosition';
    end
    propVal = get(destObj, propName);
end