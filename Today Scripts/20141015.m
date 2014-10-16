%% 20141015 

corrTimeStamp = '201410031752';
% corrPath = 'C:\Users\jgrooms\Desktop\Today Data\20141003';
corrPath = 'E:\Graduate Studies\Lab Work\Data Sets\Today Data\20141003';
corrFiles = searchdir(corrPath, corrTimeStamp);
zCorrTimeStamp = '201410151226';
zCorrPath = 'X:/Code/MATLAB/Data/Today/20141015';
zCorrFiles = searchdir(zCorrPath, zCorrTimeStamp);

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
dof = 61.04;



%% 1226 - Z-Scoring BOLD-EEG Correlation Data from 20141003
% This section will utilize the methods discussed in (Davey 2013) to z-score the correlation data between the BOLD and
% EEG filtered time series. Z-Scores will be generated using Fisher's r-to-z transform followed by using the new
% effective DOF estimate of 61.04 (see the 20141013 script for details on its derivation). Data will then be averaged
% and thresholded for significance.

% Today's parameters
timeStamp = '201410151226';
analysisStamp = 'Z-Scored BOLD-EEG Correlations';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141015/201410151226 - %02d ';

zCorrData = emptystruct('Lags', 'DOF', channels{:});

p = Progress('Z-Scoring BOLD-EEG Correlation Data');
for a = 1:length(corrFiles)
    load(corrFiles{a});
    for b = 1:length(channels)
        currentData = corrData.(channels{b});
        currentData = atanh(currentData);
        currentData = currentData .* sqrt(dof);
        zCorrData.(channels{b}) = currentData;
    end
    zCorrData.Lags = corrData.Lags;
    zCorrData.DOF = dof;
    save(sprintf([dataSaveName, analysisStamp], a), 'zCorrData');    
    p.Update(a/length(corrFiles));
end
p.close();




%% 1401 - Averaging Z-Scored Correlation Data
% This section will average the z-scored correlation data generated in the section above. It will also collect
% statistics about these z-scores, such as the standard deviations of the z-scores for each voxel across all scans.

% Today's parameters
timeStamp = '201410151401';
analysisStamp = 'Averaged Z-Scored BOLD-EEG Correlations';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141015/201410151401 - ';

emptyData = cell(length(channels), 1);
emptyData = cellfun(@(x) zeros(91, 109, 91, 41, length(zCorrFiles)), emptyData, 'UniformOutput', false);
meanCorrData = cell2struct(emptyData, channels, 1);

p = Progress('-fast', 'Averaging Z-Scored Correlation Data', 'Data Files Processed');
for a = 1:length(channels)
    p.Reset(2);
    for b = 1:length(zCorrFiles)
        load(zCorrFiles{a});
        meanCorrData.(channels{a})(:, :, :, :, b) = zCorrData.(channels{a});
        p.Update(2, b/length(zCorrFiles));
    end
    
    currentData = meanCorrData.(channels{a});
    meanCorrData.(channels{a}).Mean = nanmean(currentData, 5);
    meanCorrData.(channels{a}).STD = nanstd(currentData, [], 5);
    
    p.Update(a/length(channels));
end
p.close();

meanCorrData.Lags = zCorrData.Lags;
meanCorrData.DOF = zCorrData.DOF;

save([dataSaveName analysisStamp], 'meanCorrData');



%% 1952 - 
% Today's parameters
timeStamp = '201410151952';
analysisStamp = 'Averaged BOLD-EEG Correlations';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20141015/201410151952 - ';

emptyData = cell(length(channels), 1);
emptyData = cellfun(@(x) zeros(91, 109, 91, 41, length(corrFiles)), emptyData, 'UniformOutput', false);
meanCorrData = cell2struct(emptyData, channels, 1);

p = Progress('Averaging Correlation Coefficients', 'Data Files Processed');
for a = 1:length(channels)
     p.Reset(2);
    for b = 1:length(corrFiles)
        load(corrFiles{a});
        meanCorrData.(channels{a})(:, :, :, :, b) = corrData.(channels{a});
        p.Update(2, b/length(corrFiles));
    end
    
    currentData = meanCorrData.(channels{a});
    meanCorrData.(channels{a}).Mean = nanmean(currentData, 5);
    meanCorrData.(channels{a}).STD = nanstd(currentData, [], 5);
    
    p.Update(a/length(channels));
end
p.close();

meanCorrData.Lags = corrData.Lags;

save([dataSaveName analysisStamp], 'meanCorrData');


