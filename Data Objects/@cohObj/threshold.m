function meanCohData = threshold(meanCohData, meanNullData)
%THRESHOLD Converts real and null data into a probability distribution for determining significance.
%   This function accepts two coherence data objects: the first is the real data comparison, the
%   second is the null comparison. If a null data set is not supplied, this function automatically
%   generates and saves one. 
%
%   SYNTAX:
%   cohData = threshold(meanCohData, meanNullData)
%   cohData = threshold(meanCohData)
%
%   INPUTS: 
%   meanCohData:        The coherence data object containing averaged real comparisons between
%                       appropriately matched data.
%
%   OPTIONAL INPUTS:
%   meanNullData:       The coherence data object containing the averaged null comparisons between
%                       inappropriately matched data.
%
%   Written by Josh Grooms on 20131001


%% Generate a Null Data Set, if Needed
if nargin == 1
    nullParams = meanCohData.Parameters;
    nullParams.Coherence.GenerateNull = true;
    nullData = cohObj(nullParams);
    store(nullData);
    meanNullData = mean(nullData);
    store(meanNullData)
    clear nullData temp* nullParams
end

% Get data parameters
if ~isempty(meanCohData.StoragePath)
    [dirPart, filePart, ~] = fileparts(meanCohData.StoragePath);
end
dataFields = fieldnames(meanCohData.Data);


%% Determine Signficiance Cutoffs
progBar = progress('Evaluating Statistical Significance of Coherence');
for a = 1:length(dataFields)
    % Get the current data
    currentCohData = meanCohData.Data.(dataFields{a}).Mean;
    currentNullData = meanNullData.Data.(dataFields{a}).Mean;
    
    % Convert the parameter structure into a variable list & threshold
    threshVars = struct2var(meanCohData.Parameters.Thresholding);
    [pvals, upperCutoff] = threshold(currentCohData, currentNullData, threshVars{:});
    
    % Deal with lack of significance
    if isnan(upperCutoff); upperCutoff = 1; end;
    
    % Store the cutoff values & generated p-values in the data object
    meanCohData.Parameters.SignificanceCutoffs.(dataFields{a}) = upperCutoff;
    meanCohData.Data.(dataFields{a}).PValues = pvals;
    
    % Store the thresholds & p-values to the hard drive. Overwrite previous files
    if exist('filePart', 'var')
        store(meanCohData, 'Name', filePart, 'Path', dirPart, 'varName', 'meanCohData');
    else
        store(meanCohData)
        [dirPart, filePart, ~] = fileparts(meanCohData.StoragePath);
    end
    
    update(progBar, a/length(dataFields));
end
close(progBar)