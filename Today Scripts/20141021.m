%% 20141021 


%% 1430 - Thresholding Averaged BOLD-EEG Correlation Data
% Today's parameters
timeStamp = '201410211430';
analysisStamp = '';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141021/201410211430 - ';

% Get the averaged z-scored BOLD-EEG correlation data
zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

fpz = meanData.FPz.Mean;
fpz = fpz(:);
fpz(fpz == 0 | isnan(fpz)) = [];

% Get the two-tailed CDF values for the z-scored correlation coefficients
pValues1 = normcdf(fpz, 0, 1);
pValues2 = 1 - pValues1;
cdfVals = 2*min(pValues1, pValues2);

% Flatten & get rid of NaNs
flatVals = cdfVals(:);
flatVals(isnan(flatVals)) = [];

% FWER correction using SGoF
cutoff = sgof(flatVals, 0.05);

% Results:
%
% Something is going wrong here. No significant values are being found despite the presence of obvious significance in
% these images. Using uncorrected (for FWER) thresholding, about 50,000 voxels are found to be significant for the
% BOLD-FPz data.
%
% Curiously, the p-values generated here range between 0 and 1, inclusively. There shouldn't be any p-values that reach
% the extremes unless the z-scored correlation values were at +/- infinity, which for these data is impossible. 


%% 1508 - Imaging the Standard Deviation of Averaged BOLD-EEG Correlations
% Today's parameters
timeStamp = '201410211508';
analysisStamp = 'STD of Averaged Z-Scored BOLD-%s Correlation';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141021/201410211508 - ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
slices = 48:4:64;
clim = [0, 2];

% Get the averaged z-scored BOLD-EEG correlation data
zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

