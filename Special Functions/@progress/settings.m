function settings(progData)
%SETTINGS Change default settings for the progress bar
%
%   SYNTAX:
%   settings(progress)
%
%   INPUT:
%   progress:   The progress bar class name. This input is used to generate a simple example
%               progress bar for the user to see while making default selections.
%
%   Written by Josh Grooms on 20130803


%% Create a Settings GUI
% Set progress bar to maximum length (for user visualization)
update(progData, 1);

% Initialize a small window object for displaying the settings GUI
setWindow = windowObj(...
    'Color', 'k',...
    'Position', 'center-center',...
    'Name', 'Progress Bar Settings',...
    'NumberTitle', 'off',...
    'Size', [300, 100]);

% Set a delete function for the settings window
set(setWindow, 'DeleteFcn', @(src, evt) close(progData, src, evt));

% Create the GUI color selector
colorChoices = {'Cool', 'Gray', 'Hot', 'HSV', 'Jet'};
colorHandle = uicontrol(...
    'Units', 'normalized',...
    'Style', 'popup',...
    'String', [{'Progress Bar Colormap'}, colorChoices],...
    'Position', [1/4 1/4 1/2 1/2],...
    'Callback', @(src, evt) setColormap(progData, src, evt));


end %===============================================================================================

function setColormap(progData, src, ~)
    colorChoices = get(src, 'String');
    colorSelect = get(src, 'Value');
    if colorSelect ~= 1
        barColor = eval([lower(colorChoices{colorSelect}) '(128)']);
        set(progData, 'Colormap', barColor);
        progPath = fileparts(which('progress.m'));
        save([progPath '/settings.mat'], 'barColor', '-append');
    end
end