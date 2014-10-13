%% 20141010 

% Store some universal variables
channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

autoCorrTimeStamp = '201410081600';
autoCorrPath = 'E:\Graduate Studies\Lab Work\Data Sets\Today Data\20141008';
corrTimeStamp = '201410031752';
corrPath = 'E:\Graduate Studies\Lab Work\Data Sets\Today Data\20141003';
nullTimeStamp = '201410031844';

autoCorrFiles = searchdir(autoCorrPath, autoCorrTimeStamp);
corrFiles = searchdir(corrPath, corrTimeStamp);
nullFiles = searchdir(corrPath, nullTimeStamp);



%% 0011 - Imaging BOLD-EEG Correlations from Individual Scans
% Today's parameters
timeStamp = '201410100011';
todayPath = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20141010';

titleStr = '%03d BOLD-%s Correlation';

for a = 1:length(corrFiles)
    
    load(corrFiles{a});
    
    for b = 1:length(channels)
        
        data = corrData.(channels{b});
        
        bp = BrainPlot(data(:, :, 48:4:64, :),...
            'CLim', [-0.5, 0.5],...
            'ColorbarLabel', 'Correlation Coefficient (r)',...
            'Title', sprintf(titleStr, a, channels{b}),...
            'XTickLabel', corrData.Lags,...
            'XLabel', 'Time Shift (s)',...
            'YTickLabel', [48:4:64],...
            'YLabel', 'Slice Number');
        
        bp.Store(...
            'Path', sprintf('%s/%s', todayPath, channels{b}),...
            'Name', sprintf(['%s-' titleStr], timeStamp, a, channels{b}),...
            'Ext', {'fig', 'png'});
        
        bp.close;
        
    end
end
        
        

