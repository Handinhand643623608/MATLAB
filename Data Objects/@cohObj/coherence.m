function cohData = coherence(cohData)
%COHERENCE Evaluates the magnitude squared coherence between BOLD data and EEG data
%   COHERENCE is an internal function to the coherence data object and is called during object
%   instantiation. Parameters are specified by the user during this time. 
%
%   WARNING: COHERENCE is an internal method for cohObj and is not meant to be called externally.
%
%   Written by Josh Grooms on 20130911
%       20130917:   Moved coherence frequencies to the parameters field of the object.
%       20131001:   Implemented partial coherence.
%       20131103:   Implemented RSN-EEG coherence.
%       20140121:   Updated method for control signal regression in partial coherence. Also updated correlation mask
%                   used on BOLD data to the latest version (20131126).

% TODO: Error checking for correlation objects being z-scored
% TODO: Automatic selection of correlation data masks


%% Initialize
cohParams = cohData(1, 1).Parameters;
assignInputs(cohParams.Coherence, 'varsOnly');


%% Generate the Coherence Data
% Setup progress bars
progStrs = {[cohData(1, 1).Modalities ' ' cohData(1, 1).Relation]; 
            'Scans Completed';
            'Analyzing Channels'};
progBar = progress(progStrs{:});        
previousDataSet = {'', ''};
for a = 1:size(cohData, 1)
    reset(progBar, 2);
    for b = 1:size(cohData, 2)
        if ~isempty(cohData(a, b).ParentData)
            
            % Load the data sets
            for c = 1:2
                if ~strcmpi(previousDataSet{c}, cohData(a, b).ParentData{c})
                    tempData = load(cohData(a, b).ParentData{c});
                    tempDataName = fieldnames(tempData); 
                    data{c} = tempData.(tempDataName{1});
                    previousDataSet{c} = cohData(a, b).ParentData{c};
                    clear temp*
                end
            end
            
            % Run MS coherence between data sets
            reset(progBar, 3);
            for c = 1:length(Channels)
                [extractedData, idsMask, cohParams] = extract(data, cohParams, cohData(a, b).Scan, c);
                [currentCoh, frequencies] = mscohere(extractedData{1}, extractedData{2},...
                    Window,...
                    SegmentOverlap,...
                    NFFT,...
                    min(cohParams.Coherence.Fs));
                if iscolumn(currentCoh); currentCoh = currentCoh'; frequencies = frequencies'; end
                cohData(a, b).Data.(Channels{c}) = currentCoh;
                cohData(a, b).Parameters.Coherence.Frequencies = frequencies;
                update(progBar, 3, c/length(Channels));
            end
            
            % Fill in remaining object properties
            cohData(a, b).Averaged = false;
            cohData(a, b).Filtered = false;
            cohData(a, b).FilterShift = 0;
            cohData(a, b).ZScored = false;
            
        end
        update(progBar, 2, b/size(cohData, 2));
    end
    update(progBar, 1, a/size(cohData, 1));
end
close(progBar)
clear extract

            
end%================================================================================================
%% Nested Functions
function [extractedData, idsMask, cohParams] = extract(data, cohParams, scan, c)
    % Initialize some parameters
    persistent corrData;
    load masterStructs
    idsMask = [];
    if length(scan) == 1; scan = [scan scan]; end;
    assignInputs(cohParams.Coherence, 'varsOnly');
    
    % Extract the needed data
    switch lower(cohParams.Initialization.Modalities)
        case 'bold-eeg'
            % Get the current BOLD data
            boldData = data{1}(scan(1)); 
           
            % Mask the BOLD data
            switch lower(Masking.Method)
                case 'correlation'
                    if isempty(Masking.File)
                        try % Automatically finding an appropriate correlation data set
