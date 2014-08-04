clear all
clc



blueRGB = zeros(500, 500, 3);
blueRGB(:, :, 1) = 0.5;
blueRGB(:, :, 2) = 0.5;
blueRGB(:, :, 3) = 1;

% figure; 
% image(blueRGB)
% title('Original Light Blue RGB');


% cStruct = makecform('srgb2lab');
% blueLAB = applycform(blueRGB, cStruct);

%% Phong Reflectance Model
is = [0.5 0.5 1];                           % Specular intensity
ia = [0.5 0.5 1];                           % Ambient intensity
id = [0.5 0.5 1];                           % Diffuse intensity
attCoeff = 0.75;                            % Attenuation coefficient
lightColor = [1 1 1];

ks = 1;                                     % specular reflection constant
kd = 0.2;                                   % diffuse reflection constant
ka = 0.5;                                   % ambient reflection constant
alpha = 15;                                 % shininess constant

theta = 0:(pi/(size(blueRGB, 1)-1)):pi;                       % angle set of hemisphere
surfaceNorm = [cos(theta); sin(theta)];     % define the circle & surface normal point-by-point

lightAngle = pi/2;                          % direction of light source
lightDistance = 10;                         % radial distance of light source from hemisphere center
lightCart = [lightDistance*cos(lightAngle); lightDistance*sin(lightAngle)];

dirToLight = zeros(2, size(surfaceNorm, 2));
for i = 1:size(surfaceNorm, 2)
    currentNorm = surfaceNorm(:, i);
    currentDirToLight = currentNorm - lightCart;
    dirToLight(:, i) = norm(currentDirToLight);
end

reflectDot = 2.*(dot(dirToLight, surfaceNorm, 1));
reflectVec = zeros(size(surfaceNorm));
for i = 1:length(reflectDot)
    reflectVec(:, i) = reflectDot(i).*(surfaceNorm(:, i)) - dirToLight(:, i);
end
viewAngle = pi/2;
viewDistance = 10;
viewCart = [viewDistance*cos(viewAngle); viewDistance*sin(viewAngle)];

dirToViewer = zeros(size(surfaceNorm));
for i = 1:size(surfaceNorm, 2)
    currentNorm = surfaceNorm(:, i);
    currentDirToViewer = currentNorm - viewCart;
    dirToViewer(:, i) = norm(currentDirToViewer);
end

pixelLine = zeros([size(blueRGB, 1), 1, 3]);
for i = 1:size(blueRGB, 3)
    ambTerm = ka*ia(i)*id(i);
    diffTerm = attCoeff*lightColor(i)*kd*id(i)*dot(dirToLight, surfaceNorm, 1);
    specTerm = attCoeff*lightColor(i)*ks*is(i)*dot(reflectVec, dirToViewer).^alpha;
    pixelLine(:, 1, i) = ambTerm + diffTerm + specTerm;
end
% 
% testDiff = diffTerm;
% testDiff(testDiff < 0) = 0;
% 
% testSpec = specTerm;
% testSpec(testSpec < 0) = 0;
% 
% 
% pixelLine = ambTerm + testDiff + testSpec;
pixelIMG = repmat(pixelLine, [1, size(blueRGB, 2), 1]);
% pixelMat = pixelMat./max(pixelMat(:));
% pixelIMG = zeros(size(blueRGB));
% pixelIMG(:, :, 3) = pixelMat;

% for i = 1:size(blueRGB, 3)
%     blueRGB(:, :, i) = blueRGB(:, :, i).*pixelMat;
% end

% blueRGB = 255.*blueRGB;
% figure; imshow(blueRGB)

figure; image(pixelIMG)
   