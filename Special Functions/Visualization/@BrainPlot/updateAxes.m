function UpdateAxes(brainData, sourceData, ~)
%UPDATEAXES Updates axes labels & properties as they are changed externally.
%
%   WARNING: UPDATEAXES is an internal method for brainPlot and is not meant to be called
%   externally.

%% CHANGELOG
%   Written by Josh Grooms on 20130626



%% Initialize
% Get name of the property that changed
propName = sourceData.Name;



%% Set the Corresponding Axes Properties
switch propName
    case 'AxesColor'
        set(brainData.Axes.Primary, 'XColor', brainData.(propName), 'YColor', brainData.(propName));
    case 'Color'
        if ~isempty(brainData.Axes);
            for a = 1:size(brainData.Axes.Montage, 1)
                for b = 1:size(brainData.Axes.Montage, 2)
                    set(brainData.Axes.Montage(a, b), 'Color', brainData.Color);
                end
            end
        end
    case 'ColorbarLabel'
        set(get(brainData.Colorbar, 'YLabel'), 'String', brainData.ColorbarLabel);
    case {'XLabel', 'YLabel', 'Title'}
        set(get(brainData.Axes.Primary, propName), 'String', brainData.(propName));
    case {'XTickLabel', 'YTickLabel'}               
        set(brainData.Axes.Primary, propName, brainData.(propName));
end