function eegPlot(axHandle, inData, channels, strPlot)
%EEGPLOT Plots a spatial mapping of EEG electrodes and fills electrodes with color.
%
%   WARNING: EEGPLOT is an internal method for brainPlot and is not meant to be called externally.

%% CHANGELOG
%   Written by Josh Grooms on 20130626



%% Initialize
if nargin == 3
    strPlot = false;
end
load eegSpatialCoordinates.mat;
classPath = which('brainPlot.m');
classPath = strrep(classPath, '\brainPlot.m', '');
plotFig = [classPath '\eegPlot.fig'];

if exist(plotFig, 'file')
    %% Load an Existing Plot (Saves Time)
    loadStruct = struct('Parent', axHandle);
    [plotHandles, ~] = hgload(plotFig, loadStruct);
    plotHandles = reshape(plotHandles, [0.5*size(plotHandles, 1), 2]);
    for a = 1:length(channels)
        set(plotHandles(a, 2),...
            'CData', inData(a),...
            'EdgeColor', 'none');
        set(plotHandles(a, 1),...
            'FontUnits', 'normalized');
        if ~strPlot
            set(plotHandles(a, 1), 'Visible', 'off');
        end
    end
    
    
else
    %% Generate a Spatial EEG Map
    % Produce the spatial maps
    plotHandles = zeros(length(channels), 2);
    szLabels = zeros(length(channels), 4);
    eegCoords = zeros(length(channels), 2);

    for a = 1:length(channels)
        % Get the electrode spatial coordinates
        eegCoords(a, :) = eegCoordinates.(channels{a});

        % Draw the text on the plot & set properties
        plotHandles(a, 1) = text(eegCoords(a, 1), eegCoords(a, 2), channels{a}, 'Parent', axHandle);
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
    for a = 1:length(inData)
        % Adjust the spatial position
        currentX = circleX + eegCoords(a, 1);
        currentY = circleY + eegCoords(a, 2);

        % Create the circle object & set properties
        plotHandles(a, 2) = patch(currentX, currentY, 'w');
        set(plotHandles(a, 2),...
            'CData', inData(a),...
            'CDataMapping', 'scaled',...
            'EdgeColor', 'none',...
            'FaceColor', 'flat');

        % Delete & refresh the text data (so it's on top of the circle)
        delete(plotHandles(a, 1));
        plotHandles(a, 1) = text(eegCoords(a, 1), eegCoords(a, 2), channels{a}, 'Parent', axHandle);
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