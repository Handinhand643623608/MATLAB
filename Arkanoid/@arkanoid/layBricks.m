function layBricks(arkData, varargin)
%LAYBRICKS Generates the brick layout for the game.
%   This function generates the brick layout and stores it as an array within the Arkanoid game
%   object.
%
%   Syntax:
%   layBricks(arkData)
%
%   INPUTS:
%   arkData:    The Arkanoid game object.
%
%   Written by Josh Grooms on 20130516
%       20130521:   Implemented better brick textures from Photoshop. Implemented additional levels.
%       20130522:   Implemented the unbreakable diamond block
%       20150824:   Updated for compatibility with cumulative changes to file and folder management code over the last year.
%                   Also updated for compatibility with Unix file systems.


%% Construct an Array of Brick Objects
% Initialize important variables
brickDir = strrep(which('brick/brick'), '/brick.m', '');
% textures = fileData([brickDir '/Textures']);
textures = contents([brickDir '/Textures']);

% Get the current level & layout
brickArray = level(eval(get(arkData.Level, 'String')));
szArray = size(brickArray);

% Calculate the size of individual bricks
szBrick = [1/szArray(2) 1/szArray(1)];

% Calculate positions of individual bricks
xPositions = [0 cumsum(repmat(szBrick(1), [1, szArray(2)]))];
yPositions = 1 - cumsum(repmat(szBrick(2), [szArray(1), 1]));

% Generate the layout
for a = 1:szArray(1)
    for b = 1:szArray(2)
        if brickArray(a, b) ~= 0
            % Load the brick texture
            ctTexture = textures{brickArray(a, b)};
            [~, ctTextureName, ~] = fileparts(ctTexture);
            currentTexture = flipdim(imread(ctTexture), 1);

            % Assign brick hardness
            if strcmpi(ctTextureName, 'stone.tif');
                currentHardness = 2;
            elseif strcmpi(ctTextureName, 'diamond.tif');
                currentHardness = inf;
            else
                currentHardness = 1;
            end

            % Create a layout of brick objects
            currentPosition = [xPositions(b) yPositions(a)];
            tempBricks(a, b) = brick(arkData,...
                'Hardness',     currentHardness,...
                'Position',     currentPosition,...
                'Size',         szBrick,...
                'Texture',      currentTexture);
        else
            currentPosition = [xPositions(b) yPositions(a)];
            tempBricks(a, b) = brick(arkData,...
                'Destroyed',    true,...
                'Position',     currentPosition,...
                'Size',         szBrick);
        end
    end
end

% Transfer objects into the game object
tempBricks = flipdim(tempBricks', 2);
arkData.Bricks = tempBricks;
