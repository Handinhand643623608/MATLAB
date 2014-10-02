function r = corr3(a, b)
% CORR3 - Calculates the Pearson correlation coefficient between two volume arrays.
%   This function calculates the correlation coefficient in exactly the same way as other builtin MATLAB functions do,
%   but differs from those by accepting volumetric arrays. If one- or two-dimensional arrays are to be used, those
%   builtin functions must be used instead. Attempting to input them to this function will result in errors.
%
%   SYNTAX:
%   r = corr3(a, b)
%
%   OUTPUT:
%   r:      DOUBLE
%           The Pearson product-moment correlation coefficient between the two inputted volumetric arrays.
%
%   INPUTS:
%   a:      [ 3D DOUBLE ]
%           A volumetric (three-dimensional) array of double-precision numbers. This array can be any size over each of
%           its dimensions.
%
%   b:      [ 3D DOUBLE ]
%           A second volumetric array of double-precision numbers. This array must be exactly the same size as the other
%           inputted 3D array.
%
% See also CORR, CORR2, CORRCOEF

%% CHANGELOG
%   Written by Josh Grooms on 20141001



%% Volume Correlation
% Check for dimensionality mismatches
if (ndims(a) ~= 3 || ndims(b) || 3); error('Inputted arrays must be 3-dimensional only.'); end
if (any(size(a) ~= size(b))); error('Inputted volume arrays must be identical in size'); end

% Ensure that everything is double-precision
a = double(a);
b = double(b);

% Center the data about zero
a = a - mean(a(:));
b = b - mean(b(:));

% Compute some quantities for coefficient calculation
ab = a.*b;
a2 = a.*a;
b2 = b.*b;

% Compute the 3D Pearson correlation coefficient
r = sum(ab(:)) / sqrt(sum(a2(:)) * sum(b2(:)));
