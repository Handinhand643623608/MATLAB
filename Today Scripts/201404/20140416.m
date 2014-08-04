%% 20140416


%% 1333 - Re-Running BOLD-EEG Partial Correlations without Controlling for BOLD Global Signal
% Unfortunately, I didn't hold on to thee original data sets, so I have to re-run the entire
% correlation analysis from the base BOLD/EEG data.

% Initialize correlation parameters
load masterStructs
gmMask = load_nii(fileStruct.Files.Segments.Gray); gmMask = gmMask.img;
channels = {'AF7', 'FPZ', 'C3', 'PO8', 'PO10'};
ccStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', {{[0.01 0.08], [0.01 0.08]}},...
        'GSR', [false false],...
        'Modalities', 'BOLD-EEG',...
        'Relation', 'Partial Correlation',...
        'ScanState', 'RS'),...
    'Correlation', struct(...
        'Control', {{'Motion', 'WM', 'CSF'}},...
        'Channels', [],...
        'Fs', 0.5,...
        'GenerateNull', false,...
        'Mask', [],...
        'MaskThreshold', [],...
        'Scans', [],...
        'Subjects', [],...
        'TimeShifts', [-20:2:20]),...
    'Thresholding', struct(...
        'AlphaVal', 0.05,...
        'CDFMethod', 'arbitrary',...
        'FWERMethod', 'sgof',...
        'Mask', gmMask,...
        'MaskThreshold', 0.7,...
        'Parallel', 'gpu',...
        'Tails', 'both'));
    
progbar = progress('BOLD-EEG Partial Correlation (No GS Control)');
for a = 1:length(channels)
    ccStruct.Correlation.Channels = channels(a);
    corrData = corrObj(ccStruct);
    store(corrData);
    meanCorrData = mean(corrData);
    store(meanCorrData);
    clear corrData meanCorrData;
    update(progbar, a/length(channels));
end


%% 1437 - Imaging the Correlations Above
% Using the imaging code written on 20140411, but modifying it slightly (made new paths for
% permanent storage of data objects, removing statistical significance stuff)

% Initialize formatting variables
cle;
load masterStructs;
searchPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG/'];
searchStr = 'mean.*_20140416';
corrFiles = get(fileData(searchPath, 'search', searchStr), 'Path');
slicesToPlot = 48:4:64;
shiftsToPlot = -20:4:20;
pixelCrop = 7;

% Load the Colin brain in order to use its brain mask (removes a lot of edge-of-brain junk)
load([fileStruct.Paths.Main '/Special Functions/@brainViewer/colinBrain.mat']);
colinBrain = colinBrain(:, :, slicesToPlot);
colinMask = colinMask(:, :, slicesToPlot);

% a = 1;
for a = 1:length(corrFiles)
    % Load the correlation data & pull important parameters from the data object
    load(corrFiles{a});
    channel = meanCorrData.Parameters.Correlation.Channels{1};
    idsShifts = ismember(meanCorrData.Parameters.Correlation.TimeShifts, shiftsToPlot);
    currentData = meanCorrData.Data.(channel)(:, :, slicesToPlot, idsShifts);

    % Mask the correlation data using the Colin mask
    for b = 1:size(currentData, 4)
        temp = currentData(:, :, :, b);
        temp(colinMask == 0) = NaN;
        currentData(:, :, :, b) = temp;
    end
    clear temp;
    
    % Crop the correlation images
    currentData(1:pixelCrop, :, :, :) = [];
    currentData(end-pixelCrop:end, :, :, :) = [];
    currentData(:, 1:pixelCrop, :, :) = [];
    currentData(:, end-pixelCrop:end, :, :) = [];

    % Create the montage
    brainData(a) = brainPlot(...
        'mri',...
        currentData,...
        'AxesColor', 'k',...
        'CLim', [-3 3],...
        'Color', 'w',...
        'ColorbarLabel', 'Z-Scores',...
        'Title', ['BOLD-' channel],...
        'XLabel', 'Time Shift (s)',...
        'XTickLabel', shiftsToPlot,...
        'YLabel', 'Slice Number',...
        'YTickLabel', slicesToPlot);

    % Adjust some properties
    set(brainData(a).Axes.Primary, 'Color', 'k');
    set(brainData(a).Axes.Primary, 'FontSize', 20);
    set(get(brainData(a).Colorbar, 'YLabel'), 'FontSize', 25);
    
    saveas(brainData(a).FigureHandle, [fileStruct.Paths.Desktop '/' channel '.png'], 'png')
    saveas(brainData(a).FigureHandle, [fileStruct.Paths.Desktop '/' channel '.fig'], 'fig')
end



