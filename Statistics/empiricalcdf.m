% EMPIRICALCDF - Generates p-values for data using an empirically derived null distribution.
%
%   SYNTAX:
%       p = empiricalcdf(r, n, t)
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
%
%		t:		STRING
%				The tail of the empirical CDF to be generated.
%
%				OPTIONS:
%					'Both'	- Calculates CDF values for two-tailed hypothesis tests.
%					'Left'	- Calculates CDF values for right-tailed hypothesis tests.
%					'Right'	- Calculates CDF values for left-tailed hypothesis tests.

%% CHANGELOG
%   Written by Josh Grooms on 20141111
%       20150131:   Removed the option for tail selection. This was never implemented and keeping it as an input argument was
%                   potentially dangerous. This function now only calculates two-tailed p-value distributions.
%       20150205:   Added in the sorting of the null distribution, which should make the p-value generation process a bit
%                   faster.
%		20150225:	Implemented CDF generation for one-tailed hypothesis testing.



%% FUNCTION DEFINITION
function p = empiricalcdf(r, n, t)

% Fill in missing inputs
if (nargin == 2); t = 'Both'; end

% Error check
assert(isnumeric(r), 'The real data distribution x must be an array of single- or double-precision values.');
assert(isnumeric(n), 'The null data distribution n must be an array of single- or double-precision values.');
assert(ischar(t), 'The tail selection must be a string.');

% Flatten the data distributions
szx = size(r);
r = r(:);
n = n(:);

% Remove any null values (zeros & NaNs)
idsRemoved = isnan(r) | r == 0;
r(idsRemoved) = [];
n(isnan(n) | n == 0) = [];
n = sort(n);

% Call the MEX function to do the heavy processing
switch lower(t)
	case 'both'
		fp = MexEmpiricalCDF(r, n, 0);
	case 'left'
		fp = MexEmpiricalCDF(r, n, 1);
	case 'right'
		fp = MexEmpiricalCDF(r, n, 2);
	otherwise
		error('Unrecognized distribution tail selection %s. See documentation fpr available options.', t);
end

% Reshape the p-values to match the inputted real data
p = nan(length(idsRemoved), 1);
p(~idsRemoved) = fp;
p = reshape(p, szx);