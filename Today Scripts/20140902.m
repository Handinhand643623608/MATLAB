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
    
    meanCorrData.(channels{b}) = nanmean(meanCorrData.(channels{b}), 5);
    
end


save(sprintf(dataSaveName, analysisStamp), 'meanCorrData', '-v7.3');



%% 0850 - Imaging the Average Correlation Above
% Today's parameters
timeStamp = '201409020850';
analysisStamp = 
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140902/201409020850 - '

boldFiles = GetBOLD(Paths);
eegFiles = GetEEG(Paths);