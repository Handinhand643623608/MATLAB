function set(windowHandle, varargin)
%SET Sets the window object properties.
%
%   SYNTAX:
%   set(windowHandle, 'PropertyName', PropertyValue...)
%
%   INPUT:
%   windowHandle:       The handle to the window object for which properties are being changed.
%
%   'PropertyName':     A string indicating the property name that is to be changed. Any MATLAB
%                       native property name for figure window objects is acceptable here.
%
%   PropertyValue:      A value for the property name that is being changed. Any MATLAB native
%                       property value for figure window objects is acceptable here.
%
%   Written by Josh Grooms on 20130801
%       20130803:   Updated calls to colorbar property so that it now only turns it on if it didn't
%                   already exist.
%       20130809:   Bug fix for case sensitivity in property names. Bug fix for potential recursive 
%                   calling of SET.


%% Set the Window Object Properties
allPropNames = properties(windowHandle);
for a = 1:2:length(varargin)
    destObj = windowHandle.FigureHandle;
    propName = varargin{a};
    propVal = varargin{a+1};
    switch lower(propName)
        case lower(allPropNames)    % Native object properties
            windowHandle.(propName) = propVal;
            return            
        case 'colorbar'             % Colorbar properties
            destObj = windowHandle.Colorbar;
            if isempty(destObj) && istrue(propVal)
                destObj = colorbar;
                propName = 'Visible'; propVal = 'on';
            end
        case {'position', 'size'}   % Position & size both become outer figure position
            propName = 'OuterPosition';
            newPos = get(destObj, 'OuterPosition');
            if ischar(propVal)
                newPos = windowHandle.translate(propVal, newPos);
            elseif length(propVal) == 4
                newPos = propVal;
            elseif strcmpi(propName, 'position')
                newPos(1:2) = propVal;
            elseif strcmpi(propName, 'size')
                newPos(3:4) = propVal;
            end
            propVal = newPos;
        case {'resizable', 'resize'}
            propName = 'Resize';
    end
    set(destObj, propName, propVal);
end