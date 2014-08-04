function assignOutputs(callerNargout, varargin)
%ASSIGNOUTPUTS Assigns desired output variables of a caller function to the
%   caller's workspace as the variable VARARGOUT. Inputs include the caller
%   function's NARGOUT and then an all-inclusive list of possible output
%   variables in the order that they are to appear in VARARGOUT. Thus,
%   NARGOUT determines how many output variables from the sorted list are
%   returned from the function.
% 
%   Syntaxt:
%   assignOutputs(nargout, outVar1, outVar2,..., outVarN)
% 
%   PROPTERTY NAMES:
%   callerNargout:  The NARGOUT MATLAB function in the caller. Gives the
%                   number of output arguments being called by scripts
%                   above the caller function.
% 
%   outVar:         The variable names in the caller function. Input these
%                   in the same order as they should appear in the outputs
%                   above the caller function.
% 
%   Written by Josh Grooms on 20130109
%       20130112:   Added a help section.
%       20130124:   Editted to prevent errors when callerNargout = 0

if callerNargout ~= 0
    for i = 1:callerNargout
        varargout{i} = varargin{i};
    end
else
    return
end

assignin('caller', 'varargout', varargout);