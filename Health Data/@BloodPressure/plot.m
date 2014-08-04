function varargout = plot(bpData, varargin)
%PLOT
%
%   Written by Josh Grooms on 20131010
%       20131017:   Disabled plotting of accurate intervals between readings (axes labels were too crowded). Set default 
%                   plot to first data set (my data) if an object array is inputted. Added legends to plot.
%       20131102:   Completely rewrote function & implemented plots for morning vs. evening data.
%       20131105:   Completely rewrote function again to incorporate new features. Implemented the plotting of
%                   measurement dates on the x-axis. Implemented the plotting of heart rate data. Condensed plotting
%                   code. Implemented the display of measurement comments as popup windows when the date on the x-axis
%                   is clicked.


%% Initialize
% If an array is given, default to plotting the first data set
if numel(bpData) > 1; bpData = bpData(1); end

% Setup a default inputs structure
inStruct = struct(...
    'DateFormat', 'yyyymmdd',...
    'HeartRate', 'off',...
    'PlotData', 'Right-Left');
assignInputs(inStruct, varargin,...
    'compatibility', {'PlotData', 'data', 'format'});

% Initialize plot formatting parameters
plotParams = struct(...
    'Comments', [],...
    'DataStrs', {{'Systolic', 'Diastolic'}},...
    'DataIds', [],...
    'Legend', {{'Systolic', 'Mean Systolic', 'Diastolic', 'Mean Diastolic'}},...
    'LineWidth', [3 3 2],...
    'LineStyle', {{'-b', '-r', '-m'}},...
    'Subplot', [],...
    'Title', [],...
    'XTickLabels', [],...
    'YLabel', 'mmHg',...
    'YTick', 50:10:150);

% Initialize heart-rate dependent plot parameters
if istrue(HeartRate)
    plotParams.Legend = [plotParams.Legend, {'Heart Rate', 'Mean Heart Rate'}];
    plotParams.YLabel = [plotParams.YLabel '/BPM'];
    plotParams.DataStrs = [plotParams.DataStrs, {'HeartRate'}];
end

% Initialize a window object to plot data in
windowObj('size', 'fullscreen');


%% Compile All Plotting Parameters
% Determine indices of data for plotting
armStrs = {'Left', 'Right'}; 
timeStrs = {'AM', 'PM'; 'Morning', 'Evening'};
for a = 1:length(armStrs)
    idsArm.(armStrs{a}) = strcmpi(bpData.Arm, armStrs{a}(1));
    idsDates.(timeStrs{1, a}) = strcmpi(num2cell(datestr(bpData.Date, 'PM'), 2), timeStrs{1, a})';
end

% Compile all plotting parameters
switch lower(PlotData)
    case {'right-left', 'left-right'}
        plotParams(1:2) = plotParams;
        for a = 1:length(armStrs)
            idsData = idsArm.(armStrs{a});
            plotParams(a).Comments = bpData.Comment(idsData);
            plotParams(a).DataIds = idsData;
            plotParams(a).Subplot = {2, 1, a};
            plotParams(a).Title = sprintf('%s Arm Blood Pressure Readings', armStrs{a});
            plotParams(a).XTickLabels = num2cell(datestr(bpData.Date(idsData), DateFormat), 2);
        end
    case {'am-pm', 'morning-evening'}
        plotParams(1:4) = plotParams;
        idxSubplot = 1;
        for a = 1:length(timeStrs)
            for b = 1:length(armStrs)
                idsData = idsArm.(armStrs{b}) & idsDates.(timeStrs{1, a});
                plotParams(idxSubplot).Comments = bpData.Comment(idsData);
                plotParams(idxSubplot).DataIds = idsData;
                plotParams(idxSubplot).Subplot = {2, 2, idxSubplot};
                plotParams(idxSubplot).Title = sprintf('%s Arm %s Blood Pressure Readings', armStrs{b}, timeStrs{2, a});
                plotParams(idxSubplot).XTickLabels = num2cell(datestr(bpData.Date(idsData), DateFormat), 2);
                    idxSubplot = idxSubplot + 1;
            end
        end
end


%% Plot Blood Pressure Data
% Plot BP data
for a = 1:length(plotParams)
    plotBP(bpData, plotParams(a));
end


end%====================================================================================================================
%% Nested Functions
% Plot blood pressure data
function plotBP(bpData, plotParams)
    % Initialize important plot parameters
    idsData = plotParams.DataIds;
    dataStrs = plotParams.DataStrs;
    numData = sum(idsData);
    
    % Initialize axes for the data
    axHandle = subplot(plotParams.Subplot{:});
        
    % Plot each set of data & its associated average
    for a = 1:length(dataStrs)
        plot(bpData.(dataStrs{a})(idsData), plotParams.LineStyle{a}, 'LineWidth', plotParams.LineWidth(a));
        hold on
        meanData = mean(bpData.(dataStrs{a})(idsData));
        plot(ones(1, numData).*meanData, ['-' plotParams.LineStyle{a}], 'LineWidth', plotParams.LineWidth(a)-1);
        windowHandle.Text.Mean{a}(a) = text(...
            numData+0.01*numData,...
            meanData,...
            sprintf('%.1f', meanData),...
            'FontSize', 14,...
            'Color', plotParams.LineStyle{a}(2));
    end

    % Adjust axes parameters
    set(axHandle,...
        'XTick', 1:sum(plotParams.DataIds),...
        'XTickLabel', [],...
        'XLim', [1 sum(idsData)],...
        'YTick', plotParams.YTick,...
        'YLim', [plotParams.YTick(1), plotParams.YTick(end)]);
    grid on
    
    % Label the plot
    labelDates(axHandle, plotParams.XTickLabels, plotParams.Comments);
    ylabel(plotParams.YLabel, 'FontSize', 14);
    title(plotParams.Title, 'FontSize', 16);
    legend(axHandle, plotParams.Legend{:}, 'Location', 'NorthEastOutside');
end

% Label axis tick marks
function labelDates(axHandle, labels, comments)
    posTicks = {get(axHandle, 'XTick'), get(axHandle, 'YTick')};
    posY = posTicks{2}(1) - 0.1*diff(posTicks{2}(1:2));
    for a = 1:length(labels)
        text(...
            posTicks{1}(a),...
            posY,...
            labels{a},...
            'Rotation', 90,...
            'HorizontalAlignment', 'right',...
            'ButtonDownFcn', {@commentPopup, labels{a}, comments{a}});
    end
end 

% Display comments when a date is clicked
function commentPopup(~, ~, date, comment)
    if ~isempty(comment)
        msgbox(comment, date);
    end
end
        