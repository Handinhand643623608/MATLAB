% CCORRP - Estimates the cross-correlation function between data sets for execution time profiling.

%% CHANGELOG
%	Written by Josh Grooms on 20150131



%% Function Definition
function [cc, lags] = ccorrp(x, y, maxlag, funOpt)

	 % Check for errors in the X data argumment
    assert(~isempty(x), 'X cannot be an empty array.');
    assert(ismatrix(x), 'X must be a vector or two-dimensional array.');
    
    % Fill in any missing inputs & error check Y
    if nargin < 2;	y = x;                      end
    if nargin < 3;  maxlag = size(x, 1) - 1;    end
    if isempty(y);	y = x;                      end
    
    assert(ismatrix(y), 'Y must be a vector or a two-dimensional array.');

    % X & Y cannot have NaNs
    hasNaN = any(isnan(x(:))) || any(isnan(y(:)));
	assert(~hasNaN,...
        'NaNs were detected in one or more inputted data sets. These must be removed or replaced before invoking this function.');
    
    % Flatten vectors
    if isvector(x); x = x(:); end
    if isvector(y); y = y(:); end
    szx = size(x);
    szy = size(y);
    
    % Constrain the size of X & Y
    assert(szx(1) == szy(1), 'X and Y must always contain the same number of rows.');
    if (szx(2) ~= 1 && szy(2) ~= 1)
        assert(szx(2) == szy(2), 'When X and Y are matrices, they must both contain the same number of columns.');
    end
    
    % Cross correlate the data
    if (szx(2) == 1 && szy(2) ~= 1)
        if (funOpt == 1)
            cc = flip(MexCrossCorrelate(y, x));
        else
            cc = flip(axcorrcp(y, x));
        end
    else
        if (funOpt == 1)
            cc = MexCrossCorrelate(x, y);
        else
            cc = axcorrcp(x, y);
        end
    end
        
    % Remove unwanted shifts
    allLags = -(szx(1) - 1) : (szx(1) - 1);
    lags = -maxlag : maxlag;
    idsLagsToKeep = ismember(allLags, lags);
    cc = cc(idsLagsToKeep, :);
	
end