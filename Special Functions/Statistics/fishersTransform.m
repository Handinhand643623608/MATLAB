function z = fishersTransform(r, n)
% FISHERSTRANFORM - Transforms Pearson correlation coefficients to a normally distributed data set.
%   This function performs the variance stabilizing Fisher's r-to-z Transform on Pearson product-moment correlation
%   coefficients, which results in a data distribution that is approximately normal. This distribution is then
%   normalized to z-scores so that statistical significance testing can be conducted on the outputted data array.
%
%   Here, the Pearson product-moment correlation coefficient (r) is defined as the covariance between two data sets
%   (e.g. two signals or time series) that has been normalized to lie in the range [-1, 1]. Broadly speaking, it is an
%   estimate of how similar two data sets are to one another and is frequently used to quantify linear relationships
%   between signals and images. The formula for calculating these correlation coefficients is as follows:
%
%           sum( (X - mean(X)) .* (Y - mean(Y)) )
%       r = -------------------------------------
%                      std(X) * std(Y)
%
%           X: One signal, time series, or data set
%           Y: Another signal, time series, or data being correlated with X
%
%   The Fisher r-to-z Transform is defined as the hyperbolic arctangent of these correlation coefficients:
%   
%       z = atanh(r)
%
%   The purpose of this transformation is to decouple the variance and average of a coefficient distribution. Because of
%   the hard upper and lower bounds on correlation coefficients, the variance of any coefficient distribution is
%   inherently biased by its average value. By spreading values near these extremes out to positive or negative infinity
%   (the transform is approximately an identity function between ~[-1/2, 1/2], the variance of the distribution becomes
%   independent of the mean value. The data then tend to approximate a normal (Gaussian) distribution shape.
%
%   The final step is to normalize these z-scores by the standard deviation of the sampling distribution as shown below:
%
%                    z
%       z = -------------------
%           ( 1 / sqrt(N - 3) )
%
%         = z .* sqrt(N - 3)
%
%           N: The degrees of freedom in either X or Y.
%
%   This results in a z-score distribution that is suitable for statistical significance tests. The reason for this
%   normalization step is to scale the data so that a null distribution of transformed r values would approximate a
%   true standard normal distribution (with zero mean and unit standard deviation). Such a null distribution might be
%   derived by estimating and transforming the correlation coefficients for data sets that known to be uncorrelated. 
%   
%
%   SYNTAX:
%   z = fishersTransform(r)
%   z = fishersTransform(r, n)
%
%   OUTPUT:
%   z:              [ DOUBLES ]
%                   The transformed correlation coefficients in an array that is the exact same size and dimensionality
%                   as the input array. Unlike the Pearson r values, which are bound to [-1, 1], these values are
%                   unbounded and span the entire the real number line.
%
%   INPUTS:
%   r:              [ DOUBLES ]
%                   An array of Pearson product-moment correlation coefficients (r), which here should be the covariance
%                   between two time series normalized to the range [-1, 1]. This array can be any size and any
%                   dimensionality.
%
%   OPTIONAL INPUTS:
%   n:              DOUBLE
%                   The number of degrees of freedom (DOF) of the time series used to generate the correlation
%                   coefficients. For signals whose time points are independent of one another (i.e. raw, unprocessed
%                   signals), this just is the number of elements in the arrays that produced the correlation
%                   coefficients in r. For example, if two vectors X & Y are used to generate a correlation coefficient,
%                   then n is the length of just one of these vectors (the lengths should be equivalent).
%
%                   However, if the signals X & Y were preprocessed in some way prior to estimating the correlation,
%                   then the assumption of independence between time points is likely no longer tenable. Low-pass
%                   filtering, for example, is just one common signal processing step that decreases independence and
%                   therefore lowers the available DOFs. If applicable, n must be corrected against this effect prior to
%                   using this function.
%
%                   This value is used to transform the data such that the output is normalized by the estimate of the
%                   standard error.

%% CHANGELOG
%   Written by Josh Grooms on 20141007



%% Initialize
% Deal with missing inputs
if nargin == 1 || isempty(n)
    n = 4;      % Set n such that values are normalized by '1'
end


%% Transform Correlation Data & Normalize
% Fisher's r-to-z transform
z = atanh(r);

% Normalize by the standard error (or 1 if no normalization is desired)
z = z.*sqrt(n - 3);     % Because standard error of transform is 1/sqrt(N-3)






