function meanSpectralData = mean(spectralData)
%MEAN Averages together electrode-specific spectral data.
% 
%   Written by Josh Grooms on 20130910


%% Initialize
% Initialize a mean spectral data object
meanSpectralData = spectralObj;

% Get the names of the data fields & dimension over which to concatenate
dataNames = spectralData(1, 1).Channels;
catDim = ndims(spectralData(1, 1).Data.(dataNames{1})) + 1;

% Loop through the data object, concatenate data, & average
for a = 1:length(dataNames)
    currentData = [];
    for b = 1:size(spectralData, 1)
        for c = 1:size(spectralData, 2)
            if ~isempty(spectralData(b, c).Data)
                currentData = cat(catDim, currentData, spectralData(b, c).Data.(dataNames{a}));
            end
        end
    end
    meanSpectralData.Data.(dataNames{a}).Mean = nanmean(currentData, catDim);
    meanSpectralData.Data.(dataNames{a}).SEM = nanstd(currentData, [], catDim)./sqrt(size(currentData, catDim));
end
transferProperties(spectralData, meanSpectralData);


end%================================================================================================
%% Nested Functions
function transferProperties(spectralData, meanSpectralData)
    propNames = properties(spectralData(1, 1));
    exclusionStrs = {'Data', 'StorageDate', 'StoragePath'};
    propNames(ismember(propNames, exclusionStrs)) = [];
    for a = 1:length(propNames)
        switch lower(propNames{a})
            case 'averaged'
                meanSpectralData.Averaged = true;
            case 'parentdata'
                meanSpectralData.ParentData = compileParentData(spectralData);
            case {'subject', 'scan'}
                meanSpectralData.Subject = spectralData(1, 1).Parameters.Initialization.Subjects;
                meanSpectralData.Scan = spectralData(1, 1).Parameters.Initialization.Scans;
            otherwise
                meanSpectralData.(propNames{a}) = spectralData(1, 1).(propNames{a});
        end
    end
    meanSpectralData.Data.Frequencies = spectralData(1, 1).Data.Frequencies;
    meanSpectralData.ZScored = false;
end

function parentData = compileParentData(spectralData)
    parentData = {};
    for a = 1:size(spectralData, 1)
        for b = 1:size(spectralData, 2)
            if ~isempty(spectralData(a, b).ParentData)
                parentData = cat(1, parentData, spectralData(a, b).ParentData);
                break
            end
        end
    end
end