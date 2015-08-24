classdef arkanoid < Window
%ARKANOID - A simple, retro-style block breaking game.
%   This game is coded in a simple OOP format and runs quickly in the MATLAB environment. The goal of this game is to
%   destroy all blocks by reflecting the constantly moving ball off of the user controlled paddle. If the ball falls
%   beneath the paddle, the game is lost.
%
%   WARNING: This game is still under development and is currently only intended as a demo.
%
%   SYNTAX:
%   arkanoid
%   arkData = arkanoid
%
%   OUTPUT:
%   (arkData):    An optional output that contains the entire game object and associated properties.
%
%   REQUIRED ADDITIONAL CODE
%       @Window
%
%       assignInputs
%       colorScheme
%       sigFig

%% CHANGELOG
%   Written by Josh Grooms on 20130516
%       20130520:   Added a GUI element for settings
%       20130521:   Implemented a scoring & high scoring system. Improved the "reset" function. Implemented Photoshop
%                   textures for bricks & paddle. Added some todos.
%       20130527:   Implemented a level reset function in preparation for multiple lives. Implemented randomized ball
%                   launches. Improved collision detection & reaction with bricks.
%       20130531:   Bug fix for ball launches with downward velocity. Implemented Photoshop texturing for the ball.
%                   Removed some unnecessary code.
%       20130601:   Implemented multiple lives into the game & a display for them. Changed ordering & color scheme of
%                   HUD elements.
%       20130802:   Improvements in code. Updated for compatibility with WINDOWOBJ re-write.
%       20140829:   Updated for compatibility with the WINDOW class updates (formerly WINDOWOBJ).
%       20150824:   Updated for compatibility with cumulative changes to the WINDOW class over the past year.

%% TODOS
% TODO: Fix bug where ball can get in between adjacent bricks
% TODO: Implement a game pause.
% TODO: Implement keyboard controls for paddles
% TODO: Implement powerups for the paddle
% TODO: Optimize CPU utilization & game speed
% TODO: Implement customizable ball speed

    properties
        Ball                % A ball object, with its own properties & methods
        Bricks              % An array of brick objects
        Level = 1           % The current playing level
        Lives = [0 0 0]     % The number of replay attempts the player gets after ball falls
        Menus               % Menus for game settings
        Paddle              % The paddle object
        PushButtons         % Push buttons for GUI controls
        Score               % The score & high score of the current game
    end


    %% Constructor Method
    methods
        function arkData = arkanoid
            %ARKANOID A retro brick-breaking game.
            % Initialize a window object
            arkData = arkData@Window(...
                'Background',       [0, 0, 0],...
                'Name',             'Arkanoid',...
                'Position',         WindowPositions.CenterCenter,...
                'Resize',           'off',...
                'Size',             WindowSizes.QuarterScreen);
            % Initialize the game environment
            initialize(arkData);
            % Generate the brick layout
            layBricks(arkData);
            % Generate the paddle
            arkData.Paddle = paddle(arkData);
            % Generate the ball
            arkData.Ball = ball(arkData);
        end

    end


    %% Game Methods
    methods
        % Move the paddle with the mouse
        function clickFcn(arkData, varargin)
            set(arkData.FigureHandle,...
                'Pointer', 'custom',...
                'PointerShapeCData', nan(16, 16),...
                'WindowButtonMotionFcn', @(src, evt) arkData.Paddle.motionFcn(src, evt));
            if arkData.Ball.Speed == 0
                randSpeed = randn(1, 2);
                arkData.Ball.Speed = randSpeed.*(0.0141/norm(randSpeed));
                arkData.Ball.Speed(2) = abs(arkData.Ball.Speed(2));
                runGame(arkData);
            end
        end

        % Close the window function
        function close(arkData, varargin)
            evalin('base', 'clear all')
            close@windowObj(arkData)
        end

        % Dummy display function to prevent object properties from showing in command window
        function disp(~)
            return
        end

        % Advance in level
        function nextLevel(arkData)
            currentLevel = eval(get(arkData.Level, 'String'));
            set(arkData.Level, 'String', sprintf('%02d', currentLevel+1));
            cla(arkData.Axes);
            layBricks(arkData);
            arkData.Paddle = paddle(arkData);
            arkData.Ball = ball(arkData);
        end

        % Function for resetting the game
        function reset(arkData, varargin)
            warning('off', 'MATLAB:callback:error');
            clf(arkData.FigureHandle);
            arkData.Lives = [0 0 0];
            initialize(arkData);
            layBricks(arkData);
            arkData.Paddle = paddle(arkData);
            arkData.Ball = ball(arkData);
        end

        % Function for resetting the level
        function resetLevel(arkData, varargin)
            reset(arkData.Paddle);
            reset(arkData.Ball, arkData.Paddle);
        end

        % Function for running the game
        runGame(arkData);
        % Function to editing game settings
        settings(arkData, varargin);

    end


    %% Protected Methods
    methods (Access = protected)
        % Initialization function
        initialize(arkData);
        % Generate a layout of bricks
        layBricks(arkData);
    end
end
