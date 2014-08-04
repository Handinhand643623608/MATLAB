function [map, x, y] = fc_2D_manual_seed(I, mn, s, s_shift)     %input image and mean image as inputs
% FC_2D_MANUAL_SEED
% 2D Functional connectivity modified to allow any signal specified as the
% seed, and any shift of that signal
%
% [map, x, y] = fc_2D_manual_seed(I,        2D + Time
%                                 mn,       Mean image
%                                 s,        Signal to use as seed signal
%                                 s_shift   Time shift for seed signal
%                                 )         



% Make sure s is along the first dimension
s = reshape(s,[numel(s) 1]);

% Shift s by s_shift using zero padding
s = cat(1,zeros(-s_shift,1),s,zeros(s_shift,1));
I = cat(3,zeros(size(I,1),size(I,2),s_shift),I,zeros(size(I,1),size(I,2),-s_shift));

% Use a specified time course instead of calculating the seed
s = detrend_wm(s, 2);

seed = s;



%mn = normalize_(mn);
msk = mn > 0.2;

map = nan(size(mn));


sz = size(I);

for k = 1:sz(1)
    for l = 1:sz(2)
        if ~msk(k, l)
            continue;
        end 
        map(k, l) = ncc(seed, squeeze(I(k, l, :)));
    end
end

%map (abs(map) < 0.2) = nan;

% mn = gray2rgb(mn);
% mn(x(1)-N:x(1)+N, y(1)-N:y(1)+N, [2, 3]) = 0;
% mn(x(1)-N:x(1)+N, y(1)-N:y(1)+N, [1]) = 0.8;
% figure; imshow(mn, [], 'initialmagnification', 400);
% 
% 
a = [];
%a =  [-0.8*ones(1, sz(2)/2), 1*ones(1, sz(2)/2)];

% Eliminate the part that isn't NaN
map(isnan(map)) = 0;

