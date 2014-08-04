function settings(arkData, src, ~)
%SETTINGS Change game settings.
%   This function controls user input and window size settings.
%
%   Written by Josh Grooms on 20130521
%       20130603:   Implemented a reset function for the high score. 


%% Initialize
% Determine where the settings file is
settingsDir = which('arkanoid\settings');
settingsDir = strrep(settingsDir, '\settings.m', '');

% Setup a persistent settings method between game loads
if exist([settingsDir '\settings.mat'], 'file')
    load([settingsDir '\settings.mat']);
else
    setStruct = struct(...
        'Control', 'Mouse',...        
        'WindowSize', 'Quarter Screen');
end

% Get the setting that has been changed
setChange = get(src, 'Label');


%% Change Game Settings
switch setChange
    case {'Quarter Screen', 'Half Screen', 'Full Screen'}
        setChange = lower(strrep(setChange, ' ', ''));
        set(arkData, 'Resizable', 'on');
        set(arkData, 'Size', setChange);
        set(arkData, 'Position', 'top-right');
        setStruct.WindowSize = setChange;
        set(arkData, 'Resizable', 'off');
        
    case {'Input'}
        
    case {'Reset High Score'}
        delete([settingsDir '\highScore.mat']);
        set(arkData.Score.High, 'String', '0000');
        
end

% Store the settings for the next game load
save([settingsDir '\settings.mat'], 'setStruct');


    
