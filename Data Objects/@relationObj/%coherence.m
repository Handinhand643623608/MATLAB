function relationData = coherence(relationData, varargin)
%COHERENCE Evaluates the magnitude squared coherence between BOLD data and EEG data based on the
%   various possible inputs. Optional property specifications are in parentheses below. All inputs
%   must be specified either explicitly or through a "Parameters" property in the object itself
%   created during object instantiation. 
%
%   SYNTAX:
%   relationData = coherence(relationData, 'PropertyName', PropertyValue,...)
%
%   OUTPUTS:
%   relationData:           The relation data object containing all coherence information between
%                           modalities. 
%
%   PROPERTY NAMES:
%   relationData:           The initialized relation data object.
%
%   'Channels':             EEG channels to be included in the analysis.
%
%   ('CorrDataFile'):       The correlation data file to be used if a correlation fMRI mask is
%                           called for.
%
%   'Fs':                   The sampling frequencies of the modalities.
%
%   ('GenerateNull'):       A boolean indicating whether or not a null distribution should be
%                           generated for assessing statistical significance.
%
%   'MaskMethod':           The method to be used for masking the fMRI data.
%
%   ('Mask'):               WARNING: parameter not implemented yet.
%
%   'MaskThreshold':        Cutoff threshold used for masking. 
%
%   ('NumOverlap'):         Percentage overlap between windows during FFT step.
%
%   ('NumFFT'):             Number of FFT points used to calculate power spectral densities. 
%
%   ('Scans'):              Specific scans desired for analysis.
%
%   ('Subjects'):           Specific subjects desired for analysis.
%
%   'TimeShifts':           The time delay between modalities at which MS coherence is evaluated.
%
%   ('Window'):             The window function to be used. 
%
%   
% 
%   Written by Josh Grooms on 20130322
%       20130418:   Finished writing basic functionality. Can now handle the case of "correlation"
%                   masking only.
%       20130428:   Reorganized function to analyze all selected subjects & scans in a single
%                   run-through. Expanded help section. Added functionality to generate null
%                   distributions for bootstrapping.
%       20130611:   Removed a default setting that only made sense for a single analysis.
%       20130613:   Filled in some of the help & reference section. Bug fix for a line trying to
%                   index a BOLD object with both subject & scan indices. Bug fix for inputting BOLD
%                   TR instead of 1/TR to MS coherence function for sampling frequency.
%
%   TODO: Implement manual seed region selection
%   TODO: Generalize loading of correlation data for masks & convert these structures to objects


%% Initialize
% If parameters are provided in a structure attached to the object
if isempty(varargin)
    tempParams = relationData(1, 1).Parameters;
    tempParamNames = fieldnames(tempParams);
    varargin = cell(1, 2*length(tempParamNames));
    b = 1;
    for a = 1:2:length(varargin)
        varargin{a} = tempParamNames{b};
        varargin{a+1} = tempParams.(tempParamNames{b});
            b = b + 1;
    end
end

% Initialize an input & defaults structure
inStruct = struct(...
    'Channels', [],...
    'CorrDataFile', [],...
    'Fs', [],...
    'GenerateNull', false,...
    'MaskMethod', [],...
    'Mask', [],...
    'MaskThreshold', [],...
    'NumOverlap', [],...
    'NumFFT', [],...
    'Scans', [],...
    'Subjects', [],...
    'TimeShifts', [],...
    'Window', []);
assignInputs(inStruct, varargin,...
    'compatibility', {'Channels', 'electrodes', 'electrode';
                      'Fs', 'samplingFreq', 'sampleFreq';
                      'MaskMethod', 'method', 'maskToUse'; 
                      'Mask', 'threshold', 'region';
                      'NumOverlap', 'overlap', 'sampleOverlap';
                      'numFFT', 'steps', 'fftSteps';
                      'TimeShifts', 'lags', 'delays'});

% Load the EEG data
load(relationData(1, 1).ParentEEG);

