function fdr_thresh = f_bh_fdr(p_vals, alpha)
% F_BH_FDR Calculate the Benjamini-Hochberg control of false discovery rate
%   f_bh_fdr produces a threshold based on the input of p-values
%   (calculated from a CDF) and a significance level. 
% 
%   Syntax:
%   fdr_thresh = f_bh_fdr(p_vals, alpha)
% 
%   FDR_THRESH: the output of the function (false discovery rate
%               threshold), below or equal to which the null hypothesis can
%               be rejected
%   P_VALS: a vector of p-values
%   ALPHA: the significance level (maximum false discovery rate allowable)
%          (e.g. 0.05)
% 
%   Adapted from the function bh_fdr written by Garth Thompson
%       Written by Josh Grooms on 4/26/2012

%% Initialize
% Determine the number of samples in the p-value list
num_samples = length(p_vals);

% Order the p-value list
p_vals = sort(p_vals, 'ascend');

% Create a weighting vector
weights = alpha.*((1:num_samples)./num_samples);

%% Determine the threshold
% Convert data & weights to a column vector if necessary
if size(p_vals, 2) ~=1
    p_vals = p_vals';
elseif size(weights, 2) ~= 1
    weights = weights';
end

% Determine the indices of p-values that are less than or equal to the weights
cutoff_indices = find(p_vals <= weights);
cutoff_index = max(cutoff_indices);

if isempty(cutoff_index)
    fdr_thresh = 0;
else
    fdr_thresh = p_vals(cutoff_index);
end



