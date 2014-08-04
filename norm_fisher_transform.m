function z_norm = norm_fisher_transform(r_in,N)
% NORM_FISHER_TRANSFORM
% Normalized fisher transform, does a fisher transform on data and
% normalizes to a normal distribution with mean zero and standard deviation
% 1, assuming that the two things that were correlated were bivariate
% normal.
%
% Z = norm_fisher_transform(r,N)
% r is the correlation value in [-1 1], N is the number of values that were
% correlated, Z is the output Z score estimate.

% Fisher transform
z_notnorm = atanh(r_in);

% Divide by the standard error to studentize
z_norm = z_notnorm / (1/sqrt(N-3));