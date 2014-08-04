function threshold(meanCorrData, meanNullData)
%THRESHOLD Thresholds correlation values for statistical significance.
%   This function accepts two correlation data objects: the first is a real data comparison, the second is the null data
%   comparison. It then generates statistical significance cutoffs from these data and stores them in the mean data's
%   "Parameters" section. If a null data set is not supplied, this function automatically generates and saves one.
%
%   SYNTAX:
%   threshold(meanCorrData, meanNullData)
%   threshold(meanCorrData)
%
%   OUTPUT:
%   meanCorrData:       The correlation data object with statistical significance thresholds stored within the 
%                       "Parameters" property.
%
%   INTPUT:
%   meanCorrData:       An averaged correlation data object.
%
%   OPTIONAL INPUT:
%   meanNullData:       An averaged null distribution of correlation values. If not provided, this function 
%                       automatically generates these data using parameters found within the mean correlation data
%                       object.
%
%   Written by Josh Grooms on 20130702
%       20130709:   Bug fix for variable name typo. Overhaul of null generation setup at beginning of function.
%       20130711:   Removed output variable (not needed)
%       20130717:   Added a warning dialog to null distribution generation in case one is already available (since this 
%                   takes forever). Added ability to mask the correlation data to speed up processing. P-value
%                   generation & thresholds are now stored iteratively as the process progresses.
%       20130719:   Bug fix for null generation potentially not using the same parent data sets as the input mean
%                   (hasn't affected anything so far, though). 
%       20130728:   Added in variable name assignment to STORE function for object so it doesn't stop the thresholding 
%                   process to ask for input.
%       20130803:   Updated for compatibility with updated progress bar code.
%       20130920:   Updated to work with overhauled object parameter field.
%       20131028:   Changed default signifance cutoffs (when no actual significance is found) to infinite.


%% Initialize
% Generate a null data set, if needed
if nargin == 1 && strcmpi(meanCorrData.Parameters.Thresholding.CDFMethod, 'arbitrary')
%     % Warn the user about the impending wait, in case a null is already available
%     dlgStr = sprintf(['Arbitrary p-value generation requires a null distribution. '...
%         'Generating one may require a very long time. If one is already available, you should '...
%         'input it into this function.\n\nWould you like to generate a null data set now?']);
%     userAnswer = questdlg(...
%         dlgStr,...
%         'Generate Null Distribution?',...
%         'Yes', 'No', 'No');
%     if strcmpi(userAnswer, 'no')
%         return
%     end
    
    % Set up the null data generation parameters
    nullParams = meanCorrData.Parameters;
    nullParams.Correlation.GenerateNull = true;
    nullData = corrObj(nullParams);
    store(nullData);    
    meanNullData = mean(nullData);
    store(meanNullData)
    clear nullData temp* nullParams
end

% Get data parameters
assignInputs(meanCorrData.Parameters.Thresholding, 'varsOnly');
if ~isempty(meanCorrData.StoragePath)
    [dirPart, filePart, ~] = fileparts(meanCorrData.StoragePath);
end
DataStrs = meanCorrData.Parameters.Correlation.DataStrs;


%% Determine Significance Cutoffs
progBar = progress('Evaluating Statistical Significance of Correlations');
for a = 1:length(DataStrs)
    % Get the current correlation data
    currentCorr = meanCorrData.Data.(DataStrs{a});
    
    % Get the null data, if needed & provided
    if exist('meanNullData', 'var')
        currentNull = meanNullData.Data.(DataStrs{a});
    else
        currentNull = [];
    end
    
    % Mask the data, if called for
    if ~isempty(Mask)
        if isnumeric(Mask)
            currentCorr = mask(currentCorr, Mask, MaskThreshold);
            idxStr = repmat({':'}, 1, ndims(currentNull));
            for b = 1:size(currentNull, ndims(currentNull))
                idxStr{end} = b;
                currentNull(idxStr{:}) = mask(currentNull(idxStr{:}), Mask, MaskThreshold);
            end
        end
    end
    
    % Convert the parameter structure into a variable list & threshold
    threshVars = struct2var(meanCorrData.Parameters.Thresholding, {'Mask', 'MaskThreshold'});
    [pvals, lowerCutoff, upperCutoff] = threshold(currentCorr, currentNull, threshVars{:});
    
    % Deal with lack of significance
    if isnan(lowerCutoff), lowerCutoff = -inf; end
    if isnan(upperCutoff), upperCutoff = inf; end

    % Store the cutoff values & generated p-values in the data object
    meanCorrData.Parameters.SignificanceCutoffs.(DataStrs{a}) = [lowerCutoff, upperCutoff];
    meanCorrData.Data.PValues.(DataStrs{a}) = pvals;
    
%     % Store the thresholds & p-values on the hard drive. Overwrite previous instances
%     if exist('filePart', 'var')
%         store(meanCorrData, 'Name', filePart, 'Path', dirPart, 'varName', 'meanCorrData');
%     else
%         store(meanCorrData)
%         [dirPart, filePart, ~] = fileparts(meanCorrData.StoragePath);
%     end
    
    update(progBar, a/length(DataStrs));
end
close(progBar)

end%================================================================================================
%% Nested Functions
function outData = mask(inData, Mask, MaskThreshold)
    szMask = size(Mask);
    Mask = reshape(Mask, [], 1);
    outData = reshape(inData, [], size(inData, ndims(inData)));
    Mask = Mask > MaskThreshold;
    outData(~Mask, :) = 0;
    outData = reshape(outData, [szMask size(outData, 2)]);
end


