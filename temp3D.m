load colinBrain
load colinMask

colinBrain = double(colinBrain);
colinMask = boolean(colinMask);

structEl = strel('disk', 6, 0);
colinMask = imerode(colinMask, structEl);
% 
% 
% tempMask = colinMask(:, :, 55:end);
% structEl = strel('disk', 6, 0);
% tempMask = imerode(tempMask, structEl);
% colinMask(:, :, 55:end) = tempMask;
% 
% structEl = strel('disk', 4, 0);
% tempMask = imdilate(tempMask, structEl);
% colinMask(:, :, 55:end) = tempMask;
% 
% 
% tempMask = colinMask(:, :, 1:54);
% structEl = strel('disk', 2, 0);
% tempMask = imerode(tempMask, structEl);
% colinMask(:, :, 1:54) = tempMask;




% structEl = strel('disk', 2, 0);
% colinMask = imerode(colinMask, structEl);
% 
% structEl = strel('disk', 4, 0);
% colinMask = imerode(colinMask, structEl);
% structEl = strel('disk', 1, 0);
% colinMask = imdilate(colinMask, structEl);

% for a = 7:-1:6
%     structEl = strel('disk', a, 0);
%     colinMask = imerode(colinMask, structEl);
% %     structEl = strel('disk', a-1, 0);
% %     colinMask = imdilate(colinMask, structEl);
% end

% for a = 10:-2:2
%     structEl = strel('disk', a, 0);
%     colinMask = imclose(colinMask, structEl);
%     colinMask = imopen(colinMask, structEl);
%     colinMask = imerode(colinMask, structEl);
% end

% colinMask = imdilate(colinMask, structEl);
% % colinMask = imopen(colinMask, structEl);
% % colinMask = imclose(colinMask, structEl);

tempVolume(colinBrain, colinMask)


%% 1423 - Import the Colin Brain Mask
colinMask = load_nii('C:\Users\Josh\Dropbox\Globals\MNI\Colin Brain\colin27_t1_tal_lin_mask.nii');
colinMask = colinMask.img;

colinMask = imresize(colinMask, [91 109]);
colinMask = permute(colinMask, [3 1 2]);
colinMask = imresize(colinMask, [91 91]);
colinMask = permute(colinMask, [2 3 1]);

save(['C:\Users\Josh\Dropbox\Globals\MNI\Colin Brain\colinMask.mat'], 'colinMask');



%%
load colinBrain
load colinMask

colinBrain = double(colinBrain);
colinMask = boolean(colinMask);

structEl = strel('disk', 6, 0);
colinMask = imerode(colinMask, structEl);
colinBrain(~colinMask) = 0;

idsZ = colinBrain ~= 0;

x = zeros(1, 91*91);
idsX = 1:91:length(x);
for a = 1:91:length(x)
    x(a:a+90) = find(idsX == a);
end

y = zeros(1, 109*109);
idsY = 1:109:length(y);
for a = idsY
    y(a:a+108) = find(idsY == a);
end
y = y';

x = repmat(x, [size(y, 1) 1]);
y = repmat(y, [1, size(x, 2)]);

z = zeros(size(x));

tz = 1;
for a = 1:numel(z)
    tx = x(a); ty = y(a); 
    
    if idsZ(tx, ty, tz)
        z(a) = tz;
    end
    
    if tz == 91
        tz = 1;
    end
end


