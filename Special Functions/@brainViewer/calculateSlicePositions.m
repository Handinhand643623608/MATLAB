function calculateSlicePositions(brainData)
%CALCULATESLICEPOSITIONS
%
%   Written by Josh Grooms on 20131208


%% Initialize
% Pull data parameters from the data object
assignInputs(brainData.Parameters, 'varsOnly');

% Initialize slice position file names
viewerPath = fileparts(which('brainViewer.m'));
pointsFile = [viewerPath '/patchPoints' brainData.SlicePlane brainData.AnatomicalBrain '.mat'];

% Permute volumetric & color data to slice correctly
volumeData = brainData.Data.Anatomical;
colorData = brainData.Data.Color;
volumeData = permute(volumeData, PermutationOrder);
colorData = permute(colorData, PermutationOrder);


%% Determine Slice Positions within Patch Objects
if exist(pointsFile, 'file')
    load(pointsFile);
else
    % Initialize slice position vectors
    cDataPoints = zeros(1, size(volumeData, 3));
    facePoints = zeros(1, size(volumeData, 3));
    vertexPoints = zeros(1, size(volumeData, 3));

    % Fill in position vectors by rendering slices individually (slow)
    progbar = progress('Calculating Slice Positions in Patch Data');
    for a = 2:size(volumeData, 3);
        % Generate isosurface data
        brainSurface = isosurface(volumeData(:, :, 1:a), brainData.IsoValue, colorData(:, :, 1:a), 'noshare');
        if isfield(brainSurface, 'facevertexcdata')
            cDataPoints(a) = size(brainSurface.facevertexcdata, 1);
        end
        facePoints(a) = size(brainSurface.faces, 1);
        vertexPoints(a) = size(brainSurface.vertices, 1);
        
        % Generate isocap data
        brainCap(a) = isocaps(volumeData(:, :, 1:a), brainData.IsoValue);
        if ~isempty(brainCap(a).facevertexcdata)
            brainCap(a).facevertexcdata = scale2rgb(brainCap(a).facevertexcdata, 'Colormap', get(brainData, 'Colormap'));
        end
        
        update(progbar, a/size(volumeData, 3));
    end
    close(progbar);
    
    % Determine the range of brain slices
    hasCData = zeros(1, length(brainCap));
    for a = 1:length(brainCap)
        hasCData(a) = ~isempty(brainCap(a).facevertexcdata);
    end
    sliceRange = find(hasCData, 1, 'first'):find(hasCData, 1, 'last')+1;

    % Permanently store the slice position vectors to prevent having to repeat this step
    save(pointsFile, 'brainCap', 'cDataPoints', 'facePoints', 'sliceRange', 'vertexPoints');
end


%% Store Data in the Data Object
brainData.SlicePosition = sliceRange(end);
brainData.Data.Cap = brainCap;
brainData.Parameters = addfield(brainData.Parameters,...
    'CDataPoints', cDataPoints,...
    'FacePoints', facePoints,...
    'SliceRange', sliceRange,...
    'VertexPoints', vertexPoints);
