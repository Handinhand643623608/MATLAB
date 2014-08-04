function levelOut = level(numLevel)
%LEVEL Level layouts for the Arkanoid game.
%
%
%             1 - Black
%             2 - Blue
%             3 - Diamond
%             4 - Gray
%             5 - Green
%             6 - Light Blue
%             7 - Light Green
%             8 - Light Purple
%             9 - Orange
%             10 - Pink
%             11 - Purple
%             12 - Red
%             13 - Stone
%             14 - Teal
%             15 - Yellow

%   Written by Josh Grooms on 20130521
%       20130522:   Generated levels 3, 4


%% Level Designs
levelOut = zeros(10, 10);
switch numLevel
    case 1
        
        sequence = [11 8 10 12 9 15 7 14 6 2];
        for a = 1:10
            levelOut(a, :) = circshift(sequence, [0, a]);
        end
        levelOut(6:10, :) = 0;
        
        
    case 2
        
        levelOut = [11    0     0     0     0     0     0     0     0     0                    
                    11    8     0     0     0     0     0     0     0     0
                    11    8     10    0     0     0     0     0     0     0
                    11    8     10    12    0     0     0     0     0     0
                    11    8     10    12    9     0     0     0     0     0
                    11    8     10    12    9     15    0     0     0     0
                    11    8     10    12    9     15    7     0     0     0
                    11    8     10    12    9     15    7     14    0     0
                    11    8     10    12    9     15    7     14    6     0
                    13    13    13    13    13    13    13    13    13    2];                          
                
    case 3
        
        levelOut =  [0     0     0     0     0     0     0     0     0     0
                     3     3     3     3     3     3     2     2     2     2
                     0     0     0     0     0     0     0     0     0     0
                     6     6     6     6     6     6     6     6     6     6
                     0     0     0     0     0     0     0     0     0     0
                    14    14    14     3     3     3     3     3     3     3
                     0     0     0     0     0     0     0     0     0     0
                     7     7     7     7     7     7     7     7     7     7
                     0     0     0     0     0     0     0     0     0     0
                     3     3     3     3     3     3    15    15    15    15];
                 
    case 4
        
        sequence = [11 8 10 12 9 15 7 14 6 2]';
        for a = 1:10
            levelOut(:, a) = circshift(sequence, [a, 0]);
        end
        levelOut(:, [1 5 6 10]) = 0;
                
end


levelOut = cat(1, levelOut, zeros(5, 10));
                    
                    