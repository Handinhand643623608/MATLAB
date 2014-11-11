%% 20141106 


%% 1102 - Correction to BOLD-EEG Correlation Thresholding Process
% I stumbled onto last night while looking through a statistics textbook (Statistics for Bioengineering Sciences,
% Section 6.4, page 203). I believe I thresholded the data incorrectly yesterday by using the mean and standard
% deviations of the correlation distribution itself instead of generating p-values that are relative to a null
% distribution. This section of text discusses the changes that occur when averaging multiple normally distributed data
% sets, which is what I needed (and discussed somewhat on 201410221516).
%
% Therefore, this section will redo the 1912 section from yesterday that thresholded the latest BOLD-EEG correlation
% data. It will produce p-values using a theoretical null distribution that is zero mean and has a standard deviation of
% 1/sqrt(12), which is what the theoretical standard deviation should be after averaging together 12 standard normally
% distributed null data sets.

% Today's parameters
timeStamp = '201411061102';
analysisStamp = 'Thresholded Average BOLD-EEG Correlations';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

% Get the averaged z-scored BOLD-EEG correlation data
zcorrTimeStamp = '201410201812';
meanFile = Today.FindFiles(zcorrTimeStamp);
meanData = meanFile.Load();

pb = Progress('Thresholding Z-Scored Averaged BOLD-EEG Correlations');
for a = 1:length(channels)
    
    % Get & flatten the correlation data, then remove irrelevant values
    currentChannel = meanData.(channels{a}).Mean;
    currentChannel = currentChannel(:);
    currentChannel(currentChannel == 0 | isnan(currentChannel)) = [];
    
    % Calculate the mean & standard deviation of the current correlation distribution
    currentMeanVal = mean(currentChannel);
    currentSTDVal = std(currentChannel);
    
    % Convert the correlation values into p-values
    pvals = 2 * normcdf(-abs(currentChannel), 0, 1/sqrt(12));
    meanData.(channels{a}).PValues = pvals;
    
    % Correct for multiple comparisons
    pCutoff = sgof(pvals, 0.05);
    meanData.(channels{a}).CutoffPValue = pCutoff;
    
    % Convert the p-value cutoff into two z-score cutoffs (one for each tail)
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
    
% Save the thresholded average data
Today.SaveData(timeStamp, analysisStamp, meanData);

% Display some of the results in the console
str = ['\n%s:\n'...
            '\tP-Value Cutoff:\t\t%d\n'...
            '\tZ-Value Cutoffs:\t[%d\t%d]\n'];

for a = 1:length(channels)
    chan = meanData.(channels{a});
    fprintf(1, str, channels{a}, chan.CutoffPValue, chan.CutoffZValues(1), chan.CutoffZValues(2));
end

