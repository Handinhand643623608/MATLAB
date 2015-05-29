% THRESHOLD - Thresholds empirical data distributions for statistical significance.
%
%   THRESHOLD takes two empirical data distributions and determines statistical significance cutoffs in terms of both the
%   original data units and as a p-value. It optionally takes additional arguments that control the confidence interval size
%   and the methods of FWER correction that can be applied. 
%
%   SYNTAX:
%       c = threshold(r, n)
%       c = threshold(r, n, 'PropertyName', PropertyValue,...)
%       [c, p] = threshold(...)
%
%   OUTPUTS:
%       c:              [ DOUBLE, DOUBLE ]
%                       The lower and upper significance cutoff values in the same units as the original data distribution R.
%                       The first element of this argument is the lower cutoff. Data values in R that are outside of these
%                       cutoffs (R < C(1) | R > C(2)) are deemed statistically significant.
%
%       p:              DOUBLE
%                       The p-value that corresponds with the data cutoff values C. CDF values below this result are deemed
%                       statistically significant.
%
%   INPUTS:
%       r:              [ DOUBLES ]
%                       An array of numbers representing the real data distribution. This should contain the the actual test
%                       results that will be thresholded. R can be an array of any size and shape.
%
%       n:              [ DOUBLES ]
%                       An array of numbers representing the null data distribution. This should be an empirically derived
%                       set of results that model how the data in R would look if no significance existed. In otherwords, it
%                       represents the null hypothesis. N can an array of any size and shape, but typically it is much larger
%                       than R. 
%
%   PROPERTIES:
%       Alpha:          DOUBLE
%                       The significance level that dictates the width of the confidence interval used to produce threshold
%                       values. This is also the Type I error rate for hypothesis testing.
%						DEFAULT: 0.05
%
%       CorrectFWER:    BOOLEAN
%                       A Boolean controlling whether or not family-wise error rate (FWER) will be controlled during the
%                       thresholding process. FWER tends to increase with increasing numbers of hypothesis tests, and so it
%                       should be enabled when that number becomes large. Because this function is frequently applied to the
%                       results of fMRI analyses, it is enabled by default.
%                       DEFAULT: true
%
%       MethodFWER:     STRING
%                       A string that dictates which of the available methods will be applied to correct for FWER. Options
%                       currently include using the False Discovery Rate (FDR) or Sequential Goodness-of-Fit (SGoF)
%                       approaches. 
%                       DEFAULT: 'G'
%                       OPTIONS:
%                           'Bino'	- SGoF using a binomial test (for small sample distributions only)
%							'FDR'	- Bejamini-Hochberg control of FDR
%                           'G'		- SGoF using a G-test (for large sample distributions)

%% CHANGELOG
%   Written by Josh Grooms on 20150206
%		20150528:	Implemented FDR as a method of controlling family-wise error rate. Also filled out more documentation.



%% FUNCTION DEFINITION
function varargout = threshold(r, n, varargin)
    
    function Defaults
        Alpha		= 0.05;
        CorrectFWER = true;
        MethodFWER	= 'G';
		Tails		= 'Both';
    end
    assign(@Defaults, varargin);
    
	assert(~isempty(r) && ~isempty(n), 'Data distributions r and n cannot be empty arrays.');
	
    r = FormatDist(r);
    n = FormatDist(n);
    n = sort(n);
    
    ntrials = length(r);
    nnulls = length(n);
	
	% Determine the cutoff values in terms of the original data from the null distribution & the significance level
	switch lower(Tails)
		case 'both'
			alpha = Alpha / 2;
			idxLC = floor(alpha * nnulls);
			idxUC = ceil((1 - alpha) * nnulls);
			cutoffs = [ n(idxLC), n(idxUC) ];
		
		case 'left'
			idxLC = floor(Alpha * nnulls);
			cutoffs = [ n(idxLC), NaN ];
			
		case 'right'
			idxUC = ceil((1 - Alpha) * nnulls);
			cutoffs = [ NaN, n(idxUC) ];
			
		otherwise
			error('Unrecognized distribution tail selection %s. See documentation for available options.', Tails);
	end

	% If FWER is not being accounted for, the p-value cutoff for significance is just alpha
    p = Alpha;
    
	if CorrectFWER
		
		% WARNING: 
		%	The following approach only works when p-values decrease outside of the cutoff values. For sampled data that
		%	decrease in p-value inside the cutoff boundaries, FWER correction will not be applied correctly. This doesn't
		%	matter for any of my data (e.g. correlations, coherence, mutual information, etc), but it may matter to others
		%	at some point because in theory empirical distributions can take on any shape. 
		
		% Get the number of significant trials (uncorrected for FWER)
        nsig = sum(r <= cutoffs(1) | r >= cutoffs(2));
		
		% Control for FWER (adjusts the number of significant trials)
		switch lower(MethodFWER)
            case 'bino'
                nsig = BinoTest(ntrials, nsig, Alpha);
			case 'fdr'
				nsig = BHFDR(r, n, Tails, cutoffs, Alpha);
            case 'g'
                nsig = GTest(ntrials, nsig, Alpha);

            otherwise
                error('Unrecognized FWER correction method name. See documentation for supported options.');
		end
		
		% Calculate new data & p-value cutoffs based on the FWER-adjusted number of significant trials
		if (nsig ~= 0)
			switch lower(Tails)
				case 'both'
					idxLC = ceil(nsig / 2);
					idxUC = nnulls - floor(nsig / 2) + 1;
					cutoffs = [ n(idxLC), n(idxUC) ];
					p = max(empiricalcdf(cutoffs, n));
					
				case 'left'
					cutoffs(1) = n(nsig);
					p = empiricalcdf(cutoffs(1), n, 'Left');
					
				case 'right'
					cutoffs(2) = n(end - nsig + 1);
					p = empiricalcdf(cutoffs(2), n, 'Right');
			end
		end
		
	end
    
	varargout = { };
    assign(varargout, nargout, cutoffs, p);

