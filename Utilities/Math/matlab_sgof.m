function [num_significant pval_significant] = matlab_sgof(pval_list,alphavalue,force_bino)
% MATLAB_SGOF
% The sequential goodness of fit multiple comparisons metric.  See
% Carvajal-Rodriguez et al., 2009, BMC Bioinformatics
%
% num_significant       Number of significant p values
%                       (between 1 and length(pval_list))
% pval_significant      Highest significant p value
% = matlab_sgof(
%   pval_list           List of probability values (p values) to test
%   alphavalue          (Optional, default 0.05) Alpha significance cutoff
%   force_bino          (Optional, default false) If true will always use
%                       a binomial distribution for the test.  If false
%                       will use a G test when 11 or more p values are
%                       supplied.
% )
%
% MATLAB code written by Garth Thompson, http://groups.bme.gatech.edu/groups/keilholz/index.html

% Good ol' default 5%
if ~exist('alphavalue','var')
    alphavalue = [];
end
if isempty(alphavalue)
    alphavalue = 0.05;
end

% Default use G test if 11 or more p values
if ~exist('force_bino','var')
    force_bino = [];
end
if isempty(force_bino)
    force_bino = false;
end

% STEP 1: Sort the p values
pval_list = reshape(pval_list,[numel(pval_list), 1]);
pval_list = sort(pval_list);

% STEP 2: R is the number of p values below threshold
R = sum(pval_list <= alphavalue);
num_pvals = numel(pval_list);
if nargout == 1
    clear pval_list;
end

% STEP 3: Find all significant p values

% Probability for each possible number of significant values

if force_bino || (num_pvals <= 10)
    % Binomial distribution
    prob_each_possible_num = (1 - cdf('bino',1:R,num_pvals,alphavalue));
    % Find where passed the test
    passed_test = prob_each_possible_num<=alphavalue;
else
    % G Test
    if num_pvals ~= R
        prob_each_possible_num = 2*(...
            ((1:R) .* log((1:R) ./ (num_pvals*alphavalue))) +... % Below alpha
            ((num_pvals - (1:R)) .* log((num_pvals - (1:R)) / (num_pvals*(1-alphavalue))))... % Above Alpha
            / (1 + 1/(2*num_pvals))... % Account for williams factor
            );
    else
        prob_each_possible_num = 2*(...
            ((1:(R-1)) .* log((1:(R-1)) ./ (num_pvals*alphavalue))) +... % Below alpha
            ((num_pvals - (1:(R-1))) .* log((num_pvals - (1:(R-1))) / (num_pvals*(1-alphavalue))))... % Above Alpha
            / (1 + 1/(2*num_pvals))... % Account for williams factor
            );
        prob_each_possible_num = [prob_each_possible_num, Inf];
    end
    % G Threshold
    g_thresh = icdf('chi2',1-(alphavalue),1); % One degree of freedom, values = 0 and 1
    % Find where passed the test
    if R > 1
        if prob_each_possible_num(end) >= prob_each_possible_num(end-1)
            passed_test = prob_each_possible_num>=g_thresh;
        else
            passed_test = zeros(size(prob_each_possible_num));
        end
    else
        passed_test = prob_each_possible_num>=g_thresh;
        if sum(passed_test) > 0
            warning('Unable to distinguish sides of G distribution with only one possibly significant value.');
        end
    end
end

% Find last non-pass
last_zero_index = find(passed_test == 0,1,'last');
if isempty(last_zero_index)
    last_zero_index = 0;
end
num_significant = R - last_zero_index;

if isempty(num_significant)
    num_significant = 0;
end

if nargout > 1
    if num_significant > 0
        pval_significant = pval_list(num_significant);
    else
        pval_significant = NaN;
    end
end
