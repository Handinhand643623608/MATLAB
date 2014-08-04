function corrData = correlation(corrData)
%CORRELATION Correlate neurophysiological data.
%
%   WARNING: CORRELATION is an internal method for corrObj and is not meant to be called externally.
%
%   Written by Josh Grooms on 20130702
%       20130709:   Updated to work with new function "xcorrArr", which cuts down on computation time requirements. 
%                   Updated to use mean functional images as brain masks to lower computation time. Also updated
%                   references to BOLD data objects, the layout of which has changed.
%       20130711:   Bug fix for null generation modality determination being case sensitive.
%       20130719:   Bug fix for nuisance string capitalization in null data generation modality switch.
%       20130728:   Implemented partial correlation for EEG-BOLD relationships (with nuisance signals as the controlling 
%                   variables).
%       20130803:   Updated for compatibility with updated progress bar code.
%       20130811:   Implemented Fisher's normalized r-to-z transformation to prevent bias introduced during the 
%                   averaging of correlation coefficients.
%       20130906:   Completely re-wrote function to be more flexible on data sets being correlated.
%       20131029:   Implemented RSN-EEG correlations & BOLD nuisance-BOLD correlations.
%       20131126:   Implemented BOLD-RSN correlations for testing how well ICA is doing its job.
%       20131222:   Implemented BOLD-Motion nuisance parameter correlations.


%% Initialize
% Initialize correlation parameters
ccParams = corrData(1, 1).Parameters;
assignInputs(ccParams.Correlation, 'varsOnly');
sampleShifts = round(TimeShifts.*Fs);
maxLags = sampleShifts(end);

% Warning for temporary code placement
warning('Temporary code exists in correlation function. Is this intended?');


%% Generate the Correlation Data
% Setup progress bars
progStrs = {[corrData(1, 1).Modalities ' Correlation'];
            'Scans Completed';
            'Correlating Individual Data'};
progBar = progress(progStrs{:});        
previousDataSet = {'', ''};
for a = 1:size(corrData, 1)
    reset(progBar, 2);
    for b = 1:size(corrData, 2)
        if ~isempty(corrData(a, b).ParentData)
            
            % Load the data sets
            for c = 1:2
                if c == 2 && strcmpi(corrData(a, b).ParentData{:})
                    data{2} = data{1};
                elseif ~strcmpi(previousDataSet{c}, corrData(a, b).ParentData{c})
                    tempData = load(corrData(a, b).ParentData{c});
                    tempDataName = fieldnames(tempData); 
                    data{c} = tempData.(tempDataName{1});
                    previousDataSet{c} = corrData(a, b).ParentData{c};
                    clear temp*
                end
            end
            
            % Change scans for compatibility with null data generation
            scan = corrData(a, b).Scan;
            if length(scan) == 1; scan = [scan scan]; end;
            
            % Run cross correlation between data sets
            reset(progBar, 3)
            for c = 1:length(DataStrs)
                [extractedData, idsMask] = extract(data, ccParams, scan, c);
                currentCorr = xcorrArr(extractedData{1}, extractedData{2}, 'Dim', 2, 'MaxLag', maxLags);
                currentCorr = corrData.transform(currentCorr, size(extractedData{1}, 2));
                corrData(a, b).Data.(DataStrs{c}) = unmask(currentCorr, idsMask);
                update(progBar, 3, c/length(DataStrs));
            end
            
            % Fill in remaining object properties
            corrData(a, b).Averaged = false;
            corrData(a, b).Filtered = false;
            corrData(a, b).FilterShift = 0;
            corrData(a, b).ZScored = true;
            
        end
        update(progBar, 2, b/size(corrData, 2));
    end
    update(progBar, 1, a/size(corrData, 1));
end
close(progBar)


end%====================================================================================================================
%% Nested Functions
% Extract the correct data from the data objects
function [extractedData, idsMask] = extract(data, ccParams, scan, c)
    switch lower(ccParams.Initialization.Modalities)
        case 'bold-eeg'
            % Get the current BOLD data
            boldData = data{1}(scan(1));
            functionalData = reshape(boldData.Data.Functional, [], size(boldData.Data.Functional, 4)); 
            idsMask = isnan(functionalData(:, 1));
            functionalData(idsMask, :) = [];
            extractedData{1} = functionalData;

            % Get the current EEG data
            eegData = data{2}(scan(2));
            idxChannel = strcmpi(ccParams.Correlation.DataStrs{c}, eegData.Channels);
            extractedData{2} = eegData.Data.EEG(idxChannel, :);
            
        case 'bold-rsn'
            % Get the current BOLD data
            boldData = data{1}(scan(1));
            functionalData = reshape(boldData.Data.Functional, [], size(boldData.Data.Functional, 4)); 
            idsMask = isnan(functionalData(:, 1));
            functionalData(idsMask, :) = [];
            extractedData{1} = functionalData;
            
            % Get the current IC data
            boldData = data{1}(scan(1));
            icNames = fieldnames(boldData.Data.ICA);
            extractedData{2} = boldData.Data.ICA.(icNames{c});
            
        case 'rsn-eeg'
            % Get the current IC data
            boldData = data{1}(scan(1));
            icNames = fieldnames(boldData.Data.ICA);
            idsMask = [];
            extractedData{1} = boldData.Data.ICA.(icNames{c});
            
            % Get the current EEG data
            eegData = data{2}(scan(2));
            extractedData{2} = eegData.Data.EEG;
            
        case 'bold-bold nuisance'
            % Get the current BOLD data
            boldData = data{1}(scan(1));
            functionalData = reshape(boldData.Data.Functional, [], size(boldData.Data.Functional, 4)); 
            idsMask = isnan(functionalData(:, 1));
            functionalData(idsMask, :) = [];
            extractedData{1} = functionalData;
            
            % Get the current nuisance data
            extractedData{2} = boldData.Data.Nuisance.(ccParams.Correlation.DataStrs{c});
            
        case 'bold-motion'
            % Get the current BOLD data
            boldData = data{1}(scan(1));
            functionalData = reshape(boldData.Data.Functional, [], size(boldData.Data.Functional, 4)); 
            idsMask = isnan(functionalData(:, 1));
            functionalData(idsMask, :) = [];
            extractedData{1} = functionalData;
            
            % Get the motion data
            idxMotion = eval(ccParams.Correlation.DataStrs{c}(end));
            extractedData{2} = boldData.Data.Nuisance.Motion(idxMotion, :);         
            
            % TEMPORARY (REMOVE BEFORE NEXT RUN) - Regress motion signal from BOLD data
            extractedData{1} = (extractedData{1}' - extractedData{2}'*(extractedData{2}'\extractedData{1}'))';
    end
end

% Unmask BOLD data
function finalData = unmask(currentCorr, idsMask)
    if ~isempty(idsMask)
        tempCorr = nan([length(idsMask) size(currentCorr, 2)]);
        tempCorr(~idsMask, :) = currentCorr;
        finalData = reshape(tempCorr, [91, 109, 91, size(currentCorr, 2)]);
    else
        finalData = currentCorr;
    end
end