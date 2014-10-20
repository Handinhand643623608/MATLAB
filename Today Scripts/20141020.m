%% 20141020 


%% 1540 - Imaging Averaged BOLD-EEG Correlation Coefficients (Without Z-Scoring)
% Today's parameters
timeStamp = '201410201540';
analysisStamp = 'Average BOLD-%s Correlations';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
slices = 48:4:64;

meanTimeStamp = '201410151952';
meanCorrFile = Today.FindFiles(meanTimeStamp);

meanData = meanCorrFile.Load();

for a = 1:length(channels)
    currentData = meanData.(channels{a}).Mean;
    
    bp = BrainPlot(currentData(:, :, slices, :),...
        'CLim', [-0.5, 0.5],...
        'ColorbarLabel', 'Correlation Coefficient (r)',...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XTickLabel', meanData.Lags,...
        'XLabel', 'Time Shift (s)',...
        'YTickLabel', slices,...
        'YLabel', 'Slice Number');
    
    bp.Store(...
        'Path', Today.Data.ToString(),...
        'Name', sprintf(['%s-' analysisStamp], timeStamp, channels{a}),...
        'Ext', {'fig', 'png'});
    
    bp.close();
end
    

%% 1706 - Problem Found with 20141015 Results
% The averaged correlation data sets produced across 20141015 are incorrect. I made a typo in the file indexing that
% went unnoticed and definitely affected the averaged results. This has been noted retroactively in that day's script.



%% 1707 - Recalculating Average BOLD-EEG Correlations (Without Z-Scoring)
% Today's parameters
timeStamp = '201410201707';
analysisStamp = 'Averaged BOLD-EEG Correlations';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141020/201410201707 - ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

corrTimeStamp = '201410031752';
corrFiles = Today.FindFiles(corrTimeStamp);

currentData = zeros(91, 109, 91, 41, length(corrFiles));
meanCorrData = struct();

p = Progress('Averaging Correlation Coefficients', 'Data Files Processed');
for a = 1:length(channels)
     p.Reset(2);
    for b = 1:length(corrFiles)
        corrFiles(b).Load();
        currentData(:, :, :, :, b) = corrData.(channels{a});
        p.Update(2, b/length(corrFiles));
    end
    
    meanCorrData.(channels{a}).Mean = nanmean(currentData, 5);
    meanCorrData.(channels{a}).STD = nanstd(currentData, [], 5);
    
    p.Update(a/length(channels));
end
p.close();

meanCorrData.Lags = corrData.Lags;

save([dataSaveName analysisStamp], 'meanCorrData');