%% 20141022 


%% 1353 - Re-Examining BOLD-EEG Correlation Significance Thresholding
% Yesterday I messed around with thresholding the BOLD-EEG correlation data by comparing them against a standard normal
% null distribution (~N(0, 1)). Now, I want to see if the thresholding changes when I compare against a normal null that
% is parameterized by characteristics of an empirical null distribution (see the last two entries from yesterday). 

% Today's parameters
timeStamp = '201410221353';
analysisStamp = '';
dataSaveName = 'X:/Data/Today/20141022/201410221353 - ';

% Get the averaged z-scored BOLD-EEG correlation data
zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

fpz = meanData.FPz.Mean;
fpz = fpz(:);
fpz(fpz == 0 | isnan(fpz)) = [];

% Get the two-tailed CDF values for the z-scored correlation coefficients
pValues1 = normcdf(fpz, 0.0314, sqrt(0.1349));
pValues2 = 1 - pValues1;
cdfVals = 2*min(pValues1, pValues2);

% Flatten & get rid of NaNs
flatVals = cdfVals(:);
flatVals(isnan(flatVals)) = [];

% FWER correction using SGoF
cutoff = sgof(flatVals, 0.05);

% Results:
% Analysis never finished. It was taking too long and I'm starting to think this isn't the correct approach anyway. 



%% 1516 - Generating Histograms of Averaged Z-Scored BOLD-EEG Correlations
% Yesterday I generated histograms of the averaged null correlation data. Now I want to see how the real data compare to
% those distributions.

% Today's parameters
timeStamp = '201410221516';
analysisStamp = 'Averaged Z-Scored BOLD-%s Correlation Histogram';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

for a = 1:length(channels)
    currentData = meanData.(channels{a}).Mean(:);
    currentData(isnan(currentData) | currentData == 0) = [];
    
    figure; hist(currentData, 1000);
    title(sprintf(analysisStamp, channels{a}));
    Today.SaveImage(gcf, timeStamp, sprintf(analysisStamp, channels{a}), {'fig', 'png'});
    
    close
end

% Results:
% These peaks are quite narrow, just like the null distributions after averaging. I suppose the averaging process here
% is inflicting similar variance reductions in the data, which makes sense. However, I'm now pretty sure that
% thresholding can't be done on these data using a standard normal distribution for the null hypothesis.



%% 1641 - 
% Today's parameters
timeStamp = '201410221641';
analysisStamp = 'Thresholded Averaged FWER-Uncorrected BOLD-%s Correlation';
dataSaveName = 'X:/Data/Today/20141022/201410221641 - ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
slices = 48:4:64;

zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

load colinBrain;
colinBrain = colinBrain(:, :, slices);
colinMask = colinMask(:, :, slices);
colinBrain(colinMask == 0) = 0;
colinBrain(colinBrain > 5e6) = 4.5e6;
colinBrain(colinBrain > 4e6) = colinBrain(colinBrain > 4e6) + 5e5;

for a = 1:length(channels)
    
    currentData = meanData.(channels{a}).Mean(:, :, slices, :);
    currentData = maskImageSeries(currentData, logical(colinMask), NaN);
    currentData(currentData > -1.96 & currentData < 1.96) = NaN;
    
    bp = BrainPlot(currentData,...
        'Anatomical', colinBrain,...
        'CLim', [-3 3],...
        'ColorbarLabel', 'Z-Score',...
        'MajorFontSize', 20,...
        'MinorFontSize', 15,...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', meanData.Lags,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slices);
    
    Today.SaveImage(bp, timeStamp, sprintf(analysisStamp, channels{a}), {'png', 'fig'});
    
    bp.close();
end
    
% Results:
% Essentially nothing passes thresholding. This confirms that the standard normal curve cannot be used as the null
% distribution.



%% 1713 - 
% Let's try thresholding based on a null distribution parameterized by the empirical null from yesterday (PO10). Since
% that curve is similarly narrow, I'm betting these results will look a lot better. FWER will remain uncontrolled for
% the time being.

% Today's parameters
timeStamp = '201410221713';
analysisStamp = 'Thresholded Averaged FWER-Uncorrected BOLD-%s Correlation';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
slices = 48:4:64;
lowerCutoff = norminv(0.025, 0.0314, sqrt(0.1349));
upperCutoff = -lowerCutoff;

zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

load colinBrain;
colinBrain = colinBrain(:, :, slices);
colinMask = colinMask(:, :, slices);
colinBrain(colinMask == 0) = 0;
colinBrain(colinBrain > 5e6) = 4.5e6;
colinBrain(colinBrain > 4e6) = colinBrain(colinBrain > 4e6) + 5e5;

for a = 1:length(channels)
    
    currentData = meanData.(channels{a}).Mean(:, :, slices, :);
    currentData = maskImageSeries(currentData, logical(colinMask), NaN);
    currentData(currentData > lowerCutoff & currentData < upperCutoff) = NaN;
    
    bp = BrainPlot(currentData,...
        'Anatomical', colinBrain,...
        'CLim', [-3 3],...
        'ColorbarLabel', 'Z-Score',...
        'MajorFontSize', 20,...
        'MinorFontSize', 15,...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', meanData.Lags,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slices);
    
    Today.SaveImage(bp, timeStamp, sprintf(analysisStamp, channels{a}), {'png', 'fig'});
    
    bp.close();
end
    
% Results:
% These DO look a lot better. Lots of brain regions pass thresholding now, and most look like they belong (i.e. are part
% of an RSN or commonly correlated structures). However, FWER needs to be controlled for, and this test should be
% conducted as a t-test, not with truly normal variables.