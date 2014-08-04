function u_bandpassFilter(fileStruct, paramStruct)

%% Initialize
% Load the raw EEG data
load eegData_raw

% Initialize function-specific parameters
bandStr = paramStruct.preprocess.EEG.analysisBand;
if isempty(paramStruct.preprocess.EEG.(bandStr).subjects)
    subjects = paramStruct.general.subjects;
    scans = paramStruct.general.scans;
else
    subjects = paramStruct.preprocess.EEG.(bandStr).subjects;
    scans = paramStruct.preprocess.EEG.(bandStr).scans;
end
newFs = paramStruct.preprocess.EEG.(bandStr).newFs;
propBandStr = paramStruct.preprocess.EEG.(bandStr).propBandStr;

% Initialize the output data structure
filtEEG_data(length(subjects), paramStruct.general.maxScans) = struct('data', [], 'info', []);

%% Filter the Data to the Alpha Band (8-13 Hz)
progressStr = [propBandStr ' EEG Data Generation'];
progressbar(progressStr, 'Scans Finished')
for i = subjects
    for j = scans{i}
        % Reset the progress bar
        progressbar([], 0)
        
        % Get the current EEG data to be filtered
        currentEEG = EEG_data(i, j).data.EEG';
        currentBCG = EEG_data(i, j).data.BCG';
        currentFs = EEG_data(i, j).info.Fs;
        
        % Filter the data
        switch paramStruct.preprocess.EEG.(bandStr).filterType
            case 'bfilt'
                currentEEG = bfilt(...
                    currentEEG,...
                    paramStruct.preprocess.EEG.(bandStr).bandpass(1),...
                    paramStruct.preprocess.EEG.(bandStr).bandpass(2),...
                    currentFs, 0);
                currentSampleShift = 0;
                if ~isempty(currentBCG)
                    currentBCG = bfilt(...
                        currentBCG,...
                        paramStruct.preprocess.EEG.(bandStr).bandpass(1),...
                        paramStruct.preprocess.EEG.(bandStr).bandpass(2),...
                        currentFs, 0);
                end
            case 'fir1'
                [currentEEG currentSampleShift] = firfilt(...
                    currentEEG,...
                    paramStruct.preprocess.EEG.(bandStr).bandpass(1),...
                    paramStruct.preprocess.EEG.(bandStr).bandpass(2),...
                    currentFs,...
                    paramStruct.preprocess.EEG.(bandStr).filtParams);
                if ~isempty(currentBCG)
                    [currentBCG ~] = firfilt(...
                        currentBCG,...
                        paramStruct.preprocess.EEG.(bandStr).bandpass(1),...
                        paramStruct.preprocess.EEG.(bandStr).bandpass(2),...
                        currentFs,...
                        paramStruct.preprocess.EEG.(bandStr).filtParams);
                end
            case 'user'
                currentEEG = apply_fft_filter(...
                    currentEEG,...
                    currentFs,...
                    paramStruct.preprocess.EEG.(bandStr).filtParams(1),...
                    paramStruct.preprocess.EEG.(bandStr).filtParams(2));
                currentSampleShift = 0;
                if ~isempty(currentBCG)
                    currentBCG = apply_fft_filter(...
                        currentBCG,...
                        currentFs,...
                        paramStruct.preprocess.EEG.(bandStr).filtParams(1),...
                        paramStruct.preprocess.EEG.(bandStr).filtParams(2));
                end
            case 'zeroPhaseFIR'
                h = fdesign.bandpass(...
                    'N,Fc1,Fc2',...
                    round(paramStruct.preprocess.EEG.(bandStr).filtParams*currentFs),...
                    paramStruct.preprocess.EEG.(bandStr).bandpass(1),...
                    paramStruct.preprocess.EEG.(bandStr).bandpass(2),...
                    currentFs);
                Hd = design(h);
                currentEEG = filtfilt(Hd.Numerator, 1, currentEEG);
                if ~isempty(currentBCG)
                    currentBCG = filtfilt(Hd.Numerator, 1, currentBCG);
                end
                currentSampleShift = 0;
            otherwise
                error('Unknown filter type input. EEG data cannot be filtered')
        end
        
        if strcmp(bandStr, 'alpha')
            % Determine exact center frequency (around 12 Hz) for notch
            currentFFT = abs(real(fft(currentEEG(:, 20))));
            notchRange = currentFFT(5000:6000);
            notchRangeMax = max(notchRange);
            notchInd = find(currentFFT == notchRangeMax);
            notchFreq = notchInd(1)*(currentFs/size(currentEEG, 1));

            % 12 Hz notch filter (to remove unknown acquisition noise)
            currentD = fdesign.notch('N,F0,Q', paramStruct.preprocess.EEG.(bandStr).filtParams, notchFreq, 30, currentFs);
            currentHd = design(currentD);
            currentEEG = filtfilt(currentHd.sosMatrix, currentHd.ScaleValues, currentEEG);
            if ~isempty(currentBCG)
                currentBCG = filtfilt(currentHd.sosMatrix, currentHd.ScaleValues, currentBCG);
            end
        end
        
        if strcmp(paramStruct.preprocess.EEG.(bandStr).filterType, 'zeroPhaseFIR')
            % Set the beginning & end of the signal to zero (filter artifact)
            filtLengthSamples = round(paramStruct.preprocess.EEG.(bandStr).filtParams*currentFs);
            halfFiltLengthSamples = round(filtLengthSamples/2);
            currentEEG((1:halfFiltLengthSamples), :) = 0;
            currentEEG((end-halfFiltLengthSamples):end, :) = 0;
        end         

        % Downsample the EEG to a more manageable data size
        currentNumTimePoints = size(currentEEG, 1);
        if isfield(paramStruct.preprocess.EEG.(bandStr), 'targetTimepoints')
            targetTimePoints = paramStruct.preprocess.EEG.(bandStr).targetTimepoints;
        else
            targetTimePoints = round(currentNumTimePoints*(newFs/currentFs));
        end
        currentEEG = resample(currentEEG, targetTimePoints, currentNumTimePoints);
        if ~isempty(currentBCG)
            currentBCG = resample(currentBCG, currentTargetTimePoints, currentNumTimePoints);
        end
        currentSampleShift = currentSampleShift*(newFs/currentFs);
        
        % Detrend & z-score the data
        currentEEG = detrend_wm(currentEEG', paramStruct.preprocess.EEG.(bandStr).detrendOrder);
        currentEEG = zscore(currentEEG, 0, 2);
        if ~isempty(currentBCG)
            currentBCG = detrend_wm(currentBCG', paramStruct.preprocess.EEG.(bandStr).detrendOrder);
            currentBCG = zscore(currentBCG, 0, 2);
        end
        
        % Store the data in the output structure
        filtEEG_data(i, j).data.EEG = currentEEG;
        filtEEG_data(i, j).data.BCG = currentBCG;
        filtEEG_data(i, j).info = struct(...
            'dataFormat', '(Channels x Time Points)',...
            'subject', i,...
            'scan', j,...
            'Fs', newFs,...
            'channels', {EEG_data(i, j).info.channels},...
            'filterSampleShift', currentSampleShift);
        
        % Garbage collect
        clear current*
        
        % Update progress bar
        progressbar([], j/length(scans{i}))
    end
    
    % Update progress bar
    progressbar(i/length(subjects), [])
end

% Garbage collect
EEG_data = filtEEG_data;
clear filtEEG_data

% save the ouput data structure
saveStr = [fileStruct.paths.MAT_files '\EEG\eegData_' bandStr '.mat'];
save(saveStr, 'EEG_data', '-v7.3');
            

        
        