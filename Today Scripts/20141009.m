%% 20141009 

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



%% 1335 - Investigating the DOF Correction for Correlations between Filtered Signals
% Today's parameters
timeStamp = '201410091335';
analysisStamp = '';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141009/201410091335 - ';

autoCorrTimeStamp = '201410081600';
autoCorrPath = 'C:/Users/jgrooms/Desktop/Today Data/20141008';

autoCorrFiles = searchdir(autoCorrPath, autoCorrTimeStamp);

load(autoCorrFiles{1});

numSamples = 218;
lagsToUse = -40:40;

lags = ismember(autoCorrData.Lags, lagsToUse);
idxDF = 1:length(lagsToUse);

a = (1/218);
b = (2/218);
c = (218 - idxDF) ./ 218;
Axx = autoCorrData.Functional;
Ayy = autoCorrData.Ephys(1, :);

dfinv = a + (b * sum( c .* Axx(lags) .* Ayy(lags)));



%% 2152 - Investigating DOF Correlation Without Weighting Term
% Today's parameters
timeStamp = '201410092152';
analysisStamp = '';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20141009/201410092152-';

autoCorrFiles = searchdir(autoCorrPath, autoCorrTimeStamp);

load(autoCorrFiles{1});

numSamples = 218;
lagsToUse = -40:40;

lags = ismember(autoCorrData.Lags, lagsToUse);
idxDF = 1:length(lagsToUse);

a = (1/218);
b = (2/218);
c = (218 - idxDF) ./ 218;
Axx = autoCorrData.Functional;
Ayy = autoCorrData.Ephys(1, :);

dfinv = a + (b * sum( Axx(lags) .* Ayy(lags)));


%%
load(corrFiles{1});

fpz = corrData.FPz(:);
fpz( (isnan(fpz) | fpz == 0) ) = [];

win = Window('Size', WindowSizes.FullScreen);
hist(fpz, 10000);
title('BOLD-FPz Correlation Coefficient Distribution');
xlabel('Correlation Coefficient (r)');
ylabel('Bin Count');

saveas(gcf, [dataSaveName '1-1 BOLD-FPz Correlation Coefficient Distribution.png'], 'png');
saveas(gcf, [dataSaveName '1-1 BOLD-FPz Correlation Coefficient Distribution.fig'], 'fig');

%% 
load(nullFiles{1});

nullData = corrData;

fpzNull = nullData.FPz(:);
fpzNull( (isnan(fpzNull) | fpzNull == 0) ) = [];

win = Window('Size', WindowSizes.FullScreen);
hist(fpzNull, 10000);
title('BOLD-FPz Correlation Coefficient Null Distribution');
xlabel('Correlation Coefficient (r)');
ylabel('Bin Count');
set(gca, 'XLim', [-0.8 0.8]);

saveas(gcf, [dataSaveName '1 BOLD-FPz Correlation Coefficient Null Distribution.png'], 'png');
saveas(gcf, [dataSaveName '1 BOLD-FPz Correlation Coefficient Null Distribution.fig'], 'fig');



%% 2218 - Averaging Raw, Uncorrected Correlation Coefficients
% This analysis estimates the average cross-correlation between BOLD and the previously selected electrodes (see
% 20141003 and the top of this file). Correlation maps from individual scans will be averaged over the spatial
% dimensions. Correlation coefficients will not be converted to z-scores, because for now the intent is just to get a
% sense of what things look like and how (or if) they differ from the the batch from what was submitted with the BOLD-EG
% manuscript a few months ago.

% Today's parameters
timeStamp = '201410092218';
analysisStamp = 'BOLD-EEG Average Correlation Coefficients';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20141009/201410092218 - ';

emptyData = cell(length(channels), 1);
emptyData = cellfun(@(x) zeros(91, 109, 91, 41), emptyData, 'UniformOutput', false);

meanCorrData = cell2struct(emptyData, channels, 1);

pb = Progress('Concatenating Individual Correlation Data');
for a = 1:length(corrFiles)
    load(corrFiles{a});
    for b = 1:length(channels)
        meanCorrData.(channels{b}) = meanCorrData.(channels{b}) + corrData.(channels{b});        
    end
    pb.Update(a/length(corrFiles));
end
pb.close;

for a = 1:length(channels)
    meanCorrData.(channels{a}) = meanCorrData.(channels{a}) ./ length(corrFiles);
end

save([dataSaveName analysisStamp], 'meanCorrData');



%%

win = Window('Size', WindowSizes.FullScreen);
hist(meanCorrData.FPz(:), 10000);


%% 2334 - Imaging the Averaged Correlations from Above
% Today's parameters
timeStamp = '201410092334';
todayPath = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20141009';

slices = 48:4:64;
times = corrData.Lags;

idsLags = ismember(corrData.Lags, times);
titleStr = 'BOLD-%s Average Correlation';


for a = 1:length(channels)
    data = meanCorrData.(channels{a});
    currentTitle = sprintf(titleStr, channels{a});
    bp = BrainPlot(data(:, :, slices, idsLags),...
        'CLim', [-0.3, 0.3],...
        'ColorbarLabel', 'Correlation Coefficient (r)',...
        'Title', currentTitle,...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', times,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slices);
    
    bp.Store('Path', todayPath, 'Name', currentTitle, 'Ext', {'png', 'fig'});
    bp.close;
end

% Results: 

% Averages look terrible for the most part. Only a few electrodes show significant-looking correlations. BOLD-FPz is
% still strong, as is PO10, which were both electrodes included in previous correlation analyses. TP10 also looks good
% and is a new electrode, but the rest are pretty unremarkable. Also, these three good channels are pretty
% noisy-looking. I'll have to see what the new z-scoring/thresholding procedure does to these results tomorrow.
% Hopefully it'll at least clean up the noise a bit. 





    
    

