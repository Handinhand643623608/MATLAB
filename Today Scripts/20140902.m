%% 20140902 


%% 0032 - Imaging the Cross Correlations Ran in the Previous Today Script
% Today's parameters
timeStamp = '201409020032';
analysisStamp = 'BOLD-%s Cross Correlation';
savePath = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140902';
dataSaveName = '201409020032-%02d - %s';

corrFiles = search('E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140901', '');

titleStr = 'BOLD-%s Cross Correlation';
timeShifts = -20:2:20;

for a = 1:length(corrFiles)
    
    load(corrFiles{a});
    
    channels = fieldnames(corrData);
    
    for b = 1:length(channels)
        
        currentData = corrData.(channels{b});
        currentData = corrObj.transform(currentData, 218);
        
        brainData = BrainPlot(currentData(:, :, 48:4:64, :),...
            'CLim', [-3 3],...
            'ColorbarLabel', 'Z-Score',...
            'Title', sprintf(titleStr, channels{b}),...
            'XLabel', 'Time Shift (s)',...
            'XTickLabel', timeShifts,...
            'YLabel', 'Slice Number',...
            'YTickLabel', 48:4:64);
        
        currentSaveName = sprintf(dataSaveName, a, sprintf(analysisStamp, channels{b}));
        
        brainData.Store('Ext', {'png', 'fig'}, 'Name', currentSaveName, 'Path', savePath);
        brainData.close;
    end
end




%% 0840 - Averaging the BOLD-EEG Cross Correlations (Excluding Subjects 5 & 6)
% Today's parameters
timeStamp = '201409020840';
analysisStamp = 'BOLD-EEG Average Cross Correlation';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140902/201409020840 - %s';

corrFiles = search('E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140901', '');

meanCorrData = struct('AF7', [], 'C3', [], 'FPz', [], 'PO8', [], 'PO10', []);

pbar = Progress('Averaging Cross Correlation Data');
for a = 1:length(corrFiles)
    
    load(corrFiles{a});
    channels = fieldnames(corrData);
    
    for b = 1:length(channels)
        
        currentData = corrData.(channels{b});
        currentData = corrObj.transform(currentData, 218);
        
        meanCorrData.(channels{b}) = cat(5, meanCorrData.(channels{b}), currentData);
        
    end
    
    pbar.Update(a/length(corrFiles));
    
end
pbar.close;


for a = 1:length(channels)
    
    meanCorrData.(channels{a}) = nanmean(meanCorrData.(channels{a}), 5);
    
end


save(sprintf(dataSaveName, analysisStamp), 'meanCorrData', '-v7.3');



%% 0850 - Imaging the Average Correlation Above
% Today's parameters
timeStamp = '201409020850';
analysisStamp = 'BOLD-%s Average Cross Correlation';
savePath = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140902';
dataSaveName = '201409020850 - %s';

for a = 1:length(channels)
    brainData = BrainPlot(meanCorrData.(channels{a})(:, :, 48:4:64, :),...
        'CLim', [-3 3],...
        'ColorbarLabel', 'Z-Score',...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', [-20:2:20],...
        'YLabel', 'Slice Number',...
        'YTickLabel', 48:4:64);
    
    currentSaveName = sprintf(dataSaveName, sprintf(analysisStamp, channels{a}));
    brainData.Store('Name', currentSaveName, 'Path', savePath, 'Ext', {'png', 'fig'});
    brainData.close;
end



%% 1349 - Creating Empirical Distribution in Preparation for Significance Tests
% Today's parameters
timeStamp = '201409021349';
analysisStamp = 'BOLD-EEG Null Cross Correlation';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140902/201409021349-%02d-%02d - %s.mat'

channels = {'AF7', 'C3', 'FPz', 'PO8', 'PO10'};
maxLag = 10;

boldFiles = GetBOLD(Paths);
eegFiles = GetEEG(Paths);

scans = [1:8, 14:17];
pairings = nchoosek(scans, 2);

currentBOLDFile = '';

pbar = Progress('Generating Empirical Null Distribution', 'Channels Completed');
for a = 1:size(pairings, 1)
    
    if (~strcmp(boldFiles{pairings(a, 1)}, currentBOLDFile))
        currentBOLDFile = boldFiles{pairings(a, 1)};
        load(currentBOLDFile);
        
        nuisance = boldData.Data.Nuisance;
        nuisanceSigs = [nuisance.Motion; nuisance.WM; nuisance.CSF];
        boldData.Regress(nuisanceSigs);
        
        [funData, idsNaN] = boldData.ToMatrix;
        boldData.ZScore;
        szBOLD = size(boldData.Data.Functional);
    end
    
    load(eegFiles{pairings(a, 2)});
    
    pbar.Reset(2)
    for b = 1:length(channels)
        ephysData = eegData.ToArray(channels{b});
        tempCorr = xcorrArr(funData, ephysData, 'MaxLag', maxLag);
        
        tempVolData = nan(length(idsNaN), size(tempCorr, 2));
        tempVolData(~idsNaN, :) = tempCorr;
        corrData.(channels{b}) = reshape(tempVolData, [szBOLD(1:3), size(tempCorr, 2)]);
       
        pbar.Update(2, b/length(channels));
    end
    
    currentSaveName = sprintf(dataSaveName, pairings(a, 1), pairings(a, 2), analysisStamp);
    save(currentSaveName, 'corrData', '-v7.3');
    
    pbar.Update(1, a/length(boldFiles));
end
pbar.close;
    

