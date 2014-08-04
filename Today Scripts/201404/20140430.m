%% 20140430 


%% 1633 - Investigating BOLD Activity Around Times when EEG Signals are Very Synchronized.
% Need a summary measure of dynamic infraslow EEG synchronization. For now, going with the mean correlation value across
% electrodes. 

load masterStructs;
% load([fileStruct.Paths.Desktop '/swcData_EEG_(5, 0, 6)_20140501T1025.mat']);
load([fileStruct.Paths.Desktop '/swcData_EEG_(9, 0, 10)_20140428T1228.mat']);
% load([fileStruct.Paths.Desktop '/swcData_EEG_(24, 0, 25)_20140428T1503.mat']);

windowLength = 6;

syncData(8, 3) = struct('CorrelationMeans', [], 'CorrelationSums', []);

for a = 1:size(corrData, 1)
    for b = 1:size(corrData, 2)
        if ~isempty(corrData(a, b).Data)
            
            currentCorr = corrData(a, b).Data;
            currentCorr(currentCorr == 1) = NaN;
            
%             currentCorr = atanh(currentCorr).*sqrt(windowLength-3);     % <--- Garth's r-to-Z transform
            currentCorr = atanh(currentCorr);                           % <--- Fisher's r-to-Z transform
            
            for c = 1:size(currentCorr, 3)
                temp = currentCorr(:, :, c);
                syncData(a, b).CorrelationMeans(c) = nanmean(temp(:));
                temp(isnan(temp)) = 0;
                currentSum = sum(temp(:));
                syncData(a, b).CorrelationSums(c) = currentSum;
            end
        end
    end
end


%% 1930 - Investigating How EEG Synchronizations Might Relate to RSN Time Series (from ICA)
% Going to do some trial runs using subject 1. I'll overlay the RSN and synchronization signals on
% a single plot for visual inspection and do some stationary cross-correlations between them to see
% how strongly they might associate.

if ~exist('boldData', 'var')
    load boldObject-1_RS_dcZ_20131030;
end

% Plot EEG synchronization & DMN/TPN time series for comparison (subject 1, scans 1-2)
x = 1:length(syncData(1, 1).CorrelationMeans);
figure; plot(x, boldData(1).Data.ICA.DMN(x), x, syncData(1, 1).CorrelationMeans); title('S1-1 DMN & EEG Sync');
figure; plot(x, boldData(1).Data.ICA.DAN(x), x, syncData(1, 1).CorrelationMeans); title('S1-1 DAN & EEG Sync');
figure; plot(x, boldData(2).Data.ICA.DMN(x), x, syncData(1, 2).CorrelationMeans); title('S1-2 DMN & EEG Sync');
figure; plot(x, boldData(2).Data.ICA.DAN(x), x, syncData(1, 2).CorrelationMeans); title('S1-2 DAN & EEG Sync');

% Plot EEG synchronization & all RSN time series in a montage (subject 1, scan 1)
icNames = fieldnames(boldData(1).Data.ICA);
figure;
for a = 1:length(icNames)
    subplot(4, 5, a);
    plot(x, boldData(1).Data.ICA.(icNames{a})(x), x, syncData(1, 1).CorrelationMeans);
    title(['S1-1 ' icNames{a} ' & EEG Sync']);
end

% Plot the cross correlation between EEG synchronization & RSN time series (-20s:20s, subject 1 scan 1)
figure;
for a = 1:length(icNames)
    subplot(4, 5, a);
    [currentCorr, lags] = xcorr(diff(boldData(1).Data.ICA.(icNames{a})(x)), diff(syncData(1, 1).CorrelationMeans), 10, 'coeff');
    plot(lags*2, currentCorr);
    title(['S1-1 ' icNames{a} '-EEG Sync xcorr']);
end

% Results: The average EEG inter-electrode correlation appears to be anticorrelated with BOLD DMN
% and TPN time series in these scans, although the cross-correlation results suggest this is not
% likely the case. Across RSNs (IC time series), there isn't much in common, and correlation values
% tend to be low (never outside +/- 0.3, typically around +/- 0.1). Going to try this on subject 1's
% second scan to see if results are at least consistent.


%% 1858 - Repeating Last Section for Subject 1, Scan 2

icNames = fieldnames(boldData(2).Data.ICA);
figure;
for a = 1:length(icNames)
    subplot(4, 5, a);
    plot(x, boldData(2).Data.ICA.(icNames{a})(x), x, syncData(1, 2).CorrelationMeans);
    title(['S1-2 ' icNames{a} ' & EEG Sync']);
end

figure;
for a = 1:length(icNames)
    subplot(4, 5, a);
    [currentCorr, lags] = xcorr(diff(boldData(2).Data.ICA.(icNames{a})(x)), diff(syncData(1, 2).CorrelationMeans), 10, 'coeff');
    plot(lags*2, currentCorr);
    title(['S1-2 ' icNames{a} '-EEG Sync xcorr']);
end

% Results: No real consistency with scan 1's results. Time shifts of peak correlation are nearly
% always completely different, as are the range of correlation values themselves. The lack of any 
% discernable consistency suggest that large-scale EEG synchronization is not related to RSN
% activity, at least as it is identified using ICA. 