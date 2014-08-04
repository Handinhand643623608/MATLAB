classdef brick < hgsetget
    %BRICK A brick object to be used in the Arkanoid game.
    %   This object contains the properties necessary to construct a single brick in the game.
    %   Properties are included for later development such as powerups and hardness. The image of
    %   the brick in the game is generated during this object's construction. 
    %
    %   WARNING: This game object is still under core development
    %
    %   Syntax:
    %   brickData = brick(arkData, 'PropertyName', PropertyValue,...)
    %
    %   OUTPUTS:
    %   brickData:      A single brick object containing all properties about the brick being
    %                   displayed in the game.
    %
    %   INPUTS:
    %   arkData:        The Arkanoid game object. Needed for plotting images to the correct axes.
    %
    %   Written by Josh Grooms on 20130516
    %       20130521:   Implemented a function to generate a boolean map of brick locations.
    %                   Implemented better texturing from Photoshop.
    %       20130522:   Implemented the unbreakable diamond block
    %       20130814:   Began implementation of powerups.
    
    % TODO: Implement more brick colors
    
    
    properties (SetObservable, AbortSet)
        
        Destroyed = false       % Boolean indicating whether the brick has been destroyed
        Powerup                 % A powerup to be dropped for collection by the paddle (not yet implemented)
        Hardness = 1            % Scalar indicating how many times brick has to be hit to be destroyed
        Listeners               % Listener handles for property changes
        Position                % Lower left corner position of brick
        Size                    % Width & height of the brick
        Texture                 % An image object plotted to the axes showing the physical form of the brick
        
    end
    
    %% Constructor Method
    methods        
        function brickData = brick(arkData, varargin)
            %BRICK Constructs a single brick object for use in the Arkanoid game.
            
            if nargin ~= 0
                % Initialize
                inStruct = struct(...
                    'Destroyed', false,...
                    'Hardness', 1,...
                    'Position', [],...
                    'Size', [],...
                    'Texture', []);
                assignInputs(inStruct, varargin, 'structOnly');                        

                % Create a texture for the brick            
                if ~inStruct.Destroyed
                    inStruct.Texture = image(...
                        [inStruct.Position(1), inStruct.Position(1)+inStruct.Size(1)],...
                        [inStruct.Position(2), inStruct.Position(2)+inStruct.Size(2)],...
                        inStruct.Texture,...
                        'Parent', arkData.Axes);
                    clear temp*
                end
                
                % Randomly place powerups
                if rand(1) > 0.8
                    inStruct.Powerup = powerup;
                end
                
                % Assign properties to the object
                propNames = fieldnames(inStruct);
                for a = 1:length(propNames)
                    brickData.(propNames{a}) = inStruct.(propNames{a});
                end
                
                % Add listeners for hardness to destroy the brick
                brickData.Listeners = addlistener(brickData, 'Hardness', 'PostSet',...
                    @(evt, src) brickData.destroy('source', src, 'event', evt));
            end
        end
    end
    
    
    %% Brick Methods
    methods
        % Function for destroying bricks once the hardness has been worn down
        function destroy(brickData, varargin)
            if brickData.Hardness == 0
                brickData.Destroyed = true;
                delete(brickData.Texture)
                brickData.Texture = [];
                if ~isempty(brickData.Powerup)
                    brickData.Powerup.Position = [brickData.Position+0.25*brickData.Size 0.5*brickData.Size];
                    drawTexture(brickData.Powerup);
                end
            end
        end
        
        % Function to determine empty elements of a brick array
        function brickMap = mapBricks(brickData)
            brickMap = zeros(size(brickData));
            for a = 1:size(brickData, 1)
                for b = 1:size(brickData, 2)
                    if isempty(brickData(a, b).Texture) 
                        brickMap(a, b) = 0;
                    elseif isequal(brickData(a, b).Hardness, inf)
                        brickMap(a, b) = 2;
                    else
                        brickMap(a, b) = 1;
                    end
                end
            end
        end
    end
        
end