%                             searchStr = ['partialCorrObject_' cohParams.Initialization.ScanState '_BOLD-'...
%                                           Channels{c} '_dcGSR'];
%                             Masking.File = get(fileData([fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG'], 'Search', searchStr), 'Path');
                            Masking.File = ['partialCorrObject_RS_BOLD-' Channels{c} '_dcCSRZ_20131126.mat'];
                        catch % Couldn't find one. Need to manually specify the mask
                            error(['A suitable correlation data mask could not be found. Please '...
                                  'manually specify this parameter']);
                        end
                        cohParams.Coherence.Masking = Masking;
                    end
                    
                    % Load the correlation data & mask the BOLD images with it
                    if isempty(corrData) || ~isfield(corrData(boldData.Subject, scan(1)).Data, Channels{c})
                        load(Masking.File); 
                    end
                    currentCorrObj = corrData(boldData.Subject, scan(1));
                    
                    % Mask the data with a gray matter mask
                    mask(boldData, 'gray', boldData.Preprocessing.Parameters.Conditioning.GMCutoff, NaN);
                    mask(currentCorrObj, boldData.Data.Segments.GM, boldData.Preprocessing.Parameters.Conditioning.GMCutoff, NaN);
                    
                    idxShift = currentCorrObj.Parameters.Correlation.TimeShifts == Masking.Shift;
                    corrMask = currentCorrObj.Data.(Channels{c})(:, :, :, idxShift);
                    corrMask = corrMask > norminv(Masking.Threshold, nanmean(corrMask(:)), nanstd(corrMask(:)));
                    idsMask = mask(boldData, corrMask, 0, NaN);
                    
                    % Reshape the masked functional data & average voxel series together
                    functionalData = reshape(boldData.Data.Functional, [], size(boldData.Data.Functional, 4));
                    functionalData(isnan(functionalData(:, 1)), :) = [];
                    functionalData = nanmean(functionalData, 1);
                    extractedData{1} = functionalData;
            end
            
            % Get the current EEG data
            eegData = data{2}(scan(2));
            idxChannel = strcmpi(Channels{c}, eegData.Channels);
            channelData = eegData.Data.EEG(idxChannel, :);
            channelData = resample(channelData, length(functionalData), length(channelData));
            extractedData{2} = channelData;
            
            % If partial coherence is desired, get & regress the control signals
            if strcmpi(cohParams.Initialization.Relation, 'partial coherence')
                controlData = {ones(size(extractedData{1}, 2), 1), ones(size(extractedData{1}, 2), 1)};
                nuisanceNames = {'Motion', 'Global', 'WM', 'CSF'};
                if strcmpi(cohParams.Coherence.Control, 'bold nuisance'); cohParams.Coherence.Control = nuisanceNames; end
                for a = 1:length(cohParams.Coherence.Control)
                    switch lower(cohParams.Coherence.Control{a})
                        case {'global', 'wm'}
                            controlData{1} = cat(2, controlData{1}, boldData.Data.Nuisance.(cohParams.Coherence.Control{a})');
                            controlSig = boldData.Data.Nuisance.(cohParams.Coherence.Control{a});
                            controlDelay = 4*(1/(boldData.TR/1000));
                            controlSig = [zeros(1, controlDelay) controlSig(1:end-controlDelay)];
                            controlData{2} = cat(2, controlData{2}, controlSig');
                        case {'motion', 'csf'}
                            controlData{1} = cat(2, controlData{1}, boldData.Data.Nuisance.(cohParams.Coherence.Control{a})');
                            controlData{2} = cat(2, controlData{2}, boldData.Data.Nuisance.(cohParams.Coherence.Control{a})');
                    end
                end
                
                % Regress the control signals from the data
                for a = 1:length(extractedData)
                    extractedData{a} = (extractedData{a}' - controlData{a}*(controlData{a}\extractedData{a}'))';
                end 
            end
            
            % Add some needed parameters to the parameter structure
            cohParams.Coherence.Fs = 1000/boldData.TR;
            
        case 'rsn-eeg'
            % Get the current IC data
            boldData = data{1}(scan(1));
            icNames = fieldnames(boldData.Data.ICA);
            idsMask = [];
            extractedData{1} = boldData.Data.ICA.(icNames{c});
            cohParams.Coherence.Fs(1) = 1000/boldData.TR;
            
            % Get the current EEG data
            eegData = data{2}(scan(2));
            idxChannel = strcmpi(Channels{c}, eegData.Channels);
            channelData = eegData.Data.EEG(idxChannel, :);
            extractedData{2} = channelData;
            cohParams.Coherence.Fs(2) = eegData.Fs;
            
    end
end

