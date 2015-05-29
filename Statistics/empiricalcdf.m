% EMPIRICALCDF - Generates p-values for data using an empirically derived null distribution.
%
%   SYNTAX:
%       p = empiricalcdf(r, n, t)
%
%   OUTPUT:
%       p:      [ DOUBLES ]
%               An array of p-values derived using both the real and null data distributions. This array will always be of
%               exactly the same size and dimensionality as R. Each element of this array represents the estimated 
%               probability of observing a value at least as extreme as the corresponding R element value, assuming that the
%               null hypothesis is true.
%
%   INPUTS:
%       r:      [ DOUBLES ]
%               An array of values constituting the real data distribution. This array can be of any size.
%
%       n:      [ DOUBLES ]
%               An array of values constituting the null data distribution. This array can be of any size.
%
%	OPTIONAL INPUT:
%		t:		STRING
%				The tail of the empirical CDF to be generated.
%				DEFAULT: 'Both'
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
%		20150527:	Re-implemented the C subroutine behind empirical CDF calculations in native MATLAB code so that this
%					function can still be used even when the MEX files I've written cannot.



%% FUNCTION DEFINITION
function p = empiricalcdf(r, n, t)

	% Fill in missing inputs
	if (nargin == 2); t = 'Both'; end

	% Error check
	assert(isnumeric(r), 'The real data distribution x must be an array of single- or double-precision values.');
	assert(isnumeric(n), 'The null data distribution n must be an array of single- or double-precision values.');
	assert(ischar(t), 'The tail selection argument t must be a string.');

	% Flatten the data distributions
	szr = size(r);
	r = r(:);
	n = n(:);

	% Remove any null values (zeros & NaNs)
	idsRemoved = isnan(r) | r == 0;
	r(idsRemoved) = [];
	n(isnan(n) | n == 0) = [];
	n = sort(n);

	if (exist('MexEmpiricalCDF', 'file') == 3)
		% Call the MEX function to do the heavy lifting
		fp = MexEmpiricalCDF(r, n, Tail2Num(t));
	else
		% Use native MATLAB code if the MEX function can't be used
		fp = ComputeCDF(r, n, t);
	end

	% Reshape the p-values to match the inputted real data
	p = nan(length(idsRemoved), 1);
	p(~idsRemoved) = fp;
	p = reshape(p, szr);
	
end



%% SUBROUTINES
function n = Tail2Num(t)
% TAIL2NUM - Converts a CDF tail string argument into the appropriate enumerator that is used across subroutines.
%
%	This subroutine converts the tail selection string provided by the user (to the base function) into an integer "magic
%	number" that can be inputted to the MEX subroutine. This integer corresponds with the numeric value of one of the tail
%	selection enumerators that the C function uses.
%
%	OUTPUT:
%		n:		INTEGER
%				The value of the corresponding enumerator found within the C subroutine.
%
%	INPUT:
%		t:		STRING
%				One of the supported tail selection strings.

	switch lower(t)
		case 'both';	n = 0;
		case 'left';	n = 1;
		case 'right';	n = 2;
		otherwise
			error('Unrecognized distribution tail selection %s. See documentation fpr available options.', t);
	end
end
function p = ComputeCDF(r, n, t)
% COMPUTECDF - Calculates empirical CDF values using MATLAB language functions.
%
%	This subroutine is used whenever the compiled MEX routine is unavailable. Unfortunately in those cases, this will require
%	significantly more time to complete.
%
%	OUTPUT:
%		p:		[ MR x 1 DOUBLES ]
%				A vector of p-values that constitute the empirical CDF. Values in this output correspond directly with
%				elements in r.
%
%	INPUTS:
%		r:		[ MR x 1 DOUBLES ]
%				The real data distribution. Both NaNs and zeros must be pre-removed.
%
%		n:		[ MN x 1 DOUBLES ]
%				The null data distribution. This vector must be pre-sorted into ascending numerical order, and both NaNs and
%				zeros must be pre-removed.
%	
%		t:		STRING
%				The tail of the empirical CDF to be generated.

	lr = length(r);
	ln = length(n);
	
	p = zeros(lr, 1);
	
	switch lower(t)
		case 'both'
			for a = 1:lr
				b = 1;
				while (b <= ln && n(b) < r(a));
					b = b + 1; 
				end
				pval = (b - 1) / ln;
				p(a) = 2 * min(pval, 1 - pval);
			end
			
		case 'left'
			for a = 1:lr
				b = 1;
				while (b <= ln) && (n(b+1) < r(a))
					b = b + 1;
				end
				p(a) = (b - 1) / ln;
			end
			
		case 'right'
			for a = 1:lr
				b = 0;
				while (b <= ln) && (n(b+1) < r(a))
					b = b + 1;
				end
				p(a) = 1 - ((b - 1) / ln);
			end
			
		otherwise
			error('Unrecognized distribution tail selection %s. See documentation fpr available options.', t);
	end
	
end