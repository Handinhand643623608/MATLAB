function Y = detrend_wm(X, order, t_msk)  %time is the last dimension

orig_dim = size(X);

X = squeeze(X);


switch ndims (X)
    case 2          %when we have a single signal or a 2D matrix, with each signal along columns
        
        %%in case of 1D array, make time the second dimension
        if(min (size(X)) == 1 )
            X = reshape(X, [1 length(X)]);
        end
        
        dim = size(X);
        Y = zeros(dim);
        
        t = 1:dim(2);
        if nargin < 3
            t_msk = ones(size(t));
        end
        
        for k = 1:dim(1)
        
            p = polyfit(t(t_msk > 0), X(k, t_msk>0), order);
            Y(k, :) = X(k, :) - polyval(p, t);%+mean(polyval(p, t));
        end
          
        
end


Y = reshape(Y, orig_dim);