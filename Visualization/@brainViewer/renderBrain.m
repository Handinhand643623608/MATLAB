function renderBrain(brainData, varargin)
%RENDERBRAIN
%
%
%   Written by Josh Grooms on 20131208


%% Initialize
% Pull data from the data object
volumeData = brainData.Data.Anatomical;
colorData = brainData.Data.Color;
rotAxis = brainData.Parameters.RotationAxis;
rotAlpha = brainData.Parameters.RotationAlpha;

% Permute data to the correct orientation
volumeData = permute(volumeData, brainData.Parameters.PermutationOrder);
colorData = permute(colorData, brainData.Parameters.PermutationOrder);


%% Generate a 3D Brain Rendering
% Generate full isosurface & isocap data
brainSurface = isosurface(volumeData, brainData.IsoValue, colorData, 'noshare');
brainCap = brainData.Data.Cap(brainData.SlicePosition);

% Invert vertex color data (not clear how these are being calculated, but this works)
cmap = get(brainData.FigureHandle, 'Colormap');
numColors = size(cmap, 1);
cData = brainSurface.facevertexcdata;
cData = -(cData - 0.75) + 0.75;
cDataRGB = scale2rgb(cData, 'Colormap', cmap);
brainSurface.facevertexcdata = cDataRGB;

% Generate the brain model
brainHandle = patch(brainSurface,...
    'AlphaDataMapping', 'none',...
    'EdgeColor', 'none',...
    'FaceColor', 'interp',...
    'Parent', brainData.Axes);
capHandle = patch(brainCap,...
    'EdgeColor', 'none',...
    'FaceColor', 'interp',...
    'Parent', brainData.Axes);
isonormals(volumeData, brainHandle);

% Rotate the surface patch to the common orientation
for a = 1:size(rotAxis, 1)
    rotate(brainHandle, rotAxis(a, :), rotAlpha(a));
end

% Center model in the axes limits
vertexData = get(brainHandle, 'Vertices');
rangeData  = max(vertexData) - min(vertexData);
axesLims = [get(brainData.Axes, 'XLim') get(brainData.Axes, 'YLim') get(brainData.Axes, 'ZLim')];
diffPos = (axesLims(2:2:end) - rangeData)./2 - min(vertexData);
for a = 1:length(diffPos)
    vertexData(:, a) = vertexData(:, a) + diffPos(a);
end
set(brainHandle, 'Vertices', vertexData);


%% Store Data in the Data Object
brainData.Patches = struct(...
    'Adjustments', diffPos,...
    'Cap', capHandle,...
    'Surface', brainHandle);
brainData.Data.Surface = struct(...
    'faces', get(brainHandle, 'Faces'),...
    'facevertexcdata', get(brainHandle, 'FaceVertexCData'),...
    'vertices', get(brainHandle, 'Vertices'));
