function z = transform(r, n)
%TRANSFORM Performs Fisher's normalized r-to-z transformation on correlation data.
%   This function performs the variance stabilizing Fisher's transform on correlation data. If the
%   sample size determining the correlation coefficient is also provided, this function normalizes
%   the transformation by the estimation of the standard error.
%
%   SYNTAX:
%   z = transform(r)
%   z = transform(r, N)
%
%   OUTPUT:
%   z:              The transformed correlation coefficients in an array that is the same size and
%                   dimensionality as the input array.
%
%   INPUTS:
%   r:              An array of Pearson product-moment correlation coefficients.
%
%   OPTIONAL INPUTS:
%   n:              The number of elements in the arrays that produced the correlation coefficients.
%                   For example, if two vectors X & Y are used to generate a correlation
%                   coefficient, then n is the length of each of these vectors. This value is used
%                   to transform the data such that the output is normalized by the estimate of the
%                   standard error.
%
%   Written by Josh Grooms on 20130811


%% Initialize
% Deal with missing inputs
if nargin == 1 || isempty(n)
    n = 4;      % Set n such that values are normalized by '1'
end


%% Transform Correlation Data & Normalize
% Fisher's r-to-z transform
z = atanh(r);

% Normalize by the standard error (or 1 if no normalization is desired)
z = z.*sqrt(n - 3);     % Because standard error of transform is 1/sqrt(N-3)