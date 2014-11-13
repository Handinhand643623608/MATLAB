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
lenN = length(n);
fp = zeros(lenX, 2);



%% Generate Empirical P-Values
% Calculate how much of the work can be vectorized
numReps = floor(Memory.MaxNumDoubles / (2 * lenN));
nrep = repmat(n', numReps, 1);

% Loop through the real data distribution in chunks as large as possible
for a = 1:numReps:lenX
    % Identify where values are greater than null values (lower tail)
    xrep = repmat(x(a:a + numReps - 1), 1, lenN);
    xrep = xrep >= nrep;
    
    % Calculate one-tailed p-values
    fp(a:a + numReps - 1, 1) = sum(xrep, 2) ./ lenN;
    fp(a:a + numReps - 1, 2) = sum(~xrep, 2) ./ lenN;
end

% Get rid of large data that's not needed anymore
clear n nrep xrep;

% Calculate two-tailed p-values
fp = 2 * min(fp, [], 2);

% Reshape the p-values to match the inputted real data
p = nan(length(idsRemoved));
p(~idsRemoved) = fp;
p = reshape(p, szx);






