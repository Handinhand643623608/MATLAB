function z = f_nanzscore(x, flag, dim)
% F_NANZSCORE Standardized z-score that handles NaNs
%     f_nanzscore computes standardized z-scores given a matrix or vector of
%     values. It returns an array of the same size as the input, but centered
%     and scaled. Unlike the zscore function included in MATLAB, this
%     function can handle NaNs in the input data by not considering them in
%     calculations
% 
%     Syntax:
%     Z = f_nanzscore(x, dim)
%     
%     Z: The output matrix of standardized values (same size as input array)
%     X: The input array
%     FLAG: Pass in 0 to use the default normilization by N-1, or 1 to use
%           N.
%     DIM: The dimension over which to calculate the z-scores (e.g. 1 to
%          standardize down the rows of an input matrix or 2 to standardize 
%          across the columns)

%% Initialize function-specific paramters
% Determine how to compute the normilization (if not input)
if nargin < 2
    flag = 0;
end

% Find the dimension over which to compute the z-scores (if not input)
if nargin < 3
    dim = find(size(x) ~= 1, 1)
end

%% Calculate the z-scores
% Compute the mean
mu = nanmean(x, dim);

% Compute the standard deviation & set any zeros to ones
sigma = nanstd(x, flag, dim);
sigma(0 == sigma) = 1;

% Create the output matrix
z = bsxfun(@minus, x, mu);
z = bsxfun(@rdivide, z, sigma);

