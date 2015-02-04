function p = empiricalcdf(r, n)
% EMPIRICALCDF - Generates two-tailed p-values for data using an empirically derived null distribution.
%
%   SYNTAX:
%       p = empiricalcdf(r, n)
%
%   OUTPUT:
%       p:      [ DOUBLES ]
%               An array of p-values derived using both the real and null data distributions. This array will always be
%               of exactly the same size and dimensionality as R. Each element of this array represents the estimated
%               probability of observing a value at least as extreme as the corresponding R element value, assuming that
%               the null hypothesis is true.
%
%   INPUTS:
%       r:      [ DOUBLES ]
%               An array of values constituting the real data distribution. This array can be of any size.
%
%       n:      [ DOUBLES ]
%               An array of values constituting the null data distribution. This array can be of any size.

%% CHANGELOG
%   Written by Josh Grooms on 20141111
%       20150131:   Removed the option for tail selection. This was never implemented and keeping it as an input argument was
%                   potentially dangerous. This function now only calculates two-tailed p-value distributions.



%% Initialize
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
fp = MexEmpiricalCDF(r, n);

% Reshape the p-values to match the inputted real data
p = nan(length(idsRemoved), 1);
p(~idsRemoved) = fp;
p = reshape(p, szx);