% ISAPPROX - Estimates whether or not one array is approximately numerically equal to another.
%
%   SYNTAX:
%       b = isapprox(x, y)
%       b = isapprox(x, y, format)
%
%   OUTPUT:
%       b:          BOOLEAN
%                   A Boolean indicating whether or not the two inputs are approximately equal.
%
%   INPUTS:
%       x:          DOUBLE or [ DOUBLES ]
%                   A number or array of numbers.
%
%       y:          DOUBLE or [ DOUBLES ]
%                   A second number or array of numbers. Note that if the size of Y does not equal the size of X, the result
%                   will always be false.
%
%       format:     STRING
%                   The format string dictating how precise the approximation should be. The is the same formatting argument
%                   that is inputted to the function SIGFIG to control the number of significant figures present after a
%                   rounding operation. Consult the documentation of that function for more details on this parameter. The
%                   default value of FORMAT tests the equality between numbers at 5 significant decimal places.
%                   DEFAULT: '0.00000'
%
% See also: EPS, EQ, ISEQUAL, SIGFIG

%% CHANGELOG
%   Written by Josh Grooms on 20150131
%		20150210:	Implemented error checks for the presence of NaNs. These always result in false equality checks, even
%					when two NaNs are compared with one another.



%% FUNCTION DEFINITION
function b = isapprox(x, y, format)
    if (nargin < 3) || isempty(format); format = '0.00000'; end
    assert(~any(isnan(x(:))), 'NaNs detected in X. These break equality comparisons and cannot be present in the inputs.');
	assert(~any(isnan(y(:))), 'NaNs detected in Y. These break equality comparisons and cannot be present in the inputs.');
    xr = sigfig(x, format, 'round');
    yr = sigfig(y, format, 'round');
    b = isequal(xr, yr);
end