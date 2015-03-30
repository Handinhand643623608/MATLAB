function [lower_cutoff upper_cutoff] = u_bootstrap_corrData(corr_data, null_data, alpha, forceBinoFlag)
% F_CORR_BOOTSTRAP performs a bootstrapping statistical analysis to
%   determine significant cutoff values for thresholding correlations. The
%   analysis to be performed is two-tailed.
% 
%   Syntax:
%   [lower_cutoff, upper_cutoff] = f_corr_bootstrap(corr_data, null_data, alpha)
% 
%   LOWER_CUTOFF: the correlation value beneath which all values are
%                 statistically significant.
%   UPPER_CUTOFF: the correlation value above which all values are
%                 statistically significant.
%   CORR_DATA: the correlation data to be analyzed for significance. This
%              can be a vector or an array of correlation values.
%   NULL_DATA: a null distribution (generated elsewhere) against which the
%              correlation data is to be compared for significance. This
%              can be a vector or an array of data. 
%   ALPHA: the significance cutoff for the multiple comparisons correction
%          (default is 0.05).
% 
%       Written by Josh Grooms on 5/2/2012

%% Initialize
% Assign a value to alpha if it is not an input
if nargin < 2
    error('Both correlation and null data must be inputs')
elseif nargin == 2
    alpha = 0.05;
    forceBinoFlag = 0;
elseif nargin == 3
    forceBinoFlag = 0;
end

%% Create vectors of the data if they are not given that way
% Correlation data
if iscell(corr_data)
    while iscell(corr_data{1})
        corr_data_transfer = {};
        for i = 1:numel(corr_data)
            corr_data_transfer = cat(1, corr_data_transfer, corr_data{i});
        end
        corr_data = corr_data_transfer;
    end    
    corr_data = cell2mat(corr_data);
end
corr_vec = corr_data(:);
corr_vec(isnan(corr_vec)) = [];
corr_vec(corr_vec == 0) = [];

% Null data
if iscell(null_data)
    while iscell(null_data{1})
        null_data_transfer = {};
        for i = 1:numel(null_data)
            null_data_transfer = cat(1, null_data_transfer, null_data{i});
        end
        null_data = null_data_transfer;
    end    
    null_data = cell2mat(null_data);
end
null_vec = null_data(:);
null_vec(isnan(null_vec)) = [];
null_vec(null_vec == 0) = [];

%% Perform the analysis
% Convert correlation coefficients into p-values
disp('Calculating Positive Arbitrary p-Values')
pos_cdfvals = pval_arbitrary(corr_vec, null_vec, 'h');
disp('Calculating Negative Arbitrary p-Values')
neg_cdfvals = pval_arbitrary(corr_vec, null_vec, 'l');
twot_cdfvals = 2*min(pos_cdfvals, neg_cdfvals);

% Perform SGOF to determine maximum significant p-value
disp('Performing SGoF on Data')
[not_used pval_sig] = matlab_sgof(twot_cdfvals, alpha, forceBinoFlag);
disp('SGoF Complete')

% Convert this p-value into a correlation value for thresholding
if ~isempty(pval_sig)
    corr_sig = corr_vec(twot_cdfvals <= pval_sig);
    lower_cutoff = max(corr_sig(corr_sig < 0));
    upper_cutoff = min(corr_sig(corr_sig > 0));
else
    % Nothing is significant
    lower_cutoff = -1;
    upper_cutoff = 1;
    warning('No Significant Cutoffs Found from SGoF: Cutoffs Set to +/- 1')
end

% In case no cutoffs are found
if isempty(lower_cutoff)
    lower_cutoff = -1;
    warning('No Significant Lower Cutoff Found from SGoF: Cutoff Set to -1')
end
if isempty(upper_cutoff)
    upper_cutoff = 1;
    warning('No Significant Upper Cutoff Found from SGoF: Cutoff Set to 1')
end