try
if ~GenerateNull
    %% Generate the Coherence Data
    for a = Subjects

        % Load the BOLD data
        load(relationData(a, 1).ParentBOLD);

        for b = Scans{a}
            if ~isempty(boldData(b).Data)
                for c = 1:length(Channels)
                    for d = 1:length(TimeShifts)


                        %% Data Mask to Reduce Size
                        switch lower(MaskMethod)

                            % Use correlation data, if it exists
                            case {'correlation', 'corrdata', 'corr', 'xcorrdata', 'xcorr'}
                                % Get the correlation data to be used for masking
                                if ~exist('corrData', 'var')
                                    load(CorrDataFile);
                                end

                                % Convert input time shifts (in seconds) to array indices
                                allShifts = corrData(a, b).info.timeShifts;
                                idsTimeShifts = (allShifts == TimeShifts(d));

                                % Get the BOLD data & apply gray matter mask
                                currentBOLD = boldData(b).Data.Functional;
                                currentGM = boldData(b).Masks.Gray;
                                currentBOLD(currentGM == 0) = NaN;
                                szBOLD = size(currentBOLD);

                                % Get the EEG data & downsample to BOLD sampling frequency
                                idxChannel = strcmpi(eegData(a, b).Channels, Channels{c});
                                currentEEG = eegData(a, b).Data.EEG(idxChannel, :);
                                currentEEG = resample(currentEEG, szBOLD(4), length(currentEEG));

                                % Get the current correlation data set
                                currentCorr = corrData(a, b).data.(Channels{c})(:, :, :, idsTimeShifts);
                                currentCorr(currentGM == 0) = NaN;

                                % Sort correlation values & threshold for mask generation
                                tempFlatCorr = currentCorr(:);
                                tempFlatCorr(isnan(tempFlatCorr)) = [];
                                tempFlatCorr = sort(tempFlatCorr);
                                currentUpperThresh = tempFlatCorr(ceil((1-MaskThreshold)*length(tempFlatCorr)));
                                currentLowerThresh = tempFlatCorr(floor(MaskThreshold*length(tempFlatCorr)));
                                clear temp*

                                % Generate the masks
                                tempUpperVoxelMap = boolean((currentCorr >= currentUpperThresh));
                                tempUpperVoxelMap = repmat(tempUpperVoxelMap, [1, 1, 1, szBOLD(4)]);
                                tempLowerVoxelMap = boolean((currentCorr <= currentLowerThresh));
                                tempLowerVoxelMap = repmat(tempLowerVoxelMap, [1, 1, 1, szBOLD(4)]);
                                currentMasks{1} = tempUpperVoxelMap;
                                currentMasks{2} = tempLowerVoxelMap;
                                maskStrs = {'corr'; 'acorr'};
                                clear temp*


        %                 % Use RSNs from ICA (filtered source data)
        %                 case {'rsn', 'rsns', 'ic', 'ics'}
        % 
        %                 % Use a manually selected seed region
        %                 case {'seed', 'manual', 'seedregion', 'region'}                        

                        end            

                        % Generate average BOLD signals for each available mask
                        for e = 1:length(currentMasks)
                            tempSig = nan(szBOLD);
                            tempSig(currentMasks{e}) = currentBOLD(currentMasks{e});
                            tempSig = reshape(tempSig, [prod(szBOLD(1:3)), szBOLD(4)]);
                            currentBOLDSigs{e} = nanmean(tempSig, 1);
                        end
                        clear temp*


                        %% Evaluate Coherence between the Signals            
                        % Loop through the available masked BOLD signals & calculate coherence
                        for e = 1:length(currentBOLDSigs)
                            [tempCohData, tempFreqs] = mscohere(currentEEG, currentBOLDSigs{e},...
                                Window,...
                                NumOverlap,...
                                NumFFT,...
                                1/boldData(b).TR);
                            if iscolumn(tempCohData)
                                tempCohData = tempCohData';
                                tempFreqs = tempFreqs';
                            end                
                            relationData(a, b).Data.Coherence.([maskStrs{e} Channels{c}]) = tempCohData;
                        end
                    end

                    % Store information in the data object
                    relationData(a, b).Data.Frequencies = tempFreqs;
                    clear current* temp*
                end

                % Store parameter information in the data object
                relationData(a, b).Parameters = inStruct;
            end
        end
    end
    
