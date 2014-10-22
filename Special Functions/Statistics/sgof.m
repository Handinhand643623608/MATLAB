function cutoff = sgof(cdfVals, alphaVal)
% SGOF - Runs Sequential Goodness of Fit for FWER correction.
%   This function executes the algorithm developed by Carvajal-Rodriguez et al to correct for multiple comparisons
%   during statistical hypothesis testing. It works by comparing the uncorrected number of significant values found in
%   data against a binomial distribution, which predicts how many should be significant given the number of comparisons.
%
%   SYNTAX:
%   cutoff = sgof(cdfVals)
%   cutoff = sgof(cdfVals, alphaVal)
%
%   OUTPUT:
%   cutoff:         DOUBLE
%                   The scalar cutoff below which p-values are considered statistically significant. If no significance
%                   is found, this function returns "NaN" as the cutoff value.
%
%   INPUTS:
%   cdfVals:        [ DOUBLES ]
%                   A vector of p-values for which the significance cutoff is needed. 
%
%   OPTIONAL INPUTS:
%   alphaVal:       DOUBLE
%                   The significance threshold, or Type I error rate for hypothesis testing.
%                   DEFAULT: 0.05

%% CHANGELOG
%   Written by Josh Grooms on 20130627
%       20140127:   Implemented a much faster version of binocdf by increasing memory limits within that function.
%       20141021:   Updated the documentation for this function.



%% Initialize
if nargin == 1
    alphaVal = 0.05;
end

% Sort the CDF values
cdfVals = sort(cdfVals(:));

% Determine the number of significant (uncorrected) CDF values
numSig = sum(cdfVals <= alphaVal);



%% FWER Correction
% Test number of significant values against a binomial distribution
if exist('fastBinoCDF.m', 'file')
    probNumSig = 1 - fastBinoCDF(1:numSig, length(cdfVals), alphaVal);
else
    probNumSig = 1 - binocdf(1:numSig, length(cdfVals), alphaVal);
end
numPassed = probNumSig <= alphaVal;

% Find the smallest number of significant CDF values
idxSmallNumSig = find(numPassed == 0, 1, 'last');
if isempty(idxSmallNumSig)
    idxSmallNumSig = 0;
end
numSig = numSig - idxSmallNumSig;

% Find the significant CDF value
if numSig == 0
    cutoff = NaN;
else
    cutoff = cdfVals(numSig);
end