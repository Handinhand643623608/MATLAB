function initialize(progData, varargin)
%INITIALIZE Initialize a progress bar object.
%   This function initializes a single progress bar object at 0.0% completion that is ready to be updated.
% 
%   Written by Josh Grooms on 20130214
%       20130801:   Updated to be compatible with the re-write of WINDOWOBJ. Removed the shimmer property (not easily 
%                   implementable). Removed changelog entries (see SVN for the complete listing).
%       20130803:   Hard set all user inputs except for bar titles (these were never really used).
%       20130804:   Implemented estimated time remaining for overall progress.
%       20131210:   Implemented the "Fast" property, which turns off smooth animations & instantly jumps the progress
%                   bar to its final position.


%% Initialize
% Initialize progress bar properties
if isempty(varargin)
    barTitle = {'Progress'};
else
    if strcmpi(varargin{end}, 'fast')
        progData.Fast = true;
        varargin(end) = [];
    end
    barTitle = varargin;
end
progPath = fileparts(which('progress.m'));
load([progPath '/settings.mat']);
                  
% Set a callback to delete variables when the window is closed
set(progData, 'DeleteFcn', @(src, evt) progData.close('source', src, 'event', evt));

% Change figure size & position as needed to accommodate multiple bars  
posFig = get(progData.FigureHandle, 'Position');
oldHeight = posFig(4);
newHeight = numel(barTitle).*oldHeight;
posFig(4) = newHeight;
set(progData.FigureHandle, 'Position', posFig);
currentOuterPos = get(progData, 'Position');
currentOuterPos(2) = currentOuterPos(2) - newHeight + oldHeight;
set(progData, 'Position', currentOuterPos);
lowerBarPosition = [0.01 0.01 0.88 0.5/numel(barTitle)];

% Initialize axes within the figure
for a = 1:length(barTitle)         
    progAxes(a) = axes(...
        'Units', 'normalized',...
        'Position', lowerBarPosition,...
        'Parent', progData.FigureHandle,...
        'Color', [0 0 0],...
        'XLim', [0 104],...
        'XTick', [],...
        'YLim', [-1.25 1.25],...
        'YTick', []);
    lowerBarPosition(2) = lowerBarPosition(2) + 2*lowerBarPosition(4);
end
progAxes = flipdim(progAxes, 2);

% Create the first semicircular patch for constructing the bar
firstTheta = pi/2:(pi/999):3*pi/2;
firstCircleX = 2 + 2*cos(firstTheta);
firstCircleY = sin(firstTheta);

% Create the second semicircular endcap
secondTheta = -pi/2:(pi/999):pi/2;
secondCircleX = max(firstCircleX) + 2*cos(secondTheta);
secondCircleY = sin(secondTheta);


%% Setup the Progress Bar
% Setup text for the progressbar
for a = 1:length(barTitle)
    % Generate text for bar title & completion percentage
    progTitle(a) = text('Units', 'data', 'Position', [0, 2.25], 'String', barTitle{a},...
        'FontSize', 12, 'Color', 'w', 'FontWeight', 'bold', 'Parent', progAxes(a));
    barText(a) = text('Units', 'data', 'Position', [(max(secondCircleX)+1), 0], 'String', '0.0%',...
        'FontSize', 10, 'Color', 'w', 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'Parent', progAxes(a));

    % Initialize the patch object
    barPatch(a) = patch([firstCircleX secondCircleX], [firstCircleY secondCircleY], 1:length([firstCircleX secondCircleX]),...
        'FaceColor', 'interp', 'EdgeColor', 'none', 'Parent', progAxes(a));
    material metal
end

% Fill in the clock properties
currentTime = now;
progData.Clock.PreviousTime = currentTime;
progData.Clock.Average = currentTime;
progData.Clock.NumIterations = 0;

% Fill in text & data properties (these need to occur first)
progData.Text = struct(...
    'BarTitle', progTitle,...
    'BarText', barText);
progData.Data = barPatch;

% Fill in remaining progress bar properties
progData.Axes = progAxes;
progData.BarTitle = barTitle;
progData.Complete = zeros(1, length(barTitle));
progData.Parallel = parallelSwitch;

% Fill in figure properties
set(progData, 'Colormap', barColor);
drawnow