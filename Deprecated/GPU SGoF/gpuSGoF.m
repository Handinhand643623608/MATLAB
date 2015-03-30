function cutoff = gpuSGoF(cdfVals, alphaVal)
%SGOF Run Sequential Goodness of Fit for FWER correction.
%   This function executes the algorithm developed by Carvajal-Rodriguez et al to correct for
%   multiple comparisons during statistical hypothesis testing. It works by comparing the
%   uncorrected number of significant values found in data against a binomial distribution, which
%   predicts how many should be significant given the number of comparisons.
%
%   SYNTAX:
%   cutoff = sgof(cdfVals)
%   cutoff = sgof(cdfVals, alphaVal)
%
%   OUTPUT:
%   cutoff:         The scalar cutoff below which p-values are considered statistically significant.
%                   If no significance is found, this function returns "NaN" as the cutoff value.
%
%   INPUTS:
%   cdfVals:        A vector of p-values for which the significance cutoff is needed. 
%
%   OPTIONAL INPUTS:
%   alphaVal:       The significance threshold, or Type I error rate for hypothesis testing.
%                   DEFAULT: 0.05
%
%   Written by Josh Grooms on 20130627
%       20140127:   Created this copy of the original (sgof.m) function to accommodate GPU processing. This function
%                   cuts run time down by more than 50%, even compared against the new fastBinoCDF function.


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
probNumSig = 1 - gpuBinoCDF(1:numSig, length(cdfVals), alphaVal);
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

