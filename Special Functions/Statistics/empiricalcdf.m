function p = empiricalcdf(r, n, tail)
% EMPIRICALCDF - Generates p-values for data using an empirically derived null distribution.
%
%   SYNTAX:
%       p = empiricalcdf(r, n)
%
%   OUTPUT:
%       p:      [ DOUBLES ]
%               An array of p-values derived using both the real and null data distributions. This array will always be
%               of exactly the same size and dimensionality as x. Each element of this array represents the estimated
%               probability of observing a value at least as extreme as the corresponding x element value, assuming that
%               the null hypothesis is true.
%
%   INPUTS:
%       r:      [ NUMERICS ]
%               An array of values constituting the real data distribution. 
%
%       n:      [ NUMERICS ]
%               An array of values constituting the null data distribution.
%
%   OPTIONAL INPUT:
%       tail:   STRING
%
%               DEFAULT: 'both'
%               OPTIONS:
%                   'both'
%                   'lower'
%                   'upper'

%% CHANGELOG
%   Written by Josh Grooms on 20141111



%% Initialize
% Fill in missing input arguments
if (nargin == 2); tail = 'both'; end

% Error check
assert(isnumeric(r), 'The real data distribution x must be an array of single- or double-precision values.');
assert(isnumeric(n), 'The null data distribution n must be an array of single- or double-precision values.');

% Flatten the data distributions
szx = size(r);
r = r(:);
n = n(:);

% Remove any null values (zeros & NaNs)
idsRemoved = isnan(r) | r == 0;
r(idsRemoved) = [];
n(isnan(n) | n == 0) = [];

% Call the MEX function to do the heavy processing
fprintf(1, '\n\nStarting MEX Processing...\n\n');
fp = MexEmpiricalCDF(r, n);
fprintf(1, '\n\nProcessing Complete!\n\n');

% Reshape the p-values to match the inputted real data
p = nan(length(idsRemoved), 1);
p(~idsRemoved) = fp;
p = reshape(p, szx);