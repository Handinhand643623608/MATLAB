function relationData = bootstrap(relationData, nullData)
%BOOTSTRAP Converts real and null data into a probability distribution for determining measurement
%   significance. This function accepts two relation objects: the first is the real data, the
%   second is the null data.
%
%   Written by Josh Grooms on 20130429


%% Bootstrap for Signficiance Cutoffs
relation = relationData.Relation;
dataFields = fieldnames(relationData.Data.(relation));

for a = 1:length(dataFields)
    % Flatten the real data
    currentRealData = relationData.Data.(relation).(dataFields{a})(:);
    currentRealData(isnan(currentRealData)) = 0;
    currentRealData(currentRealData == 0) = [];
    
    % Flatted the null data
    currentNullData = nullData.Data.(relation).(dataFields{a})(:);
    currentNullData(isnan(currentNullData)) = 0;
    currentNullData(currentNullData == 0) = [];
    
    % Convert data to p-values & use SGoF for cutoffs
    cdfVals = pval_arbitrary(currentRealData, currentNullData, 'h');
    [~, currentCutoff] = matlab_sgof(cdfVals, 0.05);
    
    % Convert p-value cutoffs to data value cutoffs
    if ~isempty(currentCutoff)
        currentRealData = currentRealData(cdfVals <= currentCutoff);
        currentCutoff = min(currentRealData(currentRealData > 0));
    end
    
    % Deal with empty cutoff values
    if isempty(currentCutoff)
        currentCutoff = 1;
        warning(['No significant cutoff found for ' dataFields{a}]);
    end
    
    % Store the cutoffs in the real data parameter section
    relationData.Parameters.Cutoffs.(dataFields{a}) = currentCutoff;
end