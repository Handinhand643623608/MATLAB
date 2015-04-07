function y = scaleToRange(x, newRange, dataRange)
%SCALETORANGE - Scales array values to within a new specified range.
%
%   SYNTAX:
%   y = scaleToRange(x)
%   y = scaleToRange(x, newRange)
%   y = scaleToRange(x, newRange, dataRange)
%
%   OUTPUT:
%   y:              [DOUBLE]
%                   An array the same size as the inputted data but scaled to the new range boundaries. If the input
%                   data range is manually specified, values in this output may not span the entire new range or may
%                   exceed it. 
%
%   INPUT:
%   x:              [DOUBLE]
%                   The data set to be scaled to the new range.
%
%   OPTIONAL INPUTS:
%   newRange:       [DOUBLE, DOUBLE]
%                   The new range that the inputted data will be scaled to. The minimum and maximum data range values
%                   will be mapped onto the minimum and maximum values of this input argument, respectively. Other data
%                   values will be scaled to fit inside of this range, but will retain differences from one another that
%                   is proportional to the original data distribution.
%                   DEFAULT: [0, 1]
%
%   dataRange:      [DOUBLE, DOUBLE]
%                   Specifies the data values that will be mapped to the minimum and maximum of the new range. By
%                   default, this is the global minimum and maximum values of the inputted data so that the data span
%                   the enire new range of numbers. However, manually providing these bounds allows for some data to
%                   exceed the new range or only span a subset of it. This is useful when scaling multiple individual
%                   data sets to a universal global range (i.e. when individual data sets might not span the known
%                   global range themselves). The format of this argument is [MIN, MAX].
%                   DEFAULT: [min(x(:)), max(x(:))]

%% CHANGELOG
%   Written by Josh Grooms on 20140428
%       20140709:   Added documentation for this function.

DEPRECATED


%% Scale Data to the New Range
% Deal with missing inputs (default to a new range [0, 1] & data range [min(x) max(x)])
if nargin < 3; dataRange = [min(x(:)) max(x(:))]; end;
if nargin < 2; newRange = [0 1]; end

diffNewRange = diff(newRange);

% Get the minimum and maximum values in the dataset X
diffDataRange = diff(dataRange);

% Convert the input array
y = (diffNewRange * (x - dataRange(1)) / diffDataRange) + newRange(1);

