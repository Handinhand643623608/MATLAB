function meanCohData = mean(cohData)
%MEAN Averages together coherence data within the data object.
%   This function generates means for group-wise analysis using the supplied coherence data object.
%   MEAN performs no other function beyond MATLAB native functionality except for handling of the
%   data object properties. This function also averages together null comparison data by first
%   organizing the data into groupings that are the same size as the real comparison data. 
%
%   SYNTAX:
%   meanCohData = mean(cohData)
%
%   OUTPUTS:
%   meanCohData:        The mean coherence data object containing either averaged real or null
%                       comparisons between EEG and BOLD data.
%
%   INPUTS:
%   cohData:            The coherence data object containing single-run real or null comparisons
%                       between EEG and BOLD data.
%
%   Written by Josh Grooms on 20130614


%% Initialize
dataFields = fieldnames(cohData(1, 1).Data);
dataFields(strcmpi(dataFields, 'Frequencies')) = [];
propNames = fieldnames(cohData);

% Initialize the output variable
meanCohData = cohObj;
meanCohData.Data = [];
meanCohData.ParentData = {};


%% Average the Data
% Determine if data is from a null or real comparison
switch cohData(1, 1).Relation(1:4)        
    case 'Null'

        for a = 1:length(dataFields)
            % Randomize the ordering of the data
            currentData = cohData.Data.Coherence.(dataFields{a});
            randOrder = randperm(size(currentData, 1));
            currentData = currentData(randOrder, :);

            % Group the data by the number of scans included in the analysis
            numPerGroup = length(cat(2, cohData.Parameters.Scans{:}));
            tempData = zeros(numPerGroup, size(currentData, 2), (size(currentData, 1)/numPerGroup)); 
            for b = 1:size(tempData, 3)
                tempData(:, :, b) = currentData(1:numPerGroup, :);
                currentData(1:numPerGroup, :) = [];
            end
            cohData.Data.Coherence.(dataFields{a}) = tempData;
        end

        % Change variable names (avoid having to transfer properties)
        meanCohData = cohData;

    otherwise

        for c = 1:length(dataFields)
            meanCohData.Data.(dataFields{c}) = [];
            for a = 1:size(cohData, 1)
                for b = 1:size(cohData, 2);
                    if ~isempty(cohData(a, b).Data)
                        % Concatenate the data together
                        currentData = cohData(a, b).Data.(dataFields{c});
                        catDim = ndims(currentData) + 1;
                        meanCohData.Data.(dataFields{c}) = cat(catDim, meanCohData.Data.(dataFields{c}), currentData);

                        % Transfer other object properties
                        meanCohData.Scan{a}(b) = b;
                    end
                end
                
                % Transfer other object properties
                meanCohData.Subject = cat(2, meanCohData.Subject, a);
                meanCohData.ParentData = cat(1, meanCohData.ParentData, cohData(a, 1).ParentData);
            end
            
            % Average the data together
            tempData = meanCohData.Data.(dataFields{c});
            numSamples = sum((~isnan(tempData)), catDim);
            meanCohData.Data.(dataFields{c}).Mean = nanmean(tempData, catDim);
            meanCohData.Data.(dataFields{c}).SEM = nanstd(tempData, [], catDim)./sqrt(numSamples);
            clear temp*;
        end

        % Transfer the rest of the object properties not dependent on subject/scan
        for  a = 1:length(propNames)
            switch propNames{a}
                case {'ParentData', 'Data', 'StoragePath', 'Scan', 'Subject', 'ScanDate'}
                    continue
                otherwise
                    meanCohData.(propNames{a}) = cohData(1, 1).(propNames{a});
            end
        end                
end
meanCohData.Averaged = true;