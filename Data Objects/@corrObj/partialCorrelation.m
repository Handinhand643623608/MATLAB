function partialCorrelation(corrData)
%PARTIALCORRELATION Run cross partial correlation between data sets
%
%   WARNING: this function is an internal method and is not meant to be called externally.
%
%   Written by Josh Grooms on 20130906
%       20130920:   Improved data masking & unmasking so it's less error prone.
%       20130923:   Major bug fix in control signal regression. Took formula for control signal regression from native 
%                   PARTIALCORR. Verified that new outputs of this function match the MATLAB native function.
%       20131027:   Implemented RSN-EEG partial correlations.
%       20131126:   Implemented 4s time delays in certain control signals being regressed from EEG data (0 delay when
%                   regressing from BOLD or RSN data). Also implemented the ability to select which nuisance signals are
%                   being controlled for (using the related input in the parameter structure).
%       20140217:   Created new nested functions to handle control variable regression (allows more flexibility in what
%                   parameters are regressed and how). Implemented BOLD-Global partial correlations.


%% Initialize
ccParams = corrData(1, 1).Parameters;
assignInputs(ccParams.Correlation, 'varsOnly');
sampleShifts = round(TimeShifts.*Fs);
maxLags = sampleShifts(end);


%% Generate the Correlation Data
% Setup progress bars
progStrs = {[corrData(1, 1).Modalities ' Partial Correlation'];
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
                if ~strcmpi(previousDataSet{c}, corrData(a, b).ParentData{c})
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
            
            % Run cross partial correlation between data sets
            reset(progBar, 3);
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

            
end%================================================================================================
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

            % Get the current EEG data & regress control signals
            eegData = data{2}(scan(2));
            idxChannel = strcmpi(ccParams.Correlation.DataStrs{c}, eegData.Channels);
            extractedData{2} = eegData.Data.EEG(idxChannel, :);
            
            % Regress the control data
            boldControlData = initializeControlData(boldData, ccParams.Correlation.Control, 0);
            eegControlData = initializeControlData(boldData, ccParams.Correlation.Control, 4);
            extractedData{1} = regress(extractedData{1}, boldControlData);
            extractedData{2} = regress(extractedData{2}, eegControlData);
            
        case 'bold-global'
            % Get the current BOLD data
            boldData = data{1}(scan(1)); 
            functionalData = reshape(boldData.Data.Functional, [], size(boldData.Data.Functional, 4));
            idsMask = isnan(functionalData(:, 1));
            functionalData(idsMask, :) = [];
            extractedData{1} = functionalData;
            
            % Get the current global signal
            extractedData{2} = boldData.Data.Nuisance.Global;
            
            % Regress the control data
            controlData = initializeControlData(boldData, ccParams.Correlation.Control, 0);
            extractedData{1} = regress(extractedData{1}, controlData);
            
        case 'rsn-eeg'
            % Get the current IC data
            boldData = data{1}(scan(1));
            icNames = fieldnames(boldData.Data.ICA);
            idsMask = [];
            extractedData{1} = boldData.Data.ICA.(icNames{c});
            
            % Get the current EEG data
            eegData = data{2}(scan(2));
            extractedData{2} = eegData.Data.EEG;
            
            % Regress the control data
            boldControlData = initializeControlData(boldData, ccParams.Correlation.Control, 0);
            eegControlData = initializeControlData(boldData, ccParams.Correlation.Control, 4);
            extractedData{1} = regress(extractedData{1}, boldControlData);
            extractedData{2} = regress(extractedData{2}, eegControlData);
    end
end

% Initialize an array of control data
function controlData = initializeControlData(boldData, controlStrs, delay)
    if ~iscell(controlStrs); controlStrs = {controlStrs}; end
    controlData = ones(size(boldData.Data.Functional, 4), 1);
    for a = 1:length(controlStrs)
        switch lower(controlStrs{a})
            case {'global', 'wm'}
                controlSig = boldData.Data.Nuisance.(controlStrs{a});
                controlDelay = delay*(1/(boldData.TR/1000));
                controlSig = [zeros(1, controlDelay) controlSig(1:end-controlDelay)];
                controlData = cat(2, controlData, controlSig');
            otherwise
                controlData = cat(2, controlData, boldData.Data.Nuisance.(controlStrs{a})');
        end
    end
end

% Regress a control signal from the data
function regData = regress(inData, controlData)
    regData = (inData' - controlData*(controlData\inData'))';
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