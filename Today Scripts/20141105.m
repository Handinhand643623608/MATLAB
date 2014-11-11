%% 20141105 



%% 1701 - Prototyping the BOLD-EEG Correlation Thresholding Process
% Today's parameters
timeStamp = '201411051701';

% Get the averaged z-scored BOLD-EEG correlation data
zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

fpz = meanData.FPz.Mean;
fpz = fpz(:);
fpz(fpz == 0 | isnan(fpz)) = [];

mnFPz = mean(fpz);
stdFPz = std(fpz);

% Get the two-tailed CDF values for the z-scored correlation coefficients
pvals = 2 * normcdf(-abs(fpz), mnFPz, stdFPz);

% FWER correction using SGoF
cutoff = sgof(pvals, 0.05);

if (isnan(cutoff))
    disp('No significant data were found after FWER correction.');
else
    fprintf(1, 'FWER-corrected significance cutoff is p < %d', cutoff);
end

% Get the indices of all significant data points & the indices of the distribution tails
idsSig = pvals < cutoff;
idsLowerTail = fpz < mnFPz;
idsUpperTail = fpz > mnFPz;

% Get the cutoff values in terms of z-scored correlations
zLowerCutoff = max(fpz(idsLowerTail & idsSig));
zUpperCutoff = min(fpz(idsUpperTail & idsSig));

fprintf(1, '\nCorrelation Z-Score Lower Cutoff Value: %d', zLowerCutoff);
fprintf(1, '\nCorrelation Z-Score Upper Cutoff Value: %d\n\n', zUpperCutoff);



%% 1901 - Imaging the Results Above
% Today's parameters
timeStamp = '201411051901';
analysisStamp = '';

colinData = Files.ColinBrain.Load();

volFPz = meanData.FPz.Mean(:, :, 48:4:64, :);
threshData = volFPz;
threshData(volFPz > zLowerCutoff & volFPz < zUpperCutoff) = NaN;

anatData = colinData.colinBrain(:, :, 48:4:64);

BrainPlot(threshData, 'Anatomical', anatData);



%% 1912 - Thresholding All BOLD-EEG Correlation Data using the Process Above

% Today's parameters
timeStamp = '201411051912';
analysisStamp = 'Thresholded Averaged BOLD-EEG Correlations';
dataSaveName = 'X:/Data/Today/20141105/201411051912 - ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

% Get the averaged z-scored BOLD-EEG correlation data
zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

pb = Progress('Thresholding Z-Scored Averaged BOLD-EEG Correlations');
for a = 1:length(channels)
    
    currentChannel = meanData.(channels{a}).Mean;
    currentChannel = currentChannel(:);
    currentChannel(currentChannel == 0 | isnan(currentChannel)) = [];
    
    currentMeanVal = mean(currentChannel);
    currentSTDVal = std(currentChannel);
    
    pvals = 2 * normcdf(-abs(currentChannel), currentMeanVal, currentSTDVal);
    meanData.(channels{a}).PValues = pvals;
    
    pCutoff = sgof(pvals, 0.05);
    meanData.(channels{a}).CutoffPValue = pCutoff;
    
    zCutoffs = [NaN, NaN];
    if (~isnan(pCutoff))
        idsSig = pvals < pCutoff;
        idsLowerTail = currentChannel < currentMeanVal;
        idsUpperTail = currentChannel > currentMeanVal;
        
        zCutoffs(1) = max(currentChannel(idsLowerTail & idsSig));
        zCutoffs(2) = min(currentChannel(idsUpperTail & idsSig));
    end
    
    meanData.(channels{a}).CutoffZValues = zCutoffs;
    
    pb.Update(a/length(channels));
end
pb.close();
    
Today.SaveData(timeStamp, analysisStamp, meanData);




%% 2131 - Imaging the Thresholded BOLD-EEG Correlations

% Today's parameters
timeStamp = '201411052131';
analysisStamp = 'Thresholded Average BOLD-%s Correlation';
dataSaveName = 'X:/Data/Today/20141105/201411052131 - ';

slices = 48:4:64;

Files.ColinBrain.Load();
colinBrain = colinBrain(:, :, slices);
colinMask = colinMask(:, :, slices);

% Mask out the skull & do a histogram adjustment 
% This brightens up the anatomical data. Values used are from examining the histogram of data
colinBrain(colinMask == 0) = 0;
colinBrain(colinBrain > 5e6) = 4.5e6;                               % <-- Remove high intensity outlier voxels
colinBrain(colinBrain > 4e6) = colinBrain(colinBrain > 4e6) + 5e5;  % <-- Increase intensity of these data (gray & white matter)

for a = 1:length(channels)
    
    currentCorr = meanData.(channels{a}).Mean(:, :, slices, :);
    currentCutoff = meanData.(channels{a}).CutoffZValues;
    
    currentCorr(currentCorr > currentCutoff(1) & currentCorr < currentCutoff(2)) = NaN;
    
    bp = BrainPlot(...
        currentCorr,...
        'Anatomical', colinBrain,...
        'AxesColor', 'k',...
        'CLim', [-3 3],...
        'Color', 'w',...
        'ColorbarLabel', 'Z-Scores',...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', meanData.Lags,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slices);
    
    Today.SaveImage(bp, timeStamp, sprintf(analysisStamp, channels{a}));
    
    bp.close();
end
    
    
