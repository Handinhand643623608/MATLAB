function [discrete_data,bins] = discretize_data(continuous_data,num_steps)
% DISCRETIZE_DATA
% Takes any array and discretizes it into steps between its maximum and
% minimum values.  Steps are based on percentiles (cf Magri et al. 2012)
%
% discrete_data                 Data numbered from 1:num_steps
%   = discretize_data(
%           continuous_data,    Any matrix
%           num_steps           How many steps
%   )

% Flatten and sort data
flat_data = continuous_data(:);
flat_sorted_data = sort(flat_data);
% Get percentiles
percentiles_used = ((1:(num_steps))/(num_steps))*100;
bin_values = prctile(flat_sorted_data,percentiles_used);
% Sort by bins
discrete_data = sum(repmat(flat_data,[1,size(bin_values,2)]) > repmat(bin_values,[size(flat_data,1),1]),2) + 1;
discrete_data = reshape(discrete_data,size(continuous_data));
if nargout >= 2
    bins = [flat_sorted_data(1),bin_values];
end