classdef powerup < hgsetget
    %POWERUP A powerup object to be used in the Arkanoid game.
    %
    %   SYNTAX:
    %   powerData = powerup
    %
    %   OUTPUT:
    %   powerData:      A powerup object with only an identity set up. Other properties are added as
    %                   bricks are destroyed & powers are picked up by the paddle.
    %
    %   Written by Josh Grooms on 20130816
    
    properties 
        
        Clock
        Listeners
        Name
        Position
        Texture
        
    end
    
    
    %% Constructor Method
    methods
        function powerData = powerup
            %POWERUP Constructs a powerup for the Arkanoid game.
            % List of available powerups
            powerNames = {...
                '+1';
                'Enlongate';
                'Laser';
                'Shorten';
                'Slow';
                'Sun';
                'x2';
                };
            
            % Randomly choose a power & output
            powerData.Name = powerNames{randi(length(powerNames))};
        end
    end

    
    %% Powerup Methods
    methods
        % Draw the powerup texture when it's freed from a brick
        function drawTexture(powerData)
            
        end
        
        % Move the powers down the game grid after they've been freed
        function movePowers(powerData)
           for a = 1:length(powerData)
               powerData(a).Position(2) = powerData(a).Position(2) - 0.0141;
               set(powerData(a).Texture, 'YData', [powerData(a).Position(2) powerData(a).Position(4)]);
           end
        end
    end
end