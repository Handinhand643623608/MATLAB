%% 20141110 


%% 1236 - Imaging Thresholded Single-Subject BOLD-EEG Correlations
% This entry will visualize the thresholded correlations generated on 201411061742. I didn't get a chance to look at
% these over the weekend, so here it goes...

% Log parameters
timeStamp = '201411101236';
analysisStamp = '%02d - Thresholded BOLD-%s Correlation';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
slices = 48:4:64;

corrTimeStamp = '201411061742';
corrFiles = Today.FindFiles(corrTimeStamp);

% Load the Colin Brain anatomical data set (this is now the permanently adjusted version that was just saved today)
Files.ColinBrain.Load();
colinBrain = colinBrain(:, :, slices);
colinMask = colinMask(:, :, slices);

for a = 1:length(corrFiles)
    
    corrData = corrFiles(a).Load();
    lags = corrData.Lags;
    
    for b = 1:length(channels)
        
        currentCorr = corrData.(channels{b}).Correlation(:, :, slices, :);
        cutoffs = corrData.(channels{b}).CutoffZValues;
        
        currentCorr = maskImageSeries(currentCorr, colinMask, NaN);
        currentCorr(currentCorr > cutoffs(1) & currentCorr < cutoffs(2)) = NaN;
        
        bp = BrainPlot(...
            currentCorr,...
            'Anatomical',       colinBrain,...
            'AxesColor',        'k',...
            'CLim',             [-3 3],...
            'Color',            'w',...
            'ColorbarLabel',    'Z-Scores',...
            'Title',            sprintf(analysisStamp, a, channels{b}),...
            'XLabel',           'Time Shift (s)',...
            'XTickLabel',       lags,...
            'YLabel',           'Slice Number',...
            'YTickLabel',       slices);
        
        Today.SaveImageIn(bp, channels{b}, timeStamp, sprintf(analysisStamp, a, channels{b}), {'fig', 'png'});
    end
    
end
    
% Results: 
% Something is still going on here that I don't understand. There are some pretty clearly significant results in these
% images that are not passing thresholding at all because of SGoF (see CPz from scan 3 for just one example, but there
% are many others). I've been analyzing SGoF and the p-value generation process for some time this afternoon, but I
% can't really spot anything wrong with either procedure. I wish I could find a source that explicitly walks me through
% applying the processes to these particular data, but as far as I can tell no such explicit walkthrough exists.
%
% I probably just need to go back to using empirical data distributions for this; the results from that approach were
% always pretty sensible. Additionally, I learned recently that FWER can be exactly controlled when empirical
% distributions are used for thresholding (see Handbook of fMRI Data Analysis, Chapter 7, Section 3, Page 121).
%
% I can also try a fancier approach list Random Field Theory (RFT), which seems to be popular in literature (I can
% remember spotting its use in at least a few articles). Don't know anything about it, though, so it could be time
% consuming to learn and implement. All the same, it may be worth investigating just for my own edification...