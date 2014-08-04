function outSize = byteSize(x, scale)
%BYTESIZE Determines the size of an input in terms of data storage units.
%   BYTESIZE calculates the amount of memory or hard disk space that is required to represent the raw input input
%   (without factoring in compression). It can output this information in multiple scales ranging from bits to
%   terabytes. 
%
%   SYNTAX:
%   outSize = byteSize(x)
%   outSize = byteSize(x, scale)
%
%   OUTPUT:
%   outSize:   The size of the input data in bytes (by default) or in whatever unit is specified using the scale input.
%
%   INPUT:
%   x:          The input data for which storage size is being determined. This can be anything that MATLAB handles
%               natively in its workspace: numbers, arrays, cells, strings, structures, objects, etc.
%
%   OPTIONAL INPUT:
%   scale:      A string indicating how to scale the output variable size. This parameter accepts typical units of data 
%               storage, from bits through terabytes.
%                   DEFAULT: 'Bytes'
%                   OPTIONS:
%                       'Bits'      or 'b'
%                       'Bytes'     or 'B'
%                       'Kilobytes' or 'kB'
%                       'Megabytes' or 'MB'
%                       'Gigabytes' or 'GB'
%                       'Terabytes' or 'TB'
%   
% Written by Josh Grooms on 20131126


%% Determine Digital Size of Data
% Deal with missing inputs
if nargin == 1
    scale = 'Bytes';
end

% MATLAB can get this about any input natively
xMeta = whos('x');
xBytes = xMeta.bytes;

% Convert the size in bytes to the desired format
switch scale
    case {'Bits', 'b'}
        outSize = xBytes*8;
    case {'Bytes', 'B'}
        outSize = xBytes;
    case {'Kilobytes', 'kB'}
        outSize = xBytes/1024;
    case {'Megabytes', 'MB'}
        outSize = xBytes/(1024^2);
    case {'Gigabytes', 'GB'}
        outSize = xBytes/(1024^3);
    case {'Terabytes', 'TB'}
        outSize = xBytes/(1024^4);
    otherwise
        error(['Output size specification ' scale ' is not recognized.']);
end