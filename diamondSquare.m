% Prototyping an implementation of the diamond-square terrain generation algorithm for the Tesseract game engine in C#

maxHeight = 50;
mountainousness = 1;
roughness = 0.1;
numPoints = 128;
heightMap = zeros(numPoints+1, numPoints+1);


numIterations = log2(numPoints);

for a = 1:numIterations

    wholeStep = numPoints/2^(a-1);
    halfStep = wholeStep/2;
    
    currentRoughness = mountainousness*maxHeight/2^(a-1);
    if a > 3; currentRoughness = currentRoughness*roughness; end;
    
    % Square step
    for b = halfStep+1:wholeStep:numPoints+1
        for c = halfStep+1:wholeStep:numPoints+1
            
            leftUpper = heightMap(b-halfStep, c-halfStep);
            rightUpper = heightMap(b-halfStep, c+halfStep);
            leftLower = heightMap(b+halfStep, c-halfStep);
            rightLower = heightMap(b+halfStep, c+halfStep);
            
            heightMap(b, c) = mean([leftUpper rightUpper leftLower rightLower]);
            heightMap(b, c) = heightMap(b, c) + (rand(1)*currentRoughness - (currentRoughness/2));
        end
    end
    
    % Diamond step
    startMiddleHorizontal = true;
    for b = 1:halfStep:numPoints+1
        idxPrevVert = b-halfStep;
        idxNextVert = b+halfStep;
        if startMiddleHorizontal; idxHorizontalStart = halfStep+1; else idxHorizontalStart = 1;end;
        startMiddleHorizontal = ~startMiddleHorizontal;
        
        for c = idxHorizontalStart:wholeStep:numPoints+1
            idxPrevHorz = c-halfStep;
            idxNextHorz = c+halfStep;
            
            numSamples = 4;
            
            if idxPrevVert < 1; lower = NaN; else lower = heightMap(idxPrevVert, c); end;
            if idxNextVert > numPoints+1; upper = NaN; else upper = heightMap(idxNextVert, c); end;
            if idxPrevHorz < 1; left = NaN; else left = heightMap(b, idxPrevHorz); end;
            if idxNextHorz > numPoints+1; right = NaN; else right = heightMap(b, idxNextHorz); end;
            
            heightMap(b, c) = nanmean([upper left right lower]);
            heightMap(b, c) = heightMap(b, c) + (rand(1)*currentRoughness - (currentRoughness/2));
        end
    end
    
    figure; surf(heightMap)
end
%            
% figure;
% surf(heightMap);
    
 


