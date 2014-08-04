function y = combine_3Dto2D (X, n_columns)


sz = size(X);

if size(sz) < 3
    y = X;
    return;
end

n_rows = ceil(sz(3) / n_columns);

%n_rows;
%n_columns;
y = zeros(n_rows*sz(1), n_columns*sz(2));
%size(y)

k = 1;

for l = 1:n_rows
    for m = 1:n_columns
        
        y( (l-1)*sz(1)+1:(l-1)*sz(1)+sz(1), (m-1)*sz(2)+1:(m-1)*sz(2)+sz(2) ) = X(:, :, k);
        k = k+1;
       
        if k > sz(3)
            break;
        end
       
    end
end



%imshow(y, []);