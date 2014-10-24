function updateRender(brainData)
%UPDATERENDER
%
%   Written by Josh Grooms on 20131208


%% Initialize
% Pull data from the data object
sliceNum = brainData.SlicePosition;
rotAxis = brainData.Parameters.RotationAxis;
rotAlpha = brainData.Parameters.RotationAlpha;
adjVec = brainData.Patches.Adjustments;
cDataPoints = brainData.Parameters.CDataPoints;
facePoints = brainData.Parameters.FacePoints;
vertexPoints = brainData.Parameters.VertexPoints;


%% Update an Existing Rendering as it's Sliced
% Add or remove surface data as the volume is being sliced
brainHandle = brainData.Patches.Surface;
set(brainHandle,...
    'Faces', brainData.Data.Surface.faces(1:facePoints(sliceNum), :),...
    'FaceVertexCData', brainData.Data.Surface.facevertexcdata(1:cDataPoints(sliceNum), :),...
    'Vertices', brainData.Data.Surface.vertices(1:vertexPoints(sliceNum), :));

% Delete & recalculate isocap data
capHandle = brainData.Patches.Cap;
set(capHandle,...
    'Faces', brainData.Data.Cap(sliceNum).faces,...
    'FaceVertexCData', brainData.Data.Cap(sliceNum).facevertexcdata,...
    'Vertices', brainData.Data.Cap(sliceNum).vertices);

% Rotate & translate the isocap to align with the brain surface rendering
if ~isempty(get(brainData.Patches.Cap, 'Vertices'))
    for a = 1:size(rotAxis, 1)
        rotate(brainData.Patches.Cap, rotAxis(a, :), rotAlpha(a));
    end
    vertexData = get(brainData.Patches.Cap, 'Vertices');
    for a = 1:length(adjVec)
        vertexData(:, a) = vertexData(:, a) + adjVec(a);
    end
    set(brainData.Patches.Cap, 'Vertices', vertexData);
end
drawnow