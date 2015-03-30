function [lower_cutoff upper_cutoff] = f_bhfdr_cutoffs(correlation_vector, significance)
%% f_bhfdr_cutoffs determines the upper and lower cutoff values of significance for a vector of EEG-fMRI correlation values using the Benjamini-Hochberg false discovery rate method
%   
%   Syntax:
%   [lower_cutoff upper_cutoff] = f_bhfdr_cutoffs(correlation_vector, significance)
%   
%   CORRELATION_VECTOR: A vector (or matrix) of correlation values from the
%                       EEG-fMRI correlation data. If a matrix is entered,
%                       rows correspond to electrode-specific correlation
%                       data. Otherwise, a single row of grouped
%                       correlation data can be inputted. 
%   SIGNIFICANCE: The alpha level (significance) desired. An empty value
%                 will default to a signficance of 0.05.
%
%   Written by Josh Grooms on 3/8/2012

%% Initialize function-specific parameters
if nargin < 2
    significance = 0.05;
end

switch size(correlation_vector, 1)
    case 1
        % Get the positive, negative, and two-tailed CDF values
        pos_cdfvals = cdf('norm', correlation_vector, mean(correlation_vector), std(correlation_vector));
        neg_cdfvals = 1 - pos_cdfvals;
        twot_cdfvals = 2*min(pos_cdfvals, neg_cdfvals);
        
        % Use false discovery rate on the data
        bhfdr_thresh = bh_fdr(twot_cdfvals, significance);
        
        % Get the upper and lower cutoff values
        upper_cutoff = min(correlation_vector(boolean((twot_cdfvals <= bhfdr_thresh) .* (correlation_vector > 0))));
        lower_cutoff = max(correlation_vector(boolean((twot_cdfvals <= bhfdr_thresh) .* (correlation_vector < 0))));
        
    otherwise
        % Pre-allocate data
        pos_cdfvals = zeros(size(correlation_vector));
        neg_cdfvals = pos_cdfvals;
        twot_cdfvals = pos_cdfvals;
        bhfdr_thresh = zeros(size(correlation_vector, 1), 1);
        upper_cutoff = bhfdr_thresh;
        lower_cutoff = upper_cutoff;
        
        for i = 1:size(correlation_vector, 1)         
            % Get the positive, negative, and two-tailed CDF values
            pos_cdfvals(i, :) = cdf('norm', correlation_vector(i, :), mean(correlation_vector(i, :)), std(correlation_vector(i, :)));
            neg_cdfvals(i, :) = 1 - pos_cdfvals(i, :);
            twot_cdfvals(i, :) = 2*min(pos_cdfvals(i, :), neg_cdfvals(i, :));
            
            % Use false discovery rate on the data
            bhfdr_thresh(i) = bh_fdr(twot_cdfvals(i, :), significance);
            
            % Get the upper and lower cutoff values
            upper_cutoff(i) = min(correlation_vector(i, boolean((twot_cdfvals(i, :) <= bhfdr_thresh(i)) .* (correlation_vector(i, :) > 0))));
            lower_cutoff(i) = max(correlation_vector(i, boolean((twot_cdfvals(i, :) <= bhfdr_thresh(i)) .* (correlation_vector(i, :) < 0))));
        end
end
       
                
           