function set(progData, varargin)
%SET Overload the native "set" method to provide property name compatibility
%
%   Written by Josh Grooms on 20130329
%       20130614:   Updated "BarTitle" variable compatibility to include "Name"
%       20130625:   Removed "Name" because it conflicts with the existing windowObj property.
%       20130801:   Completely rewrote function to work with recent re-write of WINDOWOBJ.


%% Set Object Properties
progProps = properties(progData);
for a = 1:2:length(varargin)
    switch lower(varargin{a})
        case lower(progProps)
            progData.(varargin{a}) = varargin{a+1};
        otherwise
            set@windowObj(progData, varargin{a}, varargin{a+1});
    end
end