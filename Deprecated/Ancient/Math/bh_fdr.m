function p_thresh = bh_fdr(p_value_list,thresh);
% BH_FDR    Benjamini-Hockberg control of false discovery rate
% (J.R. Statist. Soc. B (1995) 57, No 1, pp289-300)
%
%   p_thresh =              Threshold below or equal to which the null hypothesis can
%                           be rejected.
%   bh_fdr(p_value_list     List of p values
%         ,thresh);         Maximum false discovery rate allowable
%
% Garth Thompson 2010 July 23
%
% Requires: 
%


m = length(p_value_list);
% Order the p_values
p_value_list = sort(p_value_list,'ascend');
% Create the weighting
weights = thresh .* ((1:m) ./ m);
% Get the index where the p values are less than or equal to the weights
p_value_list = reshape(p_value_list,numel(p_value_list),1);
weights = reshape(weights,numel(weights),1);
cutoff_index = max(find(p_value_list <= weights));

if cutoff_index > 0
    p_thresh = p_value_list(cutoff_index);
else
    p_thresh = 0.0;
end