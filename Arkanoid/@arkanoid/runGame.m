function runGame(arkData)
%RUNGAME Runs the Arkanoid game. 
%   This function controls the moment-by-moment operation of the game by calling commands to move
%   the ball, destroy the blocks, and detect collisions. 
%
%   Syntax:
%   runGame(arkData)
%
%   INPUTS:
%   arkData:    The fully constructed Arkanoid game object containing all necessary information to
%               run the game.
%
%   Written by Josh Grooms on 20130516
%       20130517:   Rewrote & optimized most of the collision detection. Still needs work, though.
%                   Weird things happen sometimes.
%       20130521:   Implemented a scoring system. Bug fix for bricks being removed from game grid
%                   even though hardness is not zero. Implemented additional levels.
%       20130522:   Implemented the unbreakable diamond block. Bug fix for level mappings that don't
%                   have bricks in the first row.
%       20130601:   Implemented multiple lives into the game.
%       20130816:   Began implementation of powerups.

% TODO: Fix bug where ball is able to pass through brick vertical edges.
% TODO: Optimize code


%% Initialize
gameGrid = mapBricks(arkData.Bricks);
idxBrick = find(gameGrid, 1, 'first');
xGameGrid = arkData.Bricks(idxBrick).Size(1):arkData.Bricks(idxBrick).Size(1):1;
yGameGrid = arkData.Bricks(idxBrick).Size(2):arkData.Bricks(idxBrick).Size(2):1;
freePowers = false(size(gameGrid));

%% Run the Game
while (arkData.Ball.Position(2)-arkData.Ball.Size > 0) && any(gameGrid(:) == 1)
        
    % Get current velocity directions & the ball center
    dirVelocity = sign(arkData.Ball.Speed);
    currentBallCenter = arkData.Ball.Position;
    
    % Get the current ball position
    boundingBox = [arkData.Ball.Position(1)-arkData.Ball.Size' arkData.Ball.Position+arkData.Ball.Size'];
    activeBallSides = currentBallCenter + dirVelocity.*arkData.Ball.Size;
    
    % Get ball position in terms of the game grid
    idsCurrentGrid = [find(xGameGrid > activeBallSides(1), 1) find(yGameGrid > activeBallSides(2), 1)];
            
    
    %% Collision Detections & Ball Movement
    % Initialize collision arguments
    collisionArgs = {};
    
    % Detect collisions with the walls
    if any(activeBallSides >= 1) || any(activeBallSides <= 0)
        collisionArgs = {'wall'};
        collide(arkData.Ball, collisionArgs{:});
        moveBall(arkData.Ball);
        pause(0.0001)   
        clear temp*
        continue
    end
    
    % Detect collisions with the paddle
    if activeBallSides(2) <= arkData.Paddle.Size(2)
        % Get the current paddle position
        currentPPos = [arkData.Paddle.Position arkData.Paddle.Position+arkData.Paddle.Size(1)];                    
        currentBallWidth = [activeBallSides(1) currentBallCenter(1)-dirVelocity(1)*arkData.Ball.Size(1)];
        currentBallPaddle = union(currentBallWidth, currentPPos);
        
        if currentBallPaddle(end) == currentPPos(2) && currentBallPaddle(1) == currentPPos(1)
            tempDiff = (currentBallCenter(1) - currentPPos(1))/arkData.Paddle.Size(1);
            if tempDiff > 1
                tempDiff = 1;
            elseif tempDiff < 0
                tempDiff = 0;
            end
            collisionArgs = {'paddle', tempDiff};
            collide(arkData.Ball, collisionArgs{:});
            moveBall(arkData.Ball);
            pause(0.0001)    
            clear temp*
            continue
        end
    end
    
    % Detect collisions with the bricks    
    if ~exist('presentState', 'var')
        presentState = idsCurrentGrid;
    else
        previousState = presentState;
        presentState = idsCurrentGrid;
        borderCross = (previousState ~= presentState);
        if any(borderCross)   
            
            if all(borderCross)
                
                borders = [0 0];
                if any(dirVelocity > 0)
                    borders = (dirVelocity > 0).*[xGameGrid(previousState(1)) yGameGrid(previousState(2))];
                end
                if any(dirVelocity < 0)
                    borders = borders + (dirVelocity < 0).*[xGameGrid(presentState(1)) yGameGrid(presentState(2))];
                end
                
                crossTime = (1./-arkData.Ball.Speed).*(borders - activeBallSides);
                borderCross(crossTime ~= max(crossTime)) = 0;
                
                tempIds = previousState + dirVelocity.*(borderCross);
                if gameGrid(tempIds(1), tempIds(2))
                    arkData.Ball.Position = arkData.Ball.Position - arkData.Ball.Speed.*max(crossTime);
                    idsCurrentGrid = tempIds;
                elseif gameGrid(presentState)
                    arkData.Ball.Position = arkData.Ball.Position - arkData.Ball.Speed.*min(crossTime);
                    borderCross = ~borderCross;
                end
            end
                            
            if gameGrid(idsCurrentGrid(1), idsCurrentGrid(2))                                                
                % Set up the collision arguments
                collisionArgs = {'brick', borderCross};
                arkData.Bricks(idsCurrentGrid(1), idsCurrentGrid(2)).Hardness = arkData.Bricks(idsCurrentGrid(1), idsCurrentGrid(2)).Hardness - 1;

                % Increment the score
                if gameGrid(idsCurrentGrid(1), idsCurrentGrid(2)) ~= 2
                    currentScore = eval(get(arkData.Score.Current, 'String'));
                    currentScore = currentScore + 1;
                    set(arkData.Score.Current, 'String', sprintf('%04d', currentScore));
                end

                % Remove brick from the game grid, if broken
                if arkData.Bricks(idsCurrentGrid(1), idsCurrentGrid(2)).Destroyed
                    gameGrid(idsCurrentGrid(1), idsCurrentGrid(2)) = 0;
                    if ~isempty(arkData.Bricks(idsCurrentGrid(1), idsCurrentGrid(2)).Powerup);
                        freePowers(idsCurrentGrid(1), idsCurrentGrid(2)) = true;
                    end
                end         
            end
        end
    end
    
    % Implement collision physics & move the ball
    if ~isempty(collisionArgs)
        collide(arkData.Ball, collisionArgs{:});
    end
    moveBall(arkData.Ball);
    pause(0.0001)
    
    % Advance any freed powerups down the game area
    if any(freePowers)
        idsFreePowers = find(freePowers);
        movePowers(arkData.Bricks(idsFreePowers).Powerup);
        powerPositions = cat(1, arkData.Bricks(idsFreePowers).Powerup.Position);
        pCollisionCheck = isInside(powerPositions, [arkData.Paddle.Position arkData.Paddle.Size]);
        if any(pCollisionCheck)
            arkData.Paddle.Powerup = arkData.Bricks(idsFreePowers(pCollisionCheck)).Powerup;
            freePowers(idsFreePowers(pCollisionCheck)) = false;
        end
    end
    
    clear temp* current*
