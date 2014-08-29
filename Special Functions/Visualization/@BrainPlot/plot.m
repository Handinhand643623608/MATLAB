function Plot(H, plotType)
%PLOT Displays the data in an EEG- or MRI-style plot.
%
%   WARNING: PLOT is an internal method for brainPlot and is not meant to be called externally.

%% CHANGELOG
%   Written by Josh Grooms on 20130626
%       20130627:   Updated to symmetrize the color bar based on maximum absolute value of data present.
%       20130702:   Updated to allow for plotting of fMRI images. Implemented anatomical underlay for thresholded
%                   images.
%       20130717:   Added DRAWNOW to force flushing of graphics buffer after each image draw to prevent misplaced 
%                   images.
%       20130809:   Updated for compatibility with re-written WINDOWOBJ.
%       20131007:   Updated font sizings.
%       20131028:   Bug fix for very large montages expanding off-screen.
%       20140625:   Removed dependencies on my personal file structure.



%% Initialize
% Parcellate the axes area
upperAxes = H.Axes.Primary;
posUpperAxes = get(upperAxes, 'Position');
numXElements = size(H.Data, H.XDim);
numYElements = size(H.Data, H.YDim);
posInnerFig = getpixelposition(H.FigureHandle);        

% Set hard upper axes limits & prevent montage from extending off-screen
[posUpperAxes, singleUnit] = calculateElementSize(posUpperAxes, posInnerFig, numXElements, numYElements);
set(upperAxes, 'Position', posUpperAxes);

% Set up a grid for placing elements of the montage
xGrid = linspace(posUpperAxes(1)+2, posUpperAxes(1)+posUpperAxes(3)-4, numXElements+1);
yGrid = linspace(posUpperAxes(2)+2, posUpperAxes(2)+posUpperAxes(4)-4, numYElements+1);
yGrid = fliplr(yGrid);



%% Plot Elements of the Montage
% Plot elements of the montage
for a = 1:length(yGrid)-1
    for b = 1:length(xGrid)-1

        % Determine where the current axes should go
        currentAxPos = [xGrid(b) yGrid(a+1) xGrid(b+1)-xGrid(b) yGrid(a)-yGrid(a+1)];

        % Constuct axes there
        H.Axes.Montage(a, b) = axes(...
            'Units', 'pixels',...
            'Box', 'off',...
            'CLim', H.CLim,...
            'CLimMode', 'manual',...
            'Color', get(H, 'Color'),...
            'Position', currentAxPos,...
            'XLim', [0 1],...
            'XTick', [],...
            'YLim', [0 1],...
            'YTick', []);
        
        % Plot specific modalities
        switch plotType
            case {'bold', 'mri', 'fmri'}
                % Plot fMRI slices
                currentData = permute(H.Data(:, :, end-(a-1), b), [2 1 3 4]);
                if ~isempty(H.Anatomical)
                    currentAnatomical = permute(double(H.Anatomical(:, :, end-(a-1))), [2 1 3]);
                    currentData = H.fuseImages(currentData, currentAnatomical, H.CLim);
                else
                    currentData = scale2rgb(currentData, 'CLim', H.CLim);
                end
                image('CData', currentData,...
                    'Parent', H.Axes.Montage(a, b),...
                    'XData', [0 1], 'YData', [0 1]); 
                drawnow

            case {'eeg', 'electrodes'}
                % Plot EEG electrodes & color data
                H.eegPlot(H.Axes.Montage(a, b), H.Data(:, b, end-(a-1)), H.Channels);
                drawnow               
        end
    end
end


%% Finalize the Plot
xTickSpacing = (singleUnit/2:singleUnit:(posUpperAxes(1)+posUpperAxes(3)-singleUnit/2))./posUpperAxes(3);
yTickSpacing = (singleUnit/2:singleUnit:(posUpperAxes(2)+posUpperAxes(4)-singleUnit/2))./posUpperAxes(4);
set(H.Axes.Primary,...
    'FontSize', 20,...
    'XTick', xTickSpacing,...
    'XTickLabel', H.XTickLabel,...
    'YTick', yTickSpacing,...
    'YTickLabel', H.YTickLabel);
set(get(H.Axes.Primary, 'XLabel'),...
    'Color', H.AxesColor,...
    'FontSize', 25,...
    'String', H.XLabel);
set(get(H.Axes.Primary, 'YLabel'),...
    'Color', H.AxesColor,...    
    'FontSize', 25,...
    'String', H.YLabel);
set(get(H.Axes.Primary, 'Title'),...
    'Color', H.AxesColor,...
    'FontSize', 25,...
    'String', H.Title);


end%================================================================================================
%% Nested Functions
% Calculate individual montage element sizings & final master axes position
function [newPosition, szElement] = calculateElementSize(posUpperAxes, posInnerFig, numXElements, numYElements)
    % Calculate new montage element height & width possibilities
    testUnitSize = [posUpperAxes(3)./numXElements, posUpperAxes(4)./numYElements];
    testTotalSize = [numXElements, numYElements].*fliplr(testUnitSize);
    
    % Perform some checks to determine how to proceed with sizing
    overextended = testTotalSize > posUpperAxes(3:4);
    if any(overextended)
        szElement = testUnitSize(overextended);
    end
    
    % Calculate the new master axes positions
    totalSize = szElement.*[numXElements, numYElements];
    newPosition = [0 0 totalSize];
    newPosition(1) = (posInnerFig(1)+posInnerFig(3) - totalSize(1))./2;
    newPosition(2) = (posInnerFig(2)+posInnerFig(4) - totalSize(2))./2;
end