%% 1652 - Testing an Idea for Better Correlation
% This is a test of an idea I've entertained for quite a while. To my current thinking, correlation
% (or covariance, in general) appears to have a flaw in the way it's applied to signal processing.
%
% Consider two separate but probably related waveforms (say, one BOLD and one EEG signal). Ordinary
% covariance says that these waveforms are positively associated if the values at each time point in
% both waveforms have the same sign (positive or negative). If the time point values tend to be
% opposite in sign, the association is said to be negative. The strength of any association is given
% by the time points' magnitudes (and the STD of both series in the case of correlation
% coefficients).
%
% These methods are unable to account for signal similarities relating to the direction of magnitude
% change. For example, particularly in the example waveforms chosen, it seems more desirable to
% measure the rise/fall similarities between two waveforms. I.e. as one waveform's amplitude is
% rising, how is the other waveform tending to behave (as a function of time shift, or whatever 
% other considerations need be given). In short, we should be more interested in calculating the
% correlation between the derivatives of these waveforms. In this fashion, positive correlations
% would correspond to coincident signal rise/fall (regardless of amplitude sign) and negative
% correlations would correspond to one signal rising while the other was falling. 
%
% Seems like a simple-enough idea, but I've never seen anything like this in literature. Although,
% it should be said that this could easily (read: very likely does) exist by another jargon-y name
% and, if I did stumble across it, I probably wouldn't recognize it. 
%
% Nevertheless, let's test it out between the infraslow BOLD and EEG data.

% Changeable parameters
channel = 'AF7';
controlDelay = 4*(1/2);  % <--- 4 seconds x BOLD sampling frequency
maxLag = 10;             % <--- In samples (not seconds)

% Load data files
load masterStructs;
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD/']), 'Path');
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG/'], 'Search', 'dcZ'), 'Path');

corrData = nan(91, 109, 91, (2*maxLag + 1), 17);
c = 1;
progbar = progress('BOLD-EEG Derivative Correlation', 'Scans Completed');
for a = 1:length(boldFiles)
    load(boldFiles{a});
    load(eegFiles{a});
    
    for b = 1:length(boldData)
        if (~isempty(boldData(b).Data))
            % Extract the BOLD data
            currentBOLD = boldData(b).Data.Functional;
            currentBOLD = reshape(currentBOLD, [], size(currentBOLD, 4));
            idsMask = isnan(currentBOLD(:, 1));
            currentBOLD(idsMask, :) = [];
            
            % Extract control data
            motionSigs = boldData(b).Data.Nuisance.Motion';
            globalSig = boldData(b).Data.Nuisance.Global';
            wmSig = boldData(b).Data.Nuisance.WM';
            csfSig = boldData(b).Data.Nuisance.CSF';
            
            % Setup control data for each modality
            boldControl = [ones(size(currentBOLD, 2), 1), motionSigs, globalSig, wmSig, csfSig];
            globalSig = [zeros(controlDelay, 1); globalSig(1:end-controlDelay)];
            wmSig = [zeros(controlDelay, 1); wmSig(1:end-controlDelay)];
            eegControl = [ones(size(currentBOLD, 2), 1), motionSigs, globalSig, wmSig, csfSig];
                
            % Extract the EEG data)
            currentEEG = eegData(b).Data.EEG(strcmpi(eegData(b).Channels, channel), :);

            % Regress control data
            currentBOLD = (currentBOLD' - boldControl*(boldControl\currentBOLD'))';
            currentEEG = (currentEEG' - eegControl*(boldControl\currentEEG'))';
            
            % Estimate the derivative for each signal
            currentBOLD = diff(currentBOLD, 1, 2);
            currentEEG = diff(currentEEG, 1, 2);
            
            % Run cross correlation
            tempCorr = xcorrArr(currentBOLD, currentEEG, 'Dim', 2, 'MaxLag', maxLag);
            currentCorr = nan(length(idsMask), size(tempCorr, 2));
            currentCorr(~idsMask, :) = tempCorr;
            currentCorr = reshape(currentCorr, 91, 109, 91, (2*maxLag + 1));
            corrData(:, :, :, :, c) = currentCorr;
            c = c + 1;
        end
        update(progbar, 2, b/length(boldData));
    end
    update(progbar, 1, a/length(boldFiles));
end
close(progbar);
save(['partialCorrData_BOLD-' channel '_dcZ_20140416.mat'], 'corrData');

meanCorrData = nanmean(corrData, 5);
save(['meanPartialCorrData_BOLD-' channel '_dcZ_20140416.mat'], 'meanCorrData');

% Results from one electrode (AF7) are actually pretty similar to the straight correlation results.
% Going to put this aside for now, but may revisit the topic in the future.




%% 2026 - Some Data Exploration

winLength = 50;

load eegObject-1_RS_dcGRZ_20130906;
af7 = eegData(1).Data.EEG(strcmpi(eegData(1).Channels, 'AF7'), :);

af7Mean = [];
af7Var = [];
af7Skew = [];
af7Kurt = [];

for a = 1:length(af7);
    if (a + winLength) > length(af7); winLength = length(af7) - a; end;        
    af7Mean = [af7Mean mean(af7(a:a+winLength))];
    af7Var = [af7Var var(af7(a:a+winLength))];
    af7Skew = [af7Skew skewness(af7(a:a+winLength))];
    af7Kurt = [af7Kurt kurtosis(af7(a:a+winLength))];
end;

figure;
plot(af7);
figure; plot(af7Mean); title('Mean');
figure; plot(af7Var); title('Var');
figure; plot(af7Skew); title('Skew');
figure; plot(af7Kurt); title('Kurt');