end


%% Store the High Scores & Advance Game Levels
% Get game info
gameDir = which('arkanoid\runGame.m');
gameDir = strrep(gameDir, 'runGame.m', '');
currentScore = eval(get(arkData.Score.Current, 'String'));
if exist([gameDir '\highScore.mat'], 'file')
    load([gameDir '\highScore.mat']);
else
    highScore = 0;
end

% Compare current & high score
if currentScore > highScore
    highScore = currentScore;
    save([gameDir '\highScore.mat'], 'highScore');
end

% Advance the level, if appropriate
if ~any(gameGrid == 1)
    nextLevel(arkData)
end

% Lose a life, if appropriate
if arkData.Ball.Position(2)-arkData.Ball.Size <= 0
    if isempty(arkData.Lives)
        return
    else
        delete(arkData.Lives(end));
        arkData.Lives(end) = [];
        resetLevel(arkData);
    end    
end


end%================================================================================================
%% Nested Functions
function z = isInside(x, y)
    %ISINSIDE Is x coordinates inside y coordinates
    z = false(size(x, 1), 1);
    for a = 1:size(x, 1)
        if x(a, 1) > y(1) && x(a, 1) < y(1)+y(3)
            if x(a, 2) > y(2) && x(a, 2) < y(2)+y(4)
                z(a) = true;
            end
        elseif x(a, 1)+x(a, 3) > y(1) && x(a, 1)+x(a, 3) < y(1)+y(3)
            if x(a, 2)+x(a, 4) > y(2) && x(a, 2)+x(a, 4) < y(2)+y(4)
                z(a) = true;
            end
        end
    end
end