classdef ball < hgsetget
    %BALL A ball object to be used in the Arkanoid game.
    %   This object contains the properties necessary for constructing a single ball object in the
    %   game. Properties are included for later development such as powerups. The image of the ball
    %   in the game is generated during this object's construction. Movement of the ball and changes
    %   in ball velocity are also handled by methods of this object. Collision detection is
    %   implemented in the main game object. 
    %
    %   WARNING: This game object is still under core development.
    %
    %   Syntax:
    %   ballData = ball(arkData, 'PropertyName', PropertyValue,...)
    %
    %   OUTPUTS:
    %   ballData:       A single ball object containing all properties about the ball being
    %                   displayed in the game.
    %
    %   INPUTS:
    %   arkData:        The Arkanoid game object. Needed to determine paddle size and for plotting
    %                   to the correct axes. 
    %
    %   Written by Josh Grooms on 20131516
    %       20130517:   Bug fix for the angle at which ball is reflected off of paddle. 
    %       20130521:   Bug fix for wall collisions. Improved synchronization between ball texture &
    %                   in-game object position by creating a listener for position changes.
    %       20130527:   Changed the handling of collisions with bricks. Implemented a reset
    %                   function.
    %       20130531:   Implemented better ball texture from Photoshop.
    %       20130601:   Implemented transparency around ball texture.
    %       20130803:   Code improvements.
    
    % TODO: Implement powerups
    
    properties (SetObservable, AbortSet)
        
        Listeners           % Listener handles for property changes
        Position            % Position of the ball center
        Powerup             % Powerup properties that affect ball physics
        Size                % Radius of the ball
        Speed               % Speed of the ball in the x & y directions
        Texture             % The image object plotted to the axes showing the physical form of the ball
        
    end
    
    
    %% Constructor Method
    methods
        function ballData = ball(arkData, varargin)
            %BALL Constructs a ball for use in the Arkanoid game.
            
            % Initialize a defaults & settings structure
            inStruct = struct(...
                'Position', [0.5 arkData.Paddle.Size(2)+0.0125],...
                'Size', 0.0125,...
                'Speed', 0);
            assignInputs(inStruct, varargin, 'structOnly');
            ballDir = which('ball\ball');
            ballDir = strrep(ballDir, '\ball.m', '');
            
            % Texture the ball
            tempTexture = imread([ballDir '\Ball.tif']);
            tempAlpha = double(tempTexture(:, :, 1));
            tempAlpha = tempAlpha./max(tempAlpha(:));
            ballData.Texture = image(...
                'AlphaData', tempAlpha,...
                'CData', tempTexture,...
                'Parent', arkData.Axes,...
                'XData', [inStruct.Position(1)-inStruct.Size inStruct.Position(1)+inStruct.Size],...
                'YData', [inStruct.Position(2)-inStruct.Size inStruct.Position(2)+inStruct.Size]);
            clear temp*
            
            % Assign inputs to object properties
            propNames = fieldnames(inStruct);
            for a = 1:length(propNames)
                ballData.(propNames{a}) = inStruct.(propNames{a});
            end
                                                 
            % Add a listener for changes in ball position to change texture location
            ballData.Listeners = addlistener(ballData, 'Position', 'PostSet',...
                @(src, evt) ballData.texturePosition(src, evt));
        end
    end
    
    
    %% Ball Methods
    methods
        % Function for moving the ball around the playing field
        function moveBall(ballData, varargin)
            ballData.Position = ballData.Position + ballData.Speed;
        end
        
        % Function for changing the speed parameters during a collision
        function collide(ballData, objHit, varargin)
            switch objHit
                case 'brick'
                    idxHit = varargin{1};
                    ballData.Speed(idxHit) = -ballData.Speed(idxHit);
                    
                case 'paddle'
                    relativeCollision = varargin{1};
                    newAngle = -(6/10)*pi*relativeCollision + (8/10*pi);
                    magSpeed = sqrt(ballData.Speed(1)^2 + ballData.Speed(2)^2);
                    newSpeed = [magSpeed*cos(newAngle) magSpeed*sin(newAngle)];
                    ballData.Speed = newSpeed;
                    
                case 'wall'
                    if any((ballData.Position+ballData.Size) > 1)
                        idxWall = ballData.Position+ballData.Size > 1;
                        ballData.Speed(idxWall) = -ballData.Speed(idxWall);                                                
                        ballData.Position(idxWall) = 1 - ballData.Size;                        
                        
                    elseif any((ballData.Position-ballData.Size) < 0)
                        idxWall = ballData.Position-ballData.Size < 0;
                        ballData.Speed(idxWall) = -ballData.Speed(idxWall);
                        ballData.Position(idxWall) = ballData.Size;
                    end
            end
        end
        
        % Function for resetting ball position
        function reset(ballData, paddleData)
            set(ballData, 'Position', [0.5 paddleData.Size(2)+ballData.Size]); 
            set(ballData, 'Speed', 0);
        end
        
        % Function for changing texture position when ball position changes
        function texturePosition(ballData, varargin)
            set(ballData.Texture,...
                'XData', [ballData.Position(1)-ballData.Size ballData.Position(1)+ballData.Size],...
                'YData', [ballData.Position(2)-ballData.Size ballData.Position(2)+ballData.Size]);
        end
        
    end
end