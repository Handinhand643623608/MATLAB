function [lowerCutoff upperCutoff] = u_FDR_corrData(corrData, alpha)

%% Benjamini-Hochsberg False Discovery Rate
% Assign alpha value if not provided (0.05)
if isempty(alpha)
    alpha = 0.05;
end

% Create a vector of the correlation data
corrVec = corrData(:);

% Fisher's r-to-z transform
corrVec = atanh(corrVec);

% Get rid of zeros
corrVec(isnan(corrVec)) = [];
corrVec(corrVec == 0) = [];

% Get the positive, negative, & two-tailed CDF values
posVals = cdf('norm', corrVec, mean(corrVec), std(corrVec));
negVals = 1 - posVals;
twotVals = 2*min(posVals, negVals);

% Get the False Discovery Rate threshold from the data
threshFDR = bh_fdr(twotVals, alpha);

% Get the upper & lower cutoff values
upperCutoff = min(corrVec(boolean((twotVals <= threshFDR) .* (corrVec > 0))));
lowerCutoff = max(corrVec(boolean((twotVals <= threshFDR) .* (corrVec < 0))));

