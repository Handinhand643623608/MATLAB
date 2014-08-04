function meanRelationData = mean(relationData)
%MEAN Averages together data within the relation data object for group-wise analyses.
%
%   SYNTAX:
%   meanRelationData = mean(relationData)
%
%   OUTPUTS:
%   meanRelationData:
%
%   PROPERTY NAMES:
%   relationData:
%
%   Written by Josh Grooms on 20130428


%% Initalize
% Get important properties from the data object
relation = relationData(1, 1).Relation;
dataFields = fieldnames(relationData(1, 1).Data.(relation));
propNames = fieldnames(relationData);

% Initalize the output variable
meanRelationData = relationObj;
meanRelationData.Data.(relation) = [];
meanRelationData.ParentBOLD = {};


%% Concatenate the Data
switch lower(relation)
    % Determine the analysis that was run
    case 'coherence'
        
        % The number of elements determines null or true distributions
        switch numel(relationData)
            % A single-element relationData object indicates the null data
            case 1
                for a = 1:length(dataFields)
                    
                    % Randomize the ordering of the data
                    currentData = relationData.Data.Coherence.(dataFields{a});
                    randOrder = randperm(size(currentData, 1));
                    currentData = currentData(randOrder, :);
                    
                    % Group the data by the number of scans included in the analysis
                    numPerGroup = length(cat(2, relationData.Parameters.Scans{:}));
                    tempData = zeros(numPerGroup, size(currentData, 2), (size(currentData, 1)/numPerGroup)); 
                    for b = 1:size(tempData, 3)
                        tempData(:, :, b) = currentData(1:numPerGroup, :);
                        currentData(1:numPerGroup, :) = [];
                    end
                    relationData.Data.Coherence.(dataFields{a}) = tempData;
                end
                
                % Change variable names (avoid having to transfer properties)
                meanRelationData = relationData;
                
            % Other data is stored as an object array
            otherwise
                for a = 1:size(relationData, 1)
                    for b = 1:size(relationData, 2);
                        if ~isempty(relationData(a, b).Data)
                            for c = 1:length(dataFields)

                                % Concatenate the data together
                                currentData = relationData(a, b).Data.Coherence.(dataFields{c});
                                if ~isfield(meanRelationData.Data.Coherence, dataFields{c})
                                    meanRelationData.Data.Coherence.(dataFields{c}) = currentData;
                                else
                                    meanRelationData.Data.Coherence.(dataFields{c}) = ...
                                        cat(1, meanRelationData.Data.Coherence.(dataFields{c}), currentData);
                                end

                            end
                            
                            % Transfer other object properties
                            meanRelationData.Data.Frequencies = relationData(a, b).Data.Frequencies;
                            meanRelationData.Scan{a}(b) = b;
                        end
                    end
                    % Transfer other object properties
                    meanRelationData.Subject = cat(2, meanRelationData.Subject, a);
                    meanRelationData.ParentBOLD = cat(1, meanRelationData.ParentBOLD, relationData(a, 1).ParentBOLD);
                end
                
                % Transfer the rest of the object properties not dependent on subject/scan
                for  a = 1:length(propNames)
                    switch propNames{a}
                        case {'ParentBOLD', 'Data', 'StoragePath', 'Scan', 'Subject', 'ScanDate'}
                            continue
                        otherwise
                            meanRelationData.(propNames{a}) = relationData(1, 1).(propNames{a});
                    end
                end                
        end
        
        % Set the dimension to average over
        dimToAverage = 1;
end


%% Average the data together
for a = 1:length(dataFields)
    currentData = meanRelationData.Data.(relation).(dataFields{a});
    
    meanRelationData.Data.SEM.(dataFields{a}) = std(currentData, [], dimToAverage)./sqrt(size(currentData, dimToAverage));
    meanRelationData.Data.(relation).(dataFields{a}) = mean(currentData, dimToAverage);
end

                    
                
                