function outColors = colorScheme(varargin)
%COLORSCHEME Create a preset color scheme for GUI object, progress bars, colormappings, etc.
% This function creates color schemes in a range of 2D matrix sizes that are especially suited for
% GUI objects, progress bars, and fancy graphics. The function output is a 3D matrix of RGB values
% that can be displayed using "imshow" or "image" directly. A lack of input size specification
% results in a 128x1x3 vector that may be used as a figure colormapping. This function uses a
% name/value input argument specification. 
%
% All inputs are optional and are case insensitive. A complete lack of input will result in a
% 128x1x3 "jet" RGB color vector.
%
%   Syntax:
%   outColors = colorScheme('PropertyName', PropertyValue,...)
%
%   OUTPUT:
%   outColors:                  An array of RGB values. Size depends on user input, but by default
%                               is 128x1x3. Red, green, and blue values are always specified along
%                               the last dimension of the output array. 
%
%   INPUTS: (values in parentheses are optional)
%   ('BrushAngle'):             A number representing the angle in degrees of the brushed metal
%                               effect. Positive angles correspond to counterclockwise rotations
%                               from the x-axis.
%                               DEFAULT: 0                               
%
%   ('BrushEdgeTreatment'):     A string specifying how the motion-blur filter deals with the edges
%                               of images. A value of 'circular' typically produces a shadowing
%                               effect, while the others are not very noticeable.
%                               DEFAULT: 'circular'
%                               OPTIONS:
%                                   'circular'      Out-of-bounds values are the opposite side of
%                                                   the image.
%                                   'symmetric'     Out-of-bounds values are mirror reflections of
%                                                   values across the border.
%                                   'replicate'     Out-of-bounds values have the same value as the
%                                                   nearest in-bounds neighbor.
%
%   ('BrushedEffect'):          Creates a brushed metal effect on the color scheme by adding
%                               Gaussian random noise to the image & motion blurring the result.
%                               Specify this option as either 'on' or 'off'.
%                               DEFAULT: 'off'
%
%   ('Inversion'):              An option to invert the color scheme. This would typically be used
%                               on GUI callbacks for things like button presses, when the user might
%                               want to create the effect of a 3D button push.
%                               WARNING: This has not yet been implemented and is not a usable
%                                        option.
%
%   ('Light'):                  A string representing whether or not to create a lighting effect on
%                               the output color scheme. This typically makes the color scheme
%                               resemble a metalic cylinder, with a light bar reflection on the side
%                               where the light is designated to shine. 
%                               DEFAULT: 'off'
%                               OPTIONS:
%                                   'top' or 'upper' or 'on'
%                                   'middle' or 'center'
%                                   'bottom' or 'lower'
%                                   'none' or 'off'
%
%   ('Size'):                   A two-element vector representing the size of the output color
%                               scheme image. This should be specified as one specifies the size of
%                               a matrix (i.e. [NumRows NumColumns]). The RGB values are always
%                               placed in the third or greater dimension, depending on the input
%                               size.
%                               DEFAULT: [128 1]
%
%   ('Scheme'):                 A string representing the desired scheme of the output image. 
%                               DEFAULT: 'metal'
%                               OPTIONS:
%                                   'bluemetal'
%                                   'chrome'
%                                   'greenmetal'
%                                   'metal'
%                                   'lightmetal'
%                                   'redmetal'
%                                   'yellowmetal'
% 
%
%   Written by Josh Grooms on 20130223
%       20130224:   Added custom colormap generating functions with various color gradients. Also
%                   added a brushed metal effect using random noise and motion blurring. 
%       20130226:   Added a help & reference section.
%       20130603:   Updated help section for consistency with other custom written functions. 

DEPRECATED Colormaps



%% Initialize
% Create a defaults & settings structure
inStruct = struct(...
    'brushAngle', 0,...
    'brushEdgeTreatment', 'circular',...
    'brushedEffect', 'off',...
    'inversion', 'off',...
    'lightAngle', 'center',...
    'sizeScheme', [128, 1],...
    'scheme', 'metal');

% Assign variables, allowing for quick input
if ~isempty(varargin)
    if ~ischar(varargin{1})
        inStruct.sizeScheme = varargin{1};
        inStruct.scheme = varargin{2};
        assignInputs(inStruct, 'varsOnly');
    else
        assignInputs(inStruct, varargin,...
            'compatibility', {'inversion', 'inverted', 'inverse', 'invertscheme';...
                              'lightAngle', 'angle', 'lightDirection', 'light';...
                              'sizeScheme', 'numColors', 'number', 'size';...
                              'scheme', 'colorscheme', 'preset', 'color'});
    end
