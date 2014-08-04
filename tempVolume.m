function tempVolume(data, mask)
% 
% if nargin == 2
%     threshold = 0;
% end
% 

% Mask the data & mark where zeros occur
data(~mask) = 0;

% Deal with very huge & very small values (clear outliers in data histogram)
temp = data(:); temp(temp == 0) = [];
lowerPct = prctile(temp, 1);
upperPct = prctile(temp, 99);
data(data <= lowerPct) = 0;
data(data >= upperPct) = 0;

idsZeros = data == 0;


% Scale the color data to the colormapping & reset zero values
dataRange = [1 256];
% colorData = (data - min(data(:)))./(max(data(:)) - min(data(:)));
colorData = (((dataRange(2) - dataRange(1))*(data - min(data(:))))./(max(data(:)) - min(data(:)))) + dataRange(1);
% colorData = round(colorData);
colorData(idsZeros) = 0;

% 
% surfaceVals = [];
% for a = 1:size(data, 2)
%     for b = 1:size(data, 3)
%         temp = data(:, a, b);
%         temp = temp(temp ~= 0);
%         if ~isempty(temp)
%             if length(temp) == 1
%                 surfaceVals = cat(1, surfaceVals, temp(1));
%             else
%                 surfaceVals = cat(1, surfaceVals, [temp(1); temp(end)]);
%             end
%         end
%     end
% end
% 
% cRange = [min(surfaceVals), max(surfaceVals)];


% data(mask < max(mask(:))) = 0;
% 
% data = smooth3(data, 'gaussian');


% Manual color mapping
numColors = 256;
flipMap = true;
cmap = linspace(0, 0.8, numColors);
cmap = repmat(cmap', [1 3]);

if flipMap
    cmap = flipdim(cmap, 1);
end

figure('Colormap', cmap);

brainSurface = isosurface(data, 5, colorData);

hBrain = patch(brainSurface,...
    'FaceColor', 'interp',...
    'EdgeColor', 'none');
isonormals(data, hBrain);
view(35, 30)
axis tight
daspect([1, 1, 1]);

set(gca, 'Color', [0 0 0]);

set(gcf, 'WindowScrollWheelFcn', @(src, evt) tempSlice(src, evt, data));