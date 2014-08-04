function fuseImages(brainData)

if ~isempty(brainData.Data.Functional)
    if isempty(brainData.Parameters.Threshold)
        brainData.Parameters.Threshold = [0 0];
    end
    
    % Pull data from the data object
    functionalData = brainData.Data.Functional;
    threshold = brainData.Parameters.Threshold;
    vertexData = get(brainData.Patches.Surface, 'Vertices');
    cData = get(brainData.Patches.Surface, 'FaceVertexCData');
    
    % Perform a simple affine registration of anatomical & functional images
%     [optimizer, metric] = imregconfig('multimodal');
%     functionalData = imregister(functionalData, brainData.Data.Anatomical, 'affine', optimizer, metric);    
    
    % Permute the data (because of the way MATLAB draws images)
    functionalData = permute(functionalData, [2 1 3]);
    
    % Convert scalar data to RGB values
    rgbData = scale2rgb(functionalData, 'Colormap', jet(256), 'CLim', [-3 3]);
    functionalData(functionalData >= threshold(1) & functionalData <= threshold(2)) = 0;
    functionalData(isnan(functionalData)) = 0;

    % Replace anatomical surface color values with corresponding functional ones
%     progbar = progress('Fusing Functional & Surface Anatomical Data', 'fast');
    progbar = progress('Fusing Functional & Surface Anatomical Data');
    for a = 1:size(vertexData, 1)
        currentVert = round(vertexData(a, :));

        if currentVert(1) <= size(functionalData, 1) && currentVert(2) <= size(functionalData, 2) && currentVert(3) <= size(functionalData, 3)
            if functionalData(currentVert(1), currentVert(2), currentVert(3)) ~= 0
                currentRGB = squeeze(rgbData(currentVert(1), currentVert(2), currentVert(3), :))';
                cData(a, :) = currentRGB;
            end
        end
%         update(progbar, a/size(vertexData, 1));
    end
    set(brainData.Patches.Surface, 'FaceVertexCData', cData);
    brainData.Data.Surface.facevertexcdata = cData;
    update(progbar, 0.5);
    

    % Replace anatomical cap color values with corresponding functional ones
    reset(progbar);
    progbar.BarTitle = 'Fusing Functional & Slice Anatomical Data';
    for a = 1:length(brainData.Data.Cap)
        vertexData = brainData.Data.Cap(a).vertices;
        cData = brainData.Data.Cap(a).facevertexcdata;

        for b = 1:size(vertexData, 1)
            currentVert = round(vertexData(b, :));

            if currentVert(1) <= size(functionalData, 1) && currentVert(2) <= size(functionalData, 2) && currentVert(3) <= size(functionalData, 3)
                if functionalData(currentVert(1), currentVert(2), currentVert(3)) ~= 0
                    currentRGB = squeeze(rgbData(currentVert(1), currentVert(2), currentVert(3), :))';
                    cData(b, :) = currentRGB;
                end
            end
        end
        brainData.Data.Cap(a).facevertexcdata = cData;
%         update(progbar, a/ length(brainData.Data.Cap));
    end
    update(progbar, 1)
    close(progbar);
end