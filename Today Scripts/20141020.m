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



%% 1812 - Recalculating Average BOLD-EEG Correlations (With Z-Scoring)
% Today's parameters
timeStamp = '201410201812';
analysisStamp = 'Averaged Z-Scored BOLD-EEG Correlations';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141020/201410201812 - ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

zcorrTimeStamp = '201410151226';
corrFiles = Today.FindFiles(zcorrTimeStamp);

currentData = zeros(91, 109, 91, 41, length(corrFiles));
meanCorrData = struct();

p = Progress('Averaging Correlation Coefficients', 'Data Files Processed');
for a = 1:length(channels)
     p.Reset(2);
    for b = 1:length(corrFiles)
        corrData = corrFiles(b).Load();
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



%% 1856 - Imaging Averaged BOLD-EEG Correlations (Without Z-Scoring)
% Today's parameters
timeStamp = '201410201856';
analysisStamp = 'Averaged BOLD-%s Correlations';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141020/201410201856 - ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
slices = 48:4:64;

meanTimeStamp = '201410201707';
meanCorrFile = Today.FindFiles(meanTimeStamp);

meanData = meanCorrFile.Load();

for a = 1:length(channels)
    currentData = meanData.(channels{a}).Mean;
    
    bp = BrainPlot(currentData(:, :, slices, :),...
        'CLim', [-0.3, 0.3],...
        'ColorbarLabel', 'Correlation Coefficient (r)',...
        'MajorFontSize', 20,...
        'MinorFontSize', 15,...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XTickLabel', meanData.Lags,...
        'XLabel', 'Time Shift (s)',...
        'YTickLabel', slices,...
        'YLabel', 'Slice Number');
    
    bp.Store(...
        'Overwrite', true,...
        'Path', Today.Data.ToString(),...
        'Name', sprintf(['%s-' analysisStamp], timeStamp, channels{a}),...
        'Ext', {'fig', 'png'});
    
    bp.close();
end



%% 1904 - Imaging Averaged BOLD-EEG Correlations (With Z-Scoring)
% Today's parameters
timeStamp = '201410201904';
analysisStamp = 'Averaged Z-Scored BOLD-%s Correlations';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141020/201410201904 - ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
slices = 48:4:64;

meanTimeStamp = '201410201812';
meanCorrFile = Today.FindFiles(meanTimeStamp);

meanData = meanCorrFile.Load();

for a = 1:length(channels)
    currentData = meanData.(channels{a}).Mean;
    
    bp = BrainPlot(currentData(:, :, slices, :),...
        'CLim', [-3 3],...
        'ColorbarLabel', 'Correlation (Z-Score)',...
        'MajorFontSize', 20,...
        'MinorFontSize', 15,...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XTickLabel', meanData.Lags,...
        'XLabel', 'Time Shift (s)',...
        'YTickLabel', slices,...
        'YLabel', 'Slice Number');
    
    bp.Store(...
        'Overwrite', true,...
        'Path', Today.Data.ToString(),...
        'Name', sprintf(['%s-' analysisStamp], timeStamp, channels{a}),...
        'Ext', {'fig', 'png'});
    
    bp.close();
end
    
% Results:
% Just as I expected, z-scoring the correlation coefficients results in essentially no visible differences between the
% images. The CLim parameter is off a little bit here between the two image sets, so they don't look identical. However,
% the structure of high/medium/low correlation magnitudes look extremely similar to my eyes.
%
% So far, all that can be said in favor of the z-scoring process is that it makes the statistics a lot quicker to run.
% Now that the process has been pinned down, performing the whole correlation analysis from start to finish should
% require less than a day because of the removed need for p-value generation.
%
% After some though, I expect that thresholding the z-scored values will result in images that are nearly indiscernable
% from what we had previously. Even though we were applying our z-scoring incorrectly, the fact that we were also
% performing the same (incorrect) operation on an empirical null data set should have accounted for that particular
% error.
%
% More specifically, the empirical null should have accounted for the degrees of freedom problem altogether because the
% data used to generate that distribution were also filtered. Therefore, the null set should have seen an increased
% level of strong but spurious correlation. This in turn would have influenced both the threshold and FWER correction
% process. 
%
% Obviously, I can't claim to know that these two approaches would generate identical results, but I would hypothesize
% that the correlation patterns that survive thresholding would be pretty similar to one another. Given the
% lousy spatiotemporal resolution of fMRI and infraslow EEG in this project, not to mention the piddly sample population
% I'm working with, whatever minor differences there may be should be inconsequential.
%
% While I'm prattling on about the topic, the empirical distribution approach to significance testing still sounds like
% the superior method to me. I especially like its characteristic lack of assumptions about any underlying data
% distributions. After a century of mathematicians trying so hard to shoehorn correlation coefficients into a Gaussian
% distribution, I can't help but feel like we've lost sight of how to really look at these data. It's as if bandaid
% after bandaid has been applied to this process when what's really needed is a different approach. I think if I had the
% time I would more vigorously defend the empirical thresholding we did before. 
 