% Results:
%
% FPz:
% 	P-Value Cutoff:		2.233785e-02
% 	Z-Value Cutoffs:	[-6.594996e-01	6.594999e-01]
% 
% FT7:
% 	P-Value Cutoff:		1.797817e-02
% 	Z-Value Cutoffs:	[-6.830249e-01	6.830275e-01]
% 
% FCz:
% 	P-Value Cutoff:		2.339478e-02
% 	Z-Value Cutoffs:	[-6.544054e-01	6.544053e-01]
% 
% FT8:
% 	P-Value Cutoff:		2.267902e-02
% 	Z-Value Cutoffs:	[-6.578326e-01	6.578327e-01]
% 
% TP9:
% 	P-Value Cutoff:		2.238608e-02
% 	Z-Value Cutoffs:	[-6.592629e-01	6.592633e-01]
% 
% CPz:
% 	P-Value Cutoff:		2.216450e-02
% 	Z-Value Cutoffs:	[-6.603555e-01	6.603560e-01]
% 
% TP10:
% 	P-Value Cutoff:		2.309241e-02
% 	Z-Value Cutoffs:	[-6.558418e-01	6.558421e-01]
% 
% PO9:
% 	P-Value Cutoff:		1.795627e-02
% 	Z-Value Cutoffs:	[-6.831572e-01	6.831564e-01]
% 
% POz:
% 	P-Value Cutoff:		2.500473e-02
% 	Z-Value Cutoffs:	[-6.470162e-01	6.470164e-01]
% 
% PO10:
% 	P-Value Cutoff:		2.695641e-02
% 	Z-Value Cutoffs:	[-6.385928e-01	6.385950e-01]
%
% These appear much better than results from yesterday's thresholding attempt (at least thresholds were found for all of
% the data). P-value cutoffs look a little suspicious to me; at ~0.02 these results aren't much lower than 0.05. I'm
% tentative about this because FWER-corrected p-value thresholds I've seen in literature are usually in the ballpark of
% 0.0001 or so (+/- an order of magnitude...I can't really remember).



%% 1119 - Imaging Thresholded Correlation Data Above
% Today's parameters
timeStamp = '201411061119';
analysisStamp = 'Thresholded Average BOLD-%s Correlation';

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
    currentCorr = maskImageSeries(currentCorr,logical(colinMask), NaN);
    
    bp = BrainPlot(...
        currentCorr,...
        'Anatomical', colinBrain,...
        'AxesColor', 'k',...
        'CLim', [-2 2],...
        'Color', 'w',...
        'ColorbarLabel', 'Z-Scores',...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', meanData.Lags,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slices);
    
    Today.SaveImage(bp, timeStamp, sprintf(analysisStamp, channels{a}), {'fig', 'png'});
    
    bp.close();
end

% Results:
% 



%% 1324 - Working on a Zooming Feature for the BrainPlot Class
% Log parameters
analysisStamp = 'Thresholded Average BOLD-%s Correlation';

slices = 48:4:64;

threshTimeStamp = '201411061102';
meanFile = Today.FindFiles(threshTimeStamp);
meanFile.Load();

fpz = meanData.FPz.Mean(:, :, slices, :);
cutoffs = meanData.FPz.CutoffZValues;

fpz(fpz > cutoffs(1) & fpz < cutoffs(2)) = NaN;

Files.ColinBrain.Load();
colinBrain = colinBrain(:, :, slices);
colinMask = colinMask(:, :, slices);

% Mask out the skull & do a histogram adjustment 
% This brightens up the anatomical data. Values used are from examining the histogram of data
colinBrain(colinMask == 0) = 0;
colinBrain(colinBrain > 5e6) = 4.5e6;                               % <-- Remove high intensity outlier voxels
colinBrain(colinBrain > 4e6) = colinBrain(colinBrain > 4e6) + 5e5;  % <-- Increase intensity of these data (gray & white matter)
    
bp = BrainPlot(...
    fpz,...
    'Anatomical', colinBrain,...
    'AxesColor', 'k',...
    'CLim', [-2 2],...
    'Color', 'w',...
    'ColorbarLabel', 'Z-Scores',...
    'Title', sprintf(analysisStamp, 'FPz'),...
    'XLabel', 'Time Shift (s)',...
    'XTickLabel', meanData.Lags,...
    'YLabel', 'Slice Number',...
    'YTickLabel', slices);



%% 1356 - Re-Imaging the Thresholded BOLD-EEG Correlations
% Log parameters
timeStamp = '201411061356';
analysisStamp = 'Thresholded Average BOLD-%s Correlation';
dataSaveName = 'X:/Data/Today/20141106/201411061356 - ';

slices = 48:4:64;

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

Files.ColinBrain.Load();
colinBrain = colinBrain(:, :, slices);
colinMask = colinMask(:, :, slices);

% Mask out the skull & do a histogram adjustment
colinBrain(colinMask == 0) = 0;
colinBrain(colinBrain > 5e6) = 4.5e6;
colinBrain(colinBrain > 4e6) = colinBrain(colinBrain > 4e6) + 5e5;

for a = 1:length(channels)
    
    currentCorr = meanData.(channels{a}).Mean(:, :, slices, :);
    currentCutoff = meanData.(channels{a}).CutoffZValues;
    
    currentCorr(currentCorr > currentCutoff(1) & currentCorr < currentCutoff(2)) = NaN;
    currentCorr = maskImageSeries(currentCorr,logical(colinMask), NaN);
    
    bp = BrainPlot(...
        currentCorr,...
        'Anatomical', colinBrain,...
        'AxesColor', 'k',...
        'CLim', [-2 2],...
        'Color', 'w',...
        'ColorbarLabel', 'Z-Scores',...
        'MinorFontSize', 16,...
        'Title', sprintf(analysisStamp, channels{a}),...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', meanData.Lags,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slices);
    
    Today.SaveImage(bp, timeStamp, sprintf(analysisStamp, channels{a}), {'fig', 'png'});
    
    bp.close();
end

% Results:



%% 1445 - Thresholding Average BOLD-EEG Correlations using FDR
% The thresholding process above uses SGoF to correct for the multiple comparisons problem. However, corrected
% thresholds still appear slightly off to me (p < ~0.02), so I want to double check those results using an alternative
% FWER correction method. This section will redo the earlier analysis using False Discovery Rate (FDR) instead.

% Log parameters
timeStamp = '201411061445';
analysisStamp = '';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

% Display some of the results in the console
str = ['\n%s:\n'...
            '\tP-Value Cutoff:\t\t%d\n'...
            '\tZ-Value Cutoffs:\t[%d\t%d]\n'];
        
for a = 1:length(channels)
    
    chan = meanData.(channels{a});
    currentChannel = chan.Mean(:);
    currentChannel(isnan(currentChannel) | currentChannel == 0) = [];
    
    currentMeanVal = mean(currentChannel);
    
    pCutoff = fdr(chan.PValues, 0.05);
    
     % Convert the p-value cutoff into two z-score cutoffs (one for each tail)
    zCutoffs = [NaN, NaN];
    if (~isnan(pCutoff))
        idsSig = chan.PValues < pCutoff;
        idsLowerTail = currentChannel < currentMeanVal;
        idsUpperTail = currentChannel > currentMeanVal;
        
        zCutoffs(1) = max(currentChannel(idsLowerTail & idsSig));
        zCutoffs(2) = min(currentChannel(idsUpperTail & idsSig));
    end
    
    fprintf(1, str, channels{a}, pCutoff, zCutoffs(1), zCutoffs(2));
    
end

% Results:
%
% FPz:
% 	P-Value Cutoff:		4.999983e-02
% 	Z-Value Cutoffs:	[-5.657937e-01	5.657940e-01]
% 
% FT7:
% 	P-Value Cutoff:		5.000000e-02
% 	Z-Value Cutoffs:	[-5.657933e-01	5.657930e-01]
% 
% FCz:
% 	P-Value Cutoff:		4.999977e-02
% 	Z-Value Cutoffs:	[-5.657939e-01	5.657937e-01]
% 
% FT8:
% 	P-Value Cutoff:		4.999999e-02
% 	Z-Value Cutoffs:	[-5.657934e-01	5.657931e-01]
% 
% TP9:
% 	P-Value Cutoff:		4.999999e-02
% 	Z-Value Cutoffs:	[-5.657933e-01	5.657930e-01]
% 
% CPz:
% 	P-Value Cutoff:		4.999998e-02
% 	Z-Value Cutoffs:	[-5.657936e-01	5.657931e-01]
% 
% TP10:
% 	P-Value Cutoff:		4.999994e-02
% 	Z-Value Cutoffs:	[-5.657932e-01	5.657935e-01]
% 
% PO9:
% 	P-Value Cutoff:		5.000000e-02
% 	Z-Value Cutoffs:	[-5.657929e-01	5.657929e-01]
% 
% POz:
% 	P-Value Cutoff:		4.999976e-02
% 	Z-Value Cutoffs:	[-5.657935e-01	5.657935e-01]
% 
% PO10:
% 	P-Value Cutoff:		4.999992e-02
% 	Z-Value Cutoffs:	[-5.657933e-01	5.657941e-01]
%
% Hmm. This definitely isn't better than the results from SGoF.



%% 1742 - Thresholding Single-Subject BOLD-EEG Correlation Data
% Log parameters
timeStamp = '201411061742';
analysisStamp = '%02d Thresholded Z-Scored BOLD-EEG Correlations';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

zCorrTimeStamp = '201410151226';
corrFiles = Today.FindFiles(zCorrTimeStamp);

pbar = Progress('Thresholding Single Subject BOLD-EEG Correlations', 'Channels Processed');
for a = 1:length(corrFiles)
    
    corrData = corrFiles(a).Load();
    
    pbar.Reset(2);
    for b = 1:length(channels)
        
        currentCorr = corrData.(channels{b});
        
        % Reformat the correlation data structure to hold summary statistics
        corrData.(channels{b}) = struct(...
            'Correlation',      currentCorr,...
            'CutoffPValue',     [],...
            'CutoffZValues',    [],...
            'PValues',          []);
        
        % Flatten correlation data & get rid of empty values
        currentCorr = currentCorr(:);
        currentCorr(isnan(currentCorr) | currentCorr == 0) = [];
        currentMeanVal = mean(currentCorr);
        
        % Convert z-scores to p-values
        pvals = 2 * normcdf(-abs(currentCorr), 0, 1);
        corrData.(channels{b}).PValues = pvals;
        
        pCutoff = sgof(pvals, 0.05);
        corrData.(channels{b}).CutoffPValue = pCutoff;
        
         % Convert the p-value cutoff into two z-score cutoffs (one for each tail)
        zCutoffs = [NaN, NaN];
        if (~isnan(pCutoff))
            idsSig = pvals < pCutoff;
            idsLowerTail = currentCorr < currentMeanVal;
            idsUpperTail = currentCorr > currentMeanVal;

            zCutoffs(1) = max(currentCorr(idsLowerTail & idsSig));
            zCutoffs(2) = min(currentCorr(idsUpperTail & idsSig));
        end

        corrData.(channels{b}).CutoffZValues = zCutoffs;
        
        pbar.Update(2, b/length(channels));
    end
    
    Today.SaveData(timeStamp, sprintf(analysisStamp, a), corrData);
    
    pbar.Update(1, a/length(corrFiles));
end    