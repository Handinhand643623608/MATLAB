
load mniBrainHD

brainEdge = zeros(size(mniBrain));
h = 'sobel';
s = strel('disk', 2, 0);

for a = 1:size(brainEdge, 3)
    brainEdge(:, :, a) = edge(mniBrain(:, :, a), h);
    brainEdge(:, :, a) = imclose(brainEdge(:, :, a), s);
end

figure;
imshow(brainEdge(:, :, 214), []);

test = imclose(brainEdge, s);

test2 = imfill(test, 'holes');




figure; 
imshow(test(:, :, 214), []);

figure;
imshow(test2(:, :, 214), []);


%%
load mniBrainHD

test = mniBrain;
clear mniBrain

test(test < 50) = 0;

test = imresize(test, [91, 109], 'nearest');
test = permute(test, [3 1 2]);
test = imresize(test, [91 91], 'nearest');
test = permute(test, [2 3 1]);

mniBrain = test;
save('C:\Users\Josh\Dropbox\Globals\MNI\Anatomical Brains\mniBrainHD3.mat');


%% 
load mniBrainHD2

numColors = 3;

% Discretize the data
minData = min(mniBrain(:));
maxData = max(mniBrain(:));
discmni = round((numColors - 1)*(mniBrain - minData)/(maxData - minData));

figure;
imshow(discmni(:, :, 45), [])

figure; imshow(mniBrain(:, :, 45), []);

test = mniBrain;
test(~discmni) = 0;

figure;
imshow(test(:, :, 45), [])