end



%% SUBROUTINES
function n = BHFDR(r, n, t, cutoffs, alpha)
% BHFDR - Calculates the FWER-corrected number of significant tests using Benjamini-Hochberg False Discovery Rate control.
%
%	OUTPUT:
%		n:			INTEGER
%					The estimated number of significant trials after FWER correction is applied.
%	
%	INPUTS:
%		r:			[ MR x 1 DOUBLES ]
%					The complete real data distribution.
%
%		n:			[ MN x 1 DOUBLES ]
%					The complete null data distribution.
%
%		t:			STRING
%					The tails of the CDF being tested for significance.
%
%		cutoffs:	[ DOUBLE, DOUBLE ]
%					The FWER-uncorrected cutoff values in the same units as the data in r.
%
%		alpha:		DOUBLE
%					The desired family-wise error rate (FWER).
	
	% Only look at trials whose p-values are significant before FWER correction (cuts out a lot of computation)
	ntrials = length(r);
	rsig = r(r <= cutoffs(1) | r >= cutoffs(2));
	nsig = length(rsig);	
	
	% Create a vector of weights the same length as the uncorrected significant data array
	weights = alpha * ( (1:nsig) / ntrials );
	weights = weights';
	
	% Create p-values for all of the uncorrected significant data points
	p = sort(empiricalcdf(rsig, n, t));
	
	% The adjusted number of significant trials is the index of the last sample whose p-value is less than its weight
	n = find(p <= weights, 1, 'last');
	
	% Ensure that empty arrays aren't returned (i.e. from FIND)
	if isempty(n); n = 0; end
end
function n = BinoTest(ntrials, nsig, alpha)
% BINOTEST - Calculates the FWER-corrected number of significant tests using a binomial distribution directly.
%
%	The binomial distribution is used as an exact test to determine the expected number of significant results given a number
%	of trials. However, because no closed-form inverse CDF formula exists for it, applying this test is extremely slow when
%	the number of trials is large. When correcting FWER for more than ~100 trials, the G-test is recommended instead.
%
%	OUTPUT:
%		n:			INTEGER
%					The estimated number of significant results after FWER correction is applied.
%
%	INPUTS:
%		ntrials:	INTEGER
%					The number of trials or hypothesis tests that were performed. This is the length of the real data
%					distribution R from above.
%
%		nsig:		INTEGER
%					The number of significant results (p < alpha) before FWER correction is applied. 
%
%		alpha:		DOUBLE
%					The desired family-wise error rate (FWER).

    p = binocdf(1:nsig, ntrials, alpha);
    nremove = find(p > alpha, 1, 'last');
    n = nsig - nremove;
end
function x = FormatDist(x)
% FORMATDIST - Standardizes the shape of a data distribution vector and eliminates null values from it.
    
	x = x(:);
    x(isnan(x)) = [];
    x(x == 0) = [];
end
function n = GTest(ntrials, nsig, alpha)
% GTEST - Calculates the FWER-corrected number of significant tests using a goodness-of-fit test.
%
%	The goodness-of-fit test (G-test) is an approximation of the binomial test whose accuracy improves with increasing
%	numbers of trials. It is also substantially faster than a binomial test. For hypothesis testing involving more than ~100
%	trials, the use of a G-test is strongly recommended and offers practically identical results.
%
%	OUTPUT:
%		n:			INTEGER
%					The estimated number of significant results after FWER correction is applied.
%
%	INPUTS:
%		ntrials:	INTEGER
%					The number of trials or hypothesis tests that were performed. This is the length of the real data
%					distribution R from above.
%
%		nsig:		INTEGER
%					The number of significant results (p < alpha) before FWER correction is applied. 
%
%		alpha:		DOUBLE
%					The desired family-wise error rate (FWER).

    obsBA = 1:nsig;                     % Observed trials with p-values lower than alpha
    expBA = ntrials * alpha;            % Expected number of trials with p-value lower than alpha
    obsAA = ntrials - obsBA;            % Observed trials with p-values greater than alpha
    expAA = ntrials * (1 - alpha);      % Expected number of trials with p-values greater than alpha
    q = 1 + (1 / (2 * ntrials));        % Williams correction factor
    
    g = 2 * ( (obsAA .* log(obsAA ./ expAA)) + (obsBA .* log(obsBA ./ expBA)) ) ./ q;
    
    gcutoff = chi2inv(1 - alpha, 1);
    nremove = find(g < gcutoff, 1, 'last');
    n = nsig - nremove;
end