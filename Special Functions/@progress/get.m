function propValue = get(progressHandle, propName)
%GET Overloads the native "get" method to provide better and more flexible property retrieval from
%   the progress bar object.
%
%   Written by Josh Grooms on 20130329
%       20130407:   Bug fix for error being generated when trying to call "getdisp". Function still
%                   tried to assign an output at the end.
%       20130801:   Completely re-wrote function to work with the recent re-write of WINDOWOBJ.


%% Generate the Output
progProps = ?progress;
progProps = {progProps.PropertyList.Name}';

switch lower(propName)
    case lower(progProps)
        propValue = progressHandle.(progProps(strcmpi(propName, progProps)));
    otherwise
        propValue = get@windowObj(progressHandle, propName);
end