else
    
    %% Generate a Null Distibution for Bootstrapping
    % Determine the null distribution pairing sequence
    totalScans = length(cat(2, Scans{:}));
    indTranslate = cell(totalScans, 1);
    m = 1;
    for a = Subjects
        for b = Scans{a}
            indTranslate{m} = [a, b];
            m = m + 1;
        end
    end
    nullPairings = num2cell(nchoosek(1:totalScans, 2));
    nullPairings = cellfun(@(x) indTranslate(x), nullPairings);
    
    % Initialize parts of the relation data object needed later
    relationData.Data.Coherence = [];
    
    progressbar('Generating Null Distribution', 'Channels Completed', 'Calculating Coherence');
    previousBOLDSubject = 0;
    for a = 1:size(nullPairings, 1)
        
        % Load new BOLD data sets, if necessary
        idsCurrentBOLD = nullPairings{a, 1};
        if idsCurrentBOLD(1) ~= previousBOLDSubject || previousBOLDSubject == 0
            load(relationData.ParentBOLD{idsCurrentBOLD(1)});
            previousBOLDSubject = idsCurrentBOLD(1);
        end
        
        % Get the EEG indices for deranged pairings
        idsCurrentEEG = nullPairings{a, 2};
        
        progressbar([], 0, [])
        for b = 1:length(Channels)
            for c = 1:length(TimeShifts)
                
                
                %% Data Mask to Reduce Size
                switch lower(MaskMethod)

                    % Use correlation data, if it exists
                    case {'correlation', 'corrdata', 'corr', 'xcorrdata', 'xcorr'}
                        % Get the correlation data to be used for masking
                        if ~exist('corrData', 'var')
                            load(CorrDataFile);
                        end

                        % Convert input time shifts (in seconds) to array indices
                        allShifts = corrData(idsCurrentBOLD(1), idsCurrentBOLD(2)).info.timeShifts;
                        idsTimeShifts = (allShifts == TimeShifts(c));

                        % Get the BOLD data & apply gray matter mask
                        currentBOLD = boldData(idsCurrentBOLD(2)).Data.Functional;
                        currentGM = boldData(idsCurrentBOLD(2)).Masks.Gray;
                        currentBOLD(currentGM == 0) = NaN;
                        szBOLD = size(currentBOLD);

                        % Get the EEG data & downsample to BOLD sampling frequency
                        idxChannel = strcmpi(eegData(idsCurrentEEG(1), idsCurrentEEG(2)).Channels, Channels{b});
                        currentEEG = eegData(idsCurrentEEG(1), idsCurrentEEG(2)).Data.EEG(idxChannel, :);
                        currentEEG = resample(currentEEG, szBOLD(4), length(currentEEG));

                        % Get the current correlation data set
                        currentCorr = corrData(idsCurrentBOLD(1), idsCurrentBOLD(2)).data.(Channels{b})(:, :, :, idsTimeShifts);
                        currentCorr(currentGM == 0) = NaN;

                        % Sort correlation values & threshold for mask generation
                        tempFlatCorr = currentCorr(:);
                        tempFlatCorr(isnan(tempFlatCorr)) = [];
                        tempFlatCorr = sort(tempFlatCorr);
                        currentUpperThresh = tempFlatCorr(ceil((1-MaskThreshold)*length(tempFlatCorr)));
                        currentLowerThresh = tempFlatCorr(floor(MaskThreshold*length(tempFlatCorr)));
                        clear temp*

                        % Generate the masks
                        tempUpperVoxelMap = boolean((currentCorr >= currentUpperThresh));
                        tempUpperVoxelMap = repmat(tempUpperVoxelMap, [1, 1, 1, szBOLD(4)]);
                        tempLowerVoxelMap = boolean((currentCorr <= currentLowerThresh));
                        tempLowerVoxelMap = repmat(tempLowerVoxelMap, [1, 1, 1, szBOLD(4)]);
                        currentMasks{1} = tempUpperVoxelMap;
                        currentMasks{2} = tempLowerVoxelMap;
                        maskStrs = {'corr'; 'acorr'};
                        clear temp*


    %                 % Use RSNs from ICA (filtered source data)
    %                 case {'rsn', 'rsns', 'ic', 'ics'}
    % 
    %                 % Use a manually selected seed region
    %                 case {'seed', 'manual', 'seedregion', 'region'}                        

                end            

                % Generate average BOLD signals for each available mask
                for d = 1:length(currentMasks)
                    tempSig = nan(szBOLD);
                    tempSig(currentMasks{d}) = currentBOLD(currentMasks{d});
                    tempSig = reshape(tempSig, [prod(szBOLD(1:3)), szBOLD(4)]);
                    currentBOLDSigs{d} = nanmean(tempSig, 1);
                end
                clear temp*


                %% Evaluate Coherence between the Signals            
                % Loop through the available masked BOLD signals & calculate coherence
                progressbar([], [], 0)
                for d = 1:length(currentBOLDSigs)
                    [tempCohData, tempFreqs] = mscohere(currentEEG, currentBOLDSigs{d},...
                        Window,...
                        NumOverlap,...
                        NumFFT,...
                        1/boldData(idsCurrentBOLD(2)).TR);
                    if iscolumn(tempCohData)
                        tempCohData = tempCohData';
                        tempFreqs = tempFreqs';
                    end
                    if ~isfield(relationData.Data.Coherence, ([maskStrs{d} Channels{b}]))
                        relationData.Data.Coherence.([maskStrs{d} Channels{b}]) = tempCohData;
                    else
                        relationData.Data.Coherence.([maskStrs{d} Channels{b}]) = ...
                            cat(1, relationData.Data.Coherence.([maskStrs{d} Channels{b}]), tempCohData);
                    end
                    progressbar([], [], d/length(currentBOLDSigs))
                end
            end

            % Store information in the data object
            relationData.Data.Frequencies = tempFreqs;
            clear current* temp*
            progressbar([], b/length(Channels), [])
        end

        % Store parameter information in the data object
        relationData.Parameters = inStruct;
        progressbar(a/size(nullPairings, 1), [], [])
    end
end
catch whatHappened
    save('cohCrash.mat')
    rethrow(whatHappened)
end

