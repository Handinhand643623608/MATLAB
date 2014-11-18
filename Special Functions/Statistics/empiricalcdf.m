function p = empiricalcdf(x, n, tail)
% EMPIRICALCDF - 
%
%   SYNTAX:
%       p = empiricalcdf(x, n)
%
%   OUTPUT:
%       p:      [ DOUBLES ]
%               An array of p-values derived using both the real and null data distributions. This array will always be
%               of exactly the same size and dimensionality as x. Each element of this array represents the estimated
%               probability of observing a value at least as extreme as the corresponding x element value, assuming that
%               the null hypothesis is true.
%
%   INPUTS:
%       x:      [ NUMERICS ]
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
assert(isnumeric(x), 'The real data distribution x must be an array of single- or double-precision values.');
assert(isnumeric(n), 'The null data distribution n must be an array of single- or double-precision values.');

% Flatten the data distributions
szx = size(x);
x = x(:);
n = n(:);

% Remove any null values (zeros & NaNs)
idsRemoved = isnan(x) | x == 0;
x(idsRemoved) = [];
n(isnan(n) | n == 0) = [];

% Initialize a flattened p-value storage array
lenX = length(x);
lenN = length(x);

pLow = zeros(lenX, 1);
pHigh = zeros(lenX, 1);

gx = gpuArray(single(x));
gn = gpuArray(single(n));
gpLow = gpuArray(single(pLow));
gpHigh = gpuArray(single(pHigh));



%% Generate Empirical P-Values
% Loop through the real data distribution to determine p-values
pb = Progress('-fast', 'P-Value Generation');
parfor (a = 1:lenX)
    s = sum(x(a) >= n);
    pLow(a) = s / lenN;
    pHigh(a) = 1 - pLow(a);
    pb.Update(a/lenX);
end

% pb = Progress('-fast', 'P-Value Generation');
% for a = 1:lenX
%     s = sum(gx(a) >= gn);
%     gpLow(a) = s / lenN;
%     gpHigh(a) = 1 - gpLow(a);
%     pb.Update(a/lenX);
% end

% Get rid of large data that's not needed anymore
clear n s;

% Calculate two-tailed p-values
% fp = gather(2 * min(gpLow, gpHigh));
fp = 2 * min(pLow, pHigh);

% Reshape the p-values to match the inputted real data
p = nan(length(idsRemoved));
p(~idsRemoved) = fp;
p = reshape(p, szx);