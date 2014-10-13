%% 20140707 


%% 1654 - 

boldDataFiles = Search(Paths, 'BOLD', 'boldData');

load boldObject-1-1_RS_20140627;


boldData.Data = matfile(boldDataFiles{1});
[~, n, e] = fileparts(boldData.StoragePath);
newP = get(Paths, 'BOLD');
saveStr = [newP '/' n e];
boldData.StoragePath = saveStr;
save(saveStr, 'boldData', '-v7.3');

load boldObject-1-2_RS_20140627;help 

boldData.Data = matfile(boldDataFiles{2});
[~, n, e] = fileparts(boldData.StoragePath);
newP = get(Paths, 'BOLD');
saveStr = [newP '/' n e];
boldData.StoragePath = saveStr;
save(saveStr, 'boldData', '-v7.3');



%% 1616 - Re-Running BOLD-EEG Cross Correlations for All Electrodes (No Nuisance Regressions of Any Kind)
% The reviewers of the infraslow BOLD-EEG manuscript weren't happy with our method of electrode selection (using
% anticorrelated pairs of electrodes). This analysis is being conducted in preparation for creating correlation data
% between BOLD and all available EEG electrodes. It is essentially a performance profiling step to estimate how feasible
% it will be to just run everything and choose only representative samples for the publication.

% Today's parameters
timeStamp = '201407071616';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140707/201407071616 - %s-%d-%d_BOLD-EEG_NoRegressions.mat';

% Analysis parameters
maxLag = 20;        % <--- In seconds
maxNumThreads = 3;

% Get references to the data being used
boldFiles = GetBOLD(Paths);
eegFiles = GetEEG(Paths);

startTime = tic;
pbar = progress('BOLD-EEG Cross Correlation', 'Electrodes Completed');
for a = 2:2
    
    % Load the BOLD & EEG data
    load(boldFiles{a});
    load(eegFiles{a});
    
    
    
    % Initialize a data structure for storing results
    corrData = struct(...
        'Data', [],...
        'Lags', [],...
        'ParentData', {{boldFiles{a}; eegFiles{a}}});
    
    % Convert time lags in seconds to samples
    maxLagSamples = maxLag/(boldData.TR/1000);
    
    % Flatten data arrays
    [funData, idsNaN] = ToMatrix(boldData);
    ephysData = eegData.Data.EEG;
    
    
    cc = nan(length(idsNaN), 2*maxLagSamples + 1);
    
    numThreadsOpen = 0;
    idxChannel = 1;
    while (idxChannel <= length(eegData.Channels))
        
        if numThreadsOpen < maxNumThreads
            numThreadsOpen = numThreadsOpen + 1;
            job(numThreadsOpen) = batch(@xcorrArr, 1, {funData, ephysData(idxChannel, :), 'MaxLag', maxLagSamples}, 'Profile', 'local');
            idxChannel = idxChannel + 1;
        end
        
        
        
%         
%             wait(job(1));
%             tempCC = fetchOutputs(job(1));
%             job(1) = [];
%             cc(~idsNaN, :) = tempCC;
%             numThreadsOpen = numThreadsOpen - 1;
%         end

        
        for b = 1:length(job)
            if ~strcmpi(job(b).FinishTime, '')
                
                tempCC = fetchOutputs(job(b));
                job(b) = [];
            
        
        
        
        
    for b = 1:length(eegData.Channels)
        
        job(b) = batch(
            
        
        for c = 1:length(job)
            if strmpi(job(c).FinishTime, '');
                m = m + 1;
            else
                cc = fetchOutputs(job(c));
                
        if m == maxNumThreads
            wait(job(b - m));
            
            m = m - 1;
        end
            
            
        
    
    
    spmd(2)
        
        ephysData = codistributed(eegData.Data.EEG, codistributor1d(1));
        cc = nan(size(funData, 1), 2*maxLagSamples + 1);
        
        for b = drange(1:length(eegData.Channels))
            cc = xcorrArr(getLocalPart
        end
        
        
        % Loop through all EEG electrodes & cross-correlate with BOLD
        for b = 1:length(eegData.Channels)
            spmd(2)
                cc = xcorrArr(getLocalPart(segFunData), ephysData(b, :), 'MaxLag', maxLagSamples);
            end
            cc = cat(1, cc{:});

            tempCC = nan(length(idsNaN), size(cc, 2));
            tempCC(~idsNaN, :) = cc;
            corrData.Data.(eegData.Channels{b}) = reshape(tempCC(:, :, b), [91 109 91 size(cc, 2)]);    

            update(pbar, 2, b/length(eegData.Channels));
        end
    end
    
    % Save the correlation data to the hard drive
    currentSaveStr = sprintf(dataSaveName, 'corrData', boldData.Subject, boldData.Scan);
    save(currentSaveStr, 'corrData', '-v7.3');
    
    update(pbar, 1, a/length(boldFiles));
end
close(pbar);
endTime = toc(startTime);

% Run 1: 746.1067s = 12.4351min      (One scan processed, no parallel processing)
% Run 2: Unknown...but too long      (One scan processed, parfor loop around individual EEG channels)



%%

load boldObject-1-1_RS_20140627;
load eegObject-1-1_RS_20140630;

[funData, idsNaN] = ToMatrix(boldData);
ephysData = ToArray(eegData, 'FPz');


tempCorr = xcorrArr(funData, ephysData);
refCorr = nan(length(idsNaN), size(tempCorr, 2));
refCorr(~idsNaN, :) = tempCorr;

refCorr = reshape(refCorr, [91 109 91 size(tempCorr, 2)]);
samplesToPlot = round(linspace(1, size(refCorr, 4), 21));
refPlot = brainPlot('mri', refCorr(:, :, 48:4:64, samplesToPlot));


%%

check = randi(100, 10)


spmd(2)
    cCheck = codistributed(check, codistributor1d(1));
    test = getLocalPart(cCheck)
end