else
    assignInputs(inStruct, 'varsOnly');
end


%% Create the Color Scheme
% Generate a lighting effect
switch lower(lightAngle)
    case {'top', 'upper', 'on'}
        topSegment = (1/3)*sizeScheme(1);
        
    case {'center', 'middle'}
        topSegment = (1/2)*sizeScheme(1);
        
    case {'bottom', 'lower'}
        topSegment = (2/3)*sizeScheme(1);
    
    case {'none', 'off'}
        topSegment = sizeScheme(1);
end

bottomSegment = sizeScheme(1) - topSegment;

switch lower(scheme)
    case 'metal'
        topPart = lightbone(ceil(topSegment));
        bottomPart = lightbone(floor(bottomSegment));
        
        outColors = [topPart; flipdim(bottomPart, 1)];
    
    case 'chrome'
        topPart = bone(round(topSegment));
        numColorsRemaining = sizeScheme(1) - size(topPart, 1);
        bottomPart = bone(numColorsRemaining);
        outColors = [topPart; flipdim(bottomPart, 1)];
        
    case 'lightmetal'
        topPart = lightgray(ceil(topSegment));
        bottomPart = lightgray(floor(bottomSegment));
        
        outColors = [topPart; flipdim(bottomPart, 1)];
        
    case 'bluemetal'
        topPart = lightblue(ceil(topSegment));
        bottomPart = lightblue(floor(bottomSegment));
        
        outColors = [topPart; flipdim(bottomPart, 1)];
        
    case 'redmetal'
        topPart = lightred(ceil(topSegment));
        bottomPart = lightred(floor(bottomSegment));
        
        outColors = [topPart; flipdim(bottomPart, 1)];
        
    case 'greenmetal'
        topPart = lightgreen(ceil(topSegment));
        bottomPart = lightgreen(floor(bottomSegment));
        
        outColors = [topPart; flipdim(bottomPart, 1)];
        
    case 'yellowmetal'
        topPart = flame(ceil(topSegment));
        bottomPart = flame(floor(bottomSegment));
        
        outColors = [topPart; flipdim(bottomPart, 1)];
end
    

%% Resize the Color Scheme
if numel(sizeScheme) == 2
    % A 2D array of the color scheme is desired, so put components in the 3rd dimension
    outColors = reshape(outColors, [sizeScheme(1), 1, 3]);
    outColors = repmat(outColors, [1, sizeScheme(2), 1]);
elseif numel(sizeScheme) == 3
    % A 3D array is desired, so put components in the 4th dimension
    outColors = reshape(outColors, [sizeScheme(1), 1, 1, 3]);
    outColors = repmat(outColors, [1, sizeScheme(2), sizeScheme(3), 3]);
end


%% Add Effects
if strcmpi(brushedEffect, 'on')
    szColors = size(outColors);
    rNoise = randi(50, szColors(1:2));
    rNoise = rNoise + 25;
    rNoise = rNoise./max(rNoise(:));
    rNoise = repmat(rNoise, [1 1 3]);
    outColors = outColors + rNoise;
    outColors = outColors./max(outColors(:));
    
    brushFilter = fspecial('motion', round((1/4)*size(outColors, 2)), brushAngle);
    outColors = imfilter(outColors, brushFilter, brushEdgeTreatment, 'same');
end


end


%% Nested Functions
% Lighter gray color mapping
function colors = lightgray(numColors)
r = linspace(0.35, 0.85, numColors);
colors = [r' r' r'];
end

% Lighter blue color mapping
function colors = lightblue(numColors)
bClimb = linspace(0.85, 1, round(0.4*numColors));
b = [bClimb ones(1, numColors - length(bClimb))]';
g = linspace(0.4, 0.9, numColors)';
r = (linspace(0, 0.45, numColors))';
colors = [r g b];
end

% Fire-like orange & yellow color mapping
function colors = flame(numColors)
colors = fliplr(lightblue(numColors));
end

function colors = lightred(numColors)
rClimb = linspace(0.75, 1, round(0.4*numColors));
r = [rClimb ones(1, numColors - length(rClimb))]';
g = linspace(0, 0.7, numColors)';
b = linspace(0, 0.7, numColors)';
colors = [r g b];
end

% Lighter bone color mapping
function colors = lightbone(numColors)
colors = (7*lightgray(numColors) + lightblue(numColors))/8;
end

% Lighter green colormapping
function colors = lightgreen(numColors)
gClimb = linspace(0.85, 1, round(0.4*numColors));
g = [gClimb ones(1, numColors - length(gClimb))]';
r = linspace(0, 0.5, numColors)';
b = linspace(0, 0.5, numColors)';
colors = [r g b];
end
