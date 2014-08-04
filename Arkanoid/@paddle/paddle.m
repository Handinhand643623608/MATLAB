classdef paddle < hgsetget
    %PADDLE A paddle object to be used in the Arkanoi game.
    %   This object contains the properties necessary to construct a single, user-controllable
    %   paddle in the game. Properties are included for later development such as powerups. The
    %   image of the paddle in the game is generated during this object's construction. The mouse
    %   control of the paddle is managed though the game object code, but the paddle's position is
    %   updated here. 
    %
    %   WARNING: This game object is still under core development
    %
    %   Syntax:
    %   paddleData = paddle(arkData, 'PropertyName', PropertyValue,...)
    %
    %   OUTPUTS:
    %   paddleData:     A single paddle object containing all properties about the paddle being
    %                   displayed in the game.
    %
    %   INPUTS:
    %   arkData:        The Arkanoid game object. Needed for plotting images to the correct axes. 
    %
    %   Written by Josh Grooms on 20130516
    %       20130517:   Removed the superfluous function "movePaddle" & combined the useful part
    %                   with "motionFcn". Also removed the associated listener.
    %       20130521:   Implemented better paddle textures from Photoshop.
    %       20130527:   Implemented a function to reset paddle position to the middle.
    %       20130531:   Removed some superfluous code.
    
    % TODO: Implement powerups for the paddle
    
    
    properties (SetObservable, AbortSet)
                
        Listeners           % Listener handles for property changes
        Position            % Left edge of the paddle
        Powerup             % The powerup being used by the paddle (not yet implemented)
        Size                % Width & height of the paddle
        Texture             % The image object plotted to the axes showing the physical form of the paddle
        
    end
    
    
    %% Constructor Method
    methods
        function paddleData = paddle(arkData, varargin)
            %PADDLE Constructs a paddle for use in the Arkanoid game.
            
            % Initialize a defaults & settings structure
            inStruct = struct(...
                'Powerup', [],...
                'Position', 0.425,...   
                'Size', [0.15 0.05]);
            assignInputs(inStruct, varargin, 'structOnly');
            paddleDir = which('paddle\paddle');
            paddleDir = strrep(paddleDir, '\paddle.m', '');
            
            % Texture the paddle
            tempTexture = flipdim(imread([paddleDir '\Paddle.tif']), 1);            
            paddleData.Texture = image(...
                [inStruct.Position, inStruct.Position+inStruct.Size(1)],...
                [0, inStruct.Size(2)],...
                tempTexture,...
                'Parent', arkData.Axes);
            clear temp*
                        
            % Assign properties to the object
            propNames = fieldnames(inStruct);
            for a = 1:length(propNames)
                paddleData.(propNames{a}) = inStruct.(propNames{a});
            end                      
        end
    end
    
    
    %% Paddle Methods
    methods
        % Functions for moving the paddle with the mouse
        function motionFcn(paddleData, varargin)
            mousePosition = get(gca, 'CurrentPoint');
            szPaddle = paddleData.Size;
            paddlePosition = mousePosition(1) - (0.5*szPaddle(1));
            if paddlePosition < 0
                paddlePosition = 0;
            elseif paddlePosition > 1-szPaddle(1)
                paddlePosition = 1-szPaddle(1);
            end
            set(paddleData, 'Position', paddlePosition)
            paddlePosition = [paddlePosition paddlePosition+szPaddle(1)];
            set(paddleData.Texture, 'XData', paddlePosition);
        end            
        function releaseFcn(~, varargin)
            set(varargin{1},...
                'Pointer', 'arrow',...
                'WindowButtonMotionFcn', '');            
        end              
        
        % Function for resetting the paddle
        function reset(paddleData)
            middlePosition = 0.5 - (paddleData.Size(1)/2);
            set(paddleData, 'Position', middlePosition); 
            set(paddleData.Texture, 'XData', [middlePosition middlePosition+paddleData.Size(1)]);
        end
    end
end



