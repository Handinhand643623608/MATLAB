function PlotEEG(A, data, showLabels)
%PLOTEEG - Plots a spatial mapping of EEG electrodes and fills electrodes with color.
%
%   WARNING: EEGPLOT is an internal method for brainPlot and is not meant to be called externally.

%% CHANGELOG
%   Written by Josh Grooms on 20130626
%       20140828:   



%% Initialize
if nargin == 3; showLabels = false; end
classPath = where('PlotEEG.m');
load([classPath '/eegInfo.mat']);
plotFig = [classPath '/eegPlot.fig'];



%% Create & Color the EEG Electrode Maps
if exist(plotFig, 'file')
    % Load an existing plot of electrode locations (saves time when making a lot of these)
    loadStruct = struct('Parent', A);
    [plotHandles, ~] = hgload(plotFig, loadStruct);
    plotHandles = reshape(plotHandles, [0.5*size(plotHandles, 1), 2]);
    for a = 1:length(channels)
        set(plotHandles(a, 2),...
            'CData', data(a),...
            'EdgeColor', 'none');
        set(plotHandles(a, 1),...
            'FontUnits', 'normalized');
        if ~showLabels
            set(plotHandles(a, 1), 'Visible', 'off');
        end
    end
else
    % Produce new spatial maps if a template doesn't already exist
    plotHandles = zeros(length(channels), 2);
    szLabels = zeros(length(channels), 4);
    coords = zeros(length(channels), 2);

    for a = 1:length(channels)
        % Get the electrode spatial coordinates
        coords(a, :) = coordinates.(channels{a});

        % Draw the text on the plot & set properties
        plotHandles(a, 1) = text(coords(a, 1), coords(a, 2), channels{a}, 'Parent', A);
        set(plotHandles(a, 1),...
            'HorizontalAlignment', 'center',...
            'VerticalAlignment', 'middle',...
            'FontUnits', 'normalized',...
            'FontWeight', 'bold');

        % Get the size of the labels to determine how to scale the circle
        szLabels(a, :) = get(plotHandles(a, 1), 'Extent');
    end

    % Get the maximum width of all text (in order to make surrounding circles consistent)
    maxWidth = max(szLabels(:, 3));

    % Initialize the circle patches
    theta = 0:(2*pi/(99)):2*pi;
    circleX = maxWidth.*sin(theta);
    circleY = maxWidth.*cos(theta);

    % Create the electrode circles on the plot
    for a = 1:length(data)
        % Adjust the spatial position
        currentX = circleX + coords(a, 1);
        currentY = circleY + coords(a, 2);

        % Create the circle object & set properties
        plotHandles(a, 2) = patch(currentX, currentY, 'w');
        set(plotHandles(a, 2),...
            'CData', data(a),...
            'CDataMapping', 'scaled',...
            'EdgeColor', 'none',...
            'FaceColor', 'flat');

        % Delete & refresh the text data (so it's on top of the circle)
        delete(plotHandles(a, 1));
        plotHandles(a, 1) = text(coords(a, 1), coords(a, 2), channels{a}, 'Parent', A);
        set(plotHandles(a, 1),...
            'HorizontalAlignment', 'center',...
            'VerticalAlignment', 'middle',...
            'Color', 'k',...    
            'FontUnits', 'normalized',...
            'FontWeight', 'bold');    
    end
    
    
    % Save the figure for quick use in the future
    hgsave(plotHandles, plotFig);
end