for a = 1:length(channels)
    
    currentData = meanData.(channels{a}).STD;
    
    bp = BrainPlot(currentData(:, :, slices, :),...
        'CLim', clim,...
        'ColorbarLabel', 'Standard Deviation (Z-Score)',...
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



%% 1513 - Imaging the Variance of Averaged BOLD-EEG Correlations
% Today's parameters
timeStamp = '201410211513';
analysisStamp = 'Variance of Averaged Z-Scored BOLD-%s Correlation';
dataSaveName = 'X:/Code/MATLAB/Data/Today/20141021/201410211513 - ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
slices = 48:4:64;
clim = [0, 3];

% Get the averaged z-scored BOLD-EEG correlation data
zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

for a = 1:length(channels)
    
    currentData = meanData.(channels{a}).STD .^ 2;
    
    bp = BrainPlot(currentData(:, :, slices, :),...
        'CLim', clim,...
        'ColorbarLabel', 'Variance (Z-Score^2)',...
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
% Variance tends to be maximal over the somatomotor cortices, IPS, and visual cortices. A smattering of other areas are
% also seen for different electrodes, but these are far less consistent. Variance tends to be maximal at time shifts
% between ~[-10, 10] for all tested electrodes. Elsewhere in the brain or at different time shifts, variance tends
% towards zero globally. 


%% 1556 - Z-Scoring & Averaging BOLD-EEG Null Correlation Data
% Today's parameters
timeStamp = '201410211556';
analysisStamp = 'Averaged Z-Scored BOLD-EEG Null Correlations';
dataSaveName = 'X:/Data/Today/20141021/201410211556 - ';

% Analysis parameters
channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
dof = 61.04;

% Get null correlation data files
nullPath = Path('C:\Users\jgrooms\Desktop\Today Data\20141003');
nullTimeStamp = '201410031844';
nullFiles = nullPath.FileSearch(nullTimeStamp);

% Randomly reorder the null data sets
order = randperm(length(nullFiles));
nullFiles = nullFiles(order);

% Allocate a temporary results array (12 is the number of real data sets available)
currentData = zeros(91, 109, 91, 41, 12);
meanNullData = struct();

p = Progress('Z-Scoring & Averaging Null Correlation Data', 'Data Files Processed');
for a = 1:length(channels)
    p.Reset(2);
    for b = 1:12
        nullData = nullFiles(b).Load();
        currentData(:, :, :, :, b) = nullData.(channels{a});
        p.Update(2, b/12);
    end
    
    % Z-Score correlation coefficients
    currentData = atanh(currentData) .* sqrt(dof);
    
    meanNullData.(channels{a}).Mean = nanmean(currentData, 5);
    meanNullData.(channels{a}).STD = nanstd(currentData, [], 5);
    
    p.Update(1, a/length(channels));
end
p.close();

save([dataSaveName analysisStamp], 'meanNullData');



%% 1704 - Inspecting Grouped vs. Single Set Null Z-Score Statistics (DOF Corrected & Uncorrected)
% I just want to see what kinds of effects the DOF correction was having on the data. This will use an empirically
% generated null distribution from the section immediate above (whatever currentData was on the last iteration).
%
% To examine the effects, I will generate summary statistics and histograms for a set of 12 individual null data sets
% and for a single set out of those 12. I will then repeat the process after removing the degrees of freedom correction
% that I used on 20141015.
%
% If the degrees of freedom correction is working, then I would expect to see that the uncorrected data do not align
% well with a standard normal distribution (mean = 0, var = 1), while the corrected data should.

% Today's parameters
timeStamp = '201410211704';
dataSaveName = 'X:/Data/Today/20141021/201410211704 - ';

% Use the currentData that persists from the section above (12 sets of BOLD-PO10 null correlation)
po10 = currentData;
singlePO10 = currentData(:, :, :, :, 6);    %<--- Just pick a random set out of the 12

% Get rid of NaNs, zeros, & flatten
po10(isnan(po10) | po10 == 0) = [];
singlePO10(isnan(singlePO10) | singlePO10 == 0) = [];

% Compute some statistics for the null distributions
disp(mean(po10));           %  0.0325
disp(mean(singlePO10));     % -0.0648
disp(std(po10));            %  0.9494
disp(std(singlePO10));      %  0.9204
disp(var(po10));            %  0.9014
disp(var(singlePO10));      %  0.8471

% Generate histograms
figure; hist(po10, 1000);
title('Concatenated Z-Scored Null Correlation Histogram');
saveas(gcf, [dataSaveName 'Concatenated Z-Scored Null Correlation Histogram.png'], 'png');
saveas(gcf, [dataSaveName 'Concatenated Z-Scored Null Correlation Histogram.fig'], 'fig');

figure; hist(singlePO10, 1000);
title('Single Data Set Z-Scored Null Correlation Histogram');
saveas(gcf, [dataSaveName 'Single Data Set Z-Scored Null Correlation Histogram.png'], 'png');
saveas(gcf, [dataSaveName 'Single Data Set Z-Scored Null Correlation Histogram.fig'], 'fig');

% Uncorrect for degrees of freedom
uPO10 = po10 ./ sqrt(dof);
uSinglePO10 = singlePO10 ./ sqrt(dof);

disp(mean(uPO10));          %  0.0042
disp(mean(uSinglePO10));    % -0.0083
disp(std(uPO10));           %  0.1215
disp(std(uSinglePO10));     %  0.1178
disp(var(uPO10));           %  0.0148
disp(var(uSinglePO10));     %  0.0139

figure; hist(uPO10, 1000);
title('Concatenated Uncorrected Z-Scored Null Correlation Histogram');
saveas(gcf, [dataSaveName 'Concatenated Uncorrected Z-Scored Null Correlation Histogram.png'], 'png');
saveas(gcf, [dataSaveName 'Concatenated Uncorrected Z-Scored Null Correlation Histogram.fig'], 'fig');

figure; hist(uSinglePO10, 1000);
title('Single Data Set Uncorrected Z-Scored Null Correlation Histogram');
saveas(gcf, [dataSaveName 'Single Data Set Uncorrected Z-Scored Null Correlation Histogram.png'], 'png');
saveas(gcf, [dataSaveName 'Single Data Set Uncorrected Z-Scored Null Correlation Histogram.fig'], 'fig');

% Results:
%
% The following is a table of values calculated through the above analysis.
%
%                             Single Set              Concatenated
%                           Mean    Variance        Mean    Variance
%       DOF Corrected:    -0.0648    0.8471        0.0325    0.9014
%       Uncorrected:      -0.0083    0.0139        0.0042    0.0148
%
% Corrected vs. Uncorrected:

% Accounting for the reduced degrees of freedom (DOF) definitely fits the PO10 null distributions better to a standard
% normal distribution. Without the DOF correction (i.e. just using Fisher's r-to-z transform), the average value remains
% approximately zero, but the variance of the data is way off at approximately 0.0148. Similar numbers were observed
% regardless of whether or not concatenated data sets or a single representative null set was used. Using the
% correction, these null data conformed well to a standard normal distributed.
%
% Concatenated vs. Single Null Set
% Concatenation of multiple null data sets doesn't change the overall null data distribution much. However, both the
% mean and variance are made closer to the standard normal parameters when multiple sets are concatenated. This makes
% sense in the context of the law of large numbers/central tendency. 



%% 1747 - Inspecting Averaged Null Z-Score Statistics (DOF Corrected & Uncorrected)
% Repeating the inspection from the section immediately above after averaging the 12 null data sets. This should
% represent the true null distribution that the real correlation data would be compared against if we were still using
% empirical thresholding. 
%
% I expect that averaging the null data sets will at the very least lower the variance of the resulting distribution.
% This is because the null data are (or should be) randomly correlated/anticorrelated with one another. At least in
% principle, there should be no unifying features between these data that lead to coherent averaging of correlation
% values. Without coherent or consistently valued correlations, the normally distributed coefficients should tend toward
% zero, thus lowering the possible spread. 

% Today's parameters
timeStamp = '201410211747';
dataSaveName = 'X:/Data/Today/20141021/201410211747 - ';

% Use the currentData that persists from the section above (12 sets of BOLD-PO10 null correlation)
po10 = nanmean(currentData, 5);
uPO10 = nanmean(currentData ./ sqrt(dof), 5);

po10(isnan(po10) | po10 == 0) = [];
uPO10(isnan(uPO10) | uPO10 == 0) = [];

disp(mean(po10));           %  0.0314
disp(mean(uPO10));          %  0.0040
disp(std(po10));            %  0.3673
disp(std(uPO10));           %  0.0470
disp(var(po10));            %  0.1349
disp(var(uPO10));           %  0.0022

% Generate histograms
figure; hist(po10, 1000);
title('Averaged Z-Scored Null Correlation Histogram');
saveas(gcf, [dataSaveName 'Averaged Z-Scored Null Correlation Histogram.png'], 'png');
saveas(gcf, [dataSaveName 'Averaged Z-Scored Null Correlation Histogram.fig'], 'fig');

figure; hist(uPO10, 1000);
title('Averaged Uncorrected Z-Scored Null Correlation Histogram');
saveas(gcf, [dataSaveName 'Averaged Uncorrected Z-Scored Null Correlation Histogram.png'], 'png');
saveas(gcf, [dataSaveName 'Averaged Uncorrected Z-Scored Null Correlation Histogram.fig'], 'fig');

% Results:
%
% The following is a table of values calculated through the above analysis:
%
%                           Mean    Variance
%       DOF Corrected:     0.0314    0.1349
%       Uncorrected:       0.0040    0.0022
%
% It is clear now that in order to better approximate the standard normal curve for null correlation distributions, the
% DOF correction must be applied. However, while I expected a reduction in the variance of the distribution after
% averaging the concatenated null sets, the magnitude of the reduction is dramatic. At approximately 0.1349 (STD =
% 0.3673), this average doesn't match a standard Gaussian distribution at all.
%
% The question now becomes: how do I test the true averaged BOLD-EEG correlation data for significance? The results here
% pretty clearly indicate that those data cannot be tested against a standard normal distribution (like typical
% significance tests tend to be). 
