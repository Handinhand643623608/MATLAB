function z = regress(x, y, dim)
%REGRESS Linearly regress one data set from another.
%   This function performs a simple linear regression between two sets of signals, finding the best fit (in the
%   least-squares sense) between them. It then scales the second set of signals (Y) according to the fitting parameters
%   and subtracts them from the first data set (X). Thus, the output data (Z) are the residual signals left over from
%   the regression. 
%
%   The regression is performed using the following formula:
%
%       Z = X - Y*(Y\X)
%
%   Inputted data sets must be either vectors or two-dimensional matrices and whose sizes are equal over the dimension
%   in which the regression is performed. 
%
%   SYNTAX:
%   z = Signal.regress(x, y)
%
%   OUTPUT:
%   z:          VECTOR or 2D ARRAY
%               A vector or matrix that is the same size as X and represents the data from that input after the data
%               from Y has been linearly regressed from it. Thus, Z represents the the residuals of the linear
%               regression of Y to X. 
%
%   INPUTS:
%   x:          VECTOR or 2D ARRAY
%               A vector or matrix of signals that will have the data in input Y linearly regressed from it. This input
%               can be at most two-dimensional; higher dimensional arrays are not supported. 
%
%   y:          VECTOR or 2D ARRAY
%               A vector or matrix of signals that will be linearly regressed from the data in input X. This input can
%               be at most two-dimensional; higher dimensional arrays are not supported. This input must be in the same
%               format as X. In other words, the regression dimension must be the same for both arrays. 
%
%   OPTIONAL INPUT:
%   dim:        INTEGER
%               The dimension over which regression is to be performed. This will typically be the time dimension of the
%               input signals.
%               DEFAULT: 2

%% CHANGELOG
%   Written by Josh Grooms on 20140618



%% Error Checking
% Determine the dimension over which to perform the regression
if nargin == 2
    dim = 2;
end

% Check that the inputs are vectors or matrices
if ~ismatrix(x) || ~ismatrix(y)
    error('Signal inputs for regression must be two dimensional matrices or vectors');
end

% Check that the inputs have compatible dimensionalities
szX = size(x);
szY = size(y);
if ~any(szX == szY)
    error('Signal inputs for regression must match over one dimension');
end

% Ensure that data are in the correct format
if dim == 2
    x = x'; 
    y = y';
end



%% Perform the Regression
% Simple linear regression
z = x - y*(y\x);

% Restore original data dimensions
if dim == 2
    z = z';
end