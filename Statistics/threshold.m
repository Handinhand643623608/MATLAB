% THRESHOLD - Thresholds empirical data distributions for statistical significance.
%
%   THRESHOLD takes two empirical data distributions and determines statistical significance cutoffs in terms of both the
%   original data units and as a p-value. It optionally takes additional arguments that control the confidence interval size
%   and the methods of FWER correction that can be applied. 
%
%   WARNING: Currently this function only handles two-tailed significance tests.
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
%
%       CorrectFWER:    BOOLEAN
%                       A Boolean controlling whether or not family-wise error rate (FWER) will be controlled during the
%                       thresholding process. FWER tends to increase with increasing numbers of hypothesis tests, and so it
%                       should be enabled when that number becomes large. Because this function is frequently applied to the
%                       results of fMRI analyses, it is enabled by default.
%                       DEFAULT: true
%
%       MethodFWER:     STRING
%                       Not yet fully implemented...
%                       DEFAULT: 'G'
%                       OPTIONS:
%                           'Bino'
%                           'G'

%% CHANGELOG
%   Written by Josh Grooms on 20150206



%% FUNCTION DEFINITION
function varargout = threshold(r, n, varargin)

    assert(~isempty(r) && ~isempty(n), 'Data distributions cannot be empty arrays.');
    
    function Defaults
        Alpha = 0.05;
        CorrectFWER = true;
        MethodFWER = 'G';
    end
    assign(@Defaults, varargin);
    
    r = formatdist(r);
    n = formatdist(n);
    n = sort(n);
    
    halpha = Alpha / 2;
    ntrials = length(r);
    nnulls = length(n);
    
    idxLC = floor(halpha * nnulls);
    idxUC = ceil((1 - halpha) * nnulls);
    cutoffs = [ n(idxLC), n(idxUC) ];
    p = Alpha;
    
    if CorrectFWER
        nsig = sum(r <= cutoffs(1) | r >= cutoffs(2));
        switch lower(MethodFWER)
            case 'g'
                nsig = gtest(ntrials, nsig, Alpha);
            case 'bino'
                nsig = binotest(ntrials, nsig, Alpha);
            otherwise
                error('Unrecognized FWER correction method name. See documentation for supported options.');
        end
        
        if (nsig ~= 0)
            idxLC = ceil(nsig / 2);
            idxUC = nnulls - floor(nsig / 2) + 1;
            
            cutoffs = [ n(idxLC), n(idxUC) ];
            p = max(empiricalcdf(cutoffs, n));
        end
    end
    
    assignOutputs(nargout, cutoffs, p);

end



%% SUBROUTINES
function nsig = binotest(ntrials, nsig, alpha)
% BINOTEST - 
    p = binocdf(1:nsig, ntrials, alpha);
    nremove = find(p > alpha, 1, 'last');
    nsig = nsig - nremove;
end

function x = formatdist(x)
% FORMATDIST - Standardizes the shape of a distribution vector and eliminates null values from it.
    x = x(:);
    x(isnan(x)) = [];
    x(x == 0) = [];
end

function nsig = gtest(ntrials, nsig, alpha)
% GTEST - 
    obsAA = 1:nsig;                     % Observed trials with p-values lower than alpha
    expAA = ntrials * alpha;            % Expected number of trials with p-value lower than alpha
    obsBA = ntrials - obsAA;            % Observed trials with p-values greater than alpha
    expBA = ntrials * (1 - alpha);      % Expected number of trials with p-values greater than alpha
    q = 1 + (1 / (2 * ntrials));        % Williams correction factor
    
    g = 2 * ( (obsAA .* log(obsAA ./ expAA)) + (obsBA .* log(obsBA ./ expBA)) ) ./ q;
    
    gcutoff = chi2inv(1 - alpha, 1);
    nremove = find(g < gcutoff, 1, 'last');
    nsig = nsig - nremove;
end