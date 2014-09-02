%% 20140901 


%% 2332 - Rerunning BOLD-EEG Cross Correlation (No Nuisance Regression from EEG)
% Reviewers of the manuscript didn't like that we regressed BOLD nuisance parameters from EEG. Also, this analyiss will
% exclude subjects 5 & 6 because their EEG data was found to have some unknown high-frequency artifacts.

% Today's parameters
timeStamp = '201409012332';
analysisStamp = 'BOLD-EEG Cross Correlation';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140901/201409012332-%02d - %s.mat'

maxLag = 10;
channels = {'AF7', 'C3', 'FPz', 'PO8', 'PO10'};
ignoreScans = [9:13];

boldFiles = GetBOLD(Paths);
eegFiles = GetEEG(Paths);

pbar = Progress('Cross-Correlating BOLD & EEG Signals', 'Channels Completed');
for a = 1:length(boldFiles)
    
    if ismember(a, ignoreScans); continue; end
    
    load(boldFiles{a});
    load(eegFiles{a});
    
    nuisance = boldData.Data.Nuisance;
    nuisanceSigs = [nuisance.Motion', nuisance.WM', nuisance.CSF'];
    boldData.Regress(nuisanceSigs);
    
    [funData, idsNaN] = boldData.ToMatrix;
    boldData.ZScore;
    szBOLD = size(boldData.Data.Functional);
    
    pbar.Reset(2);
    for b = 1:length(channels)
        ephysData = eegData.ToArray(channels{b});
        tempCorr = xcorrArr(funData, ephysData, 'MaxLag', maxLag);
        
        tempVolData = nan(length(idsNaN), size(tempCorr, 2));
        tempVolData(~idsNaN, :) = tempCorr;
        corrData.(channels{b}) = reshape(tempVolData, [szBOLD(1:3), size(tempCorr, 2)]);
       
        pbar.Update(2, b/length(channels));
    end
    
    currentSaveName = sprintf(dataSaveName, a, analysisStamp);
    save(currentSaveName, 'corrData', '-v7.3');
    
    pbar.Update(1, a/length(boldFiles));
end
pbar.close;