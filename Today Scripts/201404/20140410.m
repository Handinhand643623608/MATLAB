%% 20140410


%% 1557 - Re-Generating EEG Inter-Electrode Correlation Images (Pre-/Post-CSR)
% Don't have the original .fig files for these, and I need to make some
% serious formatting changes for the publication.

% Image data before CSR
load masterStructs;
searchStr = 'dcZ';
eegFiles = get(fileData([fileStruct.Paths.Desktop '/EEG Data/'], 'search', searchStr), 'Path');

% Concatenate inter-electrode correlations (only include electrodes present for all subjects)
allCorr = [];
for a = 1:length(eegFiles);
    load(eegFiles{a});
    
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            allCorr = cat(3, allCorr, corrcoef(eegData(b).Data.EEG(1:64, :)'));
        end
    end
end

% Average correlation values
meanCorr = nanmean(allCorr, 3);
channels = eegData(1).Channels;

% Image the data & set appropriate font sizes, labels, etc.
figure; 
imagesc(meanCorr, [-1 1]);
cbar = colorbar;
set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
set(cbar, 'YTick', -1:0.5:1);
set(gca, 'FontSize', 20);
set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
xlabel('Electrode Index', 'FontSize', 25);
ylabel('Electrode Index', 'FontSize', 25);
saveas(gcf, 'Inter-Electrode Correlations (Pre-CSR).png', 'png');
saveas(gcf, 'Inter-Electrode Correlations (Pre-CSR).fig', 'fig');
close all

% Now image after CSR was performed
load masterStructs;
searchStr = 'dcGRZ';
eegFiles = get(fileData([fileStruct.Paths.Desktop '/EEG Data/'], 'search', searchStr), 'Path');

% Concatenate inter-electrode correlations (only include electrodes present for all subjects)
allCorr = [];
for a = 1:length(eegFiles);
    load(eegFiles{a});
    
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            allCorr = cat(3, allCorr, corrcoef(eegData(b).Data.EEG(1:64, :)'));
        end
    end
end

% Average correlation values
meanCorr = nanmean(allCorr, 3);
channels = eegData(1).Channels;

% [~, idsSorted] = sort(meanCorr);
% sortTest = zeros(1, size(idsSorted, 2));
% for a = 1:size(idsSorted, 2)
%     sortedCorr = meanCorr(idsSorted(:, a), idsSorted(:, a));
%     testMat = sortedCorr(2:end, 2:end) > sortedCorr(1:end-1, 1:end-1);
%     sortTest(a) = sum(testMat(:));
% end
% idxBestSort = idsSorted(:, sortTest == max(sortTest));
% meanCorr = meanCorr(idxBestSort, idxBestSort);

% Image the data & set appropriate font sizes, labels, etc.
figure; 
imagesc(meanCorr, [-1 1]);
axis square;
cbar = colorbar;
set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
set(cbar, 'YTick', -1:0.5:1);
set(gca, 'FontSize', 20);
set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
xlabel('Electrode Index', 'FontSize', 25);
ylabel('Electrode Index', 'FontSize', 25);
saveas(gcf, 'Inter-Electrode Correlations (Post-CSR).png', 'png');
saveas(gcf, 'Inter-Electrode Correlations (Post-CSR).fig', 'fig');
close all


%% 1633 - Re-Generating EEG Inter-Electrode Anticorrelation Frequency Images (Pre-/Post-CSR)
% Same situation as the last entry. A lot of formatting changes are needed for the publication.
% These are plots of the frequency of anticorrelations between all possible electrode pairings

% Image data before CSR
load masterStructs;
searchStr = 'dcZ';
eegFiles = get(fileData([fileStruct.Paths.Desktop '/EEG Data/'], 'search', searchStr), 'Path');

% Concatenate inter-electrode correlations (only include electrodes present for all subjects)
acorrFreqs = zeros(64, 64);
for a = 1:length(eegFiles);
    load(eegFiles{a});
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            tempCorr = corrcoef(eegData(b).Data.EEG(1:64, :)');
            tempCorr(tempCorr > 0) = 0;
            tempCorr(tempCorr < 0) = 1;
            acorrFreqs = acorrFreqs + tempCorr;
        end
    end
end

% Image the data & set appropriate font sizes, labels, etc.
figure;
imagesc(acorrFreqs, [0 17]);
axis square;
cbar = colorbar;
set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
set(cbar, 'YTick', 1:4:17);
set(gca, 'FontSize', 20);
set(get(cbar, 'YLabel'), 'String', 'Count', 'FontSize', 25);
xlabel('Electrode Index', 'FontSize', 25);
ylabel('Electrode Index', 'FontSize', 25);
saveas(gcf, 'Inter-Electrode Anticorrelation Frequency (Pre-CSR).png', 'png');
saveas(gcf, 'Inter-Electrode Anticorrelation Frequency (Pre-CSR).fig', 'fig');

% Image data after CSR
load masterStructs;
searchStr = 'dcGRZ';
eegFiles = get(fileData([fileStruct.Paths.Desktop '/EEG Data/'], 'search', searchStr), 'Path');

% Concatenate inter-electrode correlations (only include electrodes present for all subjects)
acorrFreqs = zeros(64, 64);
for a = 1:length(eegFiles);
    load(eegFiles{a});
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
            tempCorr = corrcoef(eegData(b).Data.EEG(1:64, :)');
            acorrFreqs(tempCorr < 0) = acorrFreqs(tempCorr < 0) + 1;
        end
    end
end

% [~, idsSorted] = sort(acorrFreqs);
% sortTest = zeros(1, size(idsSorted, 2));
% for a = 1:size(idsSorted, 2)
%     sortedFreqs = acorrFreqs(idsSorted(:, a), idsSorted(:, a));
%     testMat = sortedFreqs(2:end, 2:end) > sortedFreqs(1:end-1, 1:end-1);
%     sortTest(a) = sum(testMat(:));
% end
% idxBestSort = idsSorted(:, sortTest == max(sortTest));
% acorrFreqs = acorrFreqs(idxBestSort, idxBestSort);
% 
idsMaxFreq = acorrFreqs == 17;

% Image the data & set appropriate font sizes, labels, etc.
figure;
imagesc(acorrFreqs, [0 17]);
axis square;
cbar = colorbar;
set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
set(cbar, 'YTick', 1:4:17);
set(gca, 'FontSize', 20);
set(get(cbar, 'YLabel'), 'String', 'Count', 'FontSize', 25);
xlabel('Electrode Index', 'FontSize', 25);
ylabel('Electrode Index', 'FontSize', 25);
saveas(gcf, 'Inter-Electrode Anticorrelation Frequency (Post-CSR).png', 'png');
saveas(gcf, 'Inter-Electrode Anticorrelation Frequency (Post-CSR).fig', 'fig');


%% 1648 - Investigating Some Channels (P3, Pz, PO7) that Appear Bad in Data Above
% These channels are different in correlation & anticorrelation frequency behavior than all other
% channels.
load masterStructs;
searchStr = 'dcZ';
eegFiles = get(fileData([fileStruct.Paths.Desktop '/EEG Data/'], 'search', searchStr), 'Path');

windowObj('Size', 'fullscreen');

count = 0;
for a = 1:length(eegFiles)
    load(eegFiles{a});
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)
                subplot(17, 3, (count)*3+1);
                plot(eegData(b).Data.EEG(strcmpi(eegData(b).Channels, 'P3'), :));
                if (a == 1 && b == 1); title('P3', 'FontWeight', 'bold'); end;
                if (count ~= 16); set(gca, 'XTick', []); end;
                subplot(17, 3, (count)*3+2);
                plot(eegData(b).Data.EEG(strcmpi(eegData(b).Channels, 'PZ'), :));
                if (a == 1 && b == 1); title('PZ', 'FontWeight', 'bold'); end;
                if (count ~= 16); set(gca, 'XTick', []); end;
                subplot(17, 3, (count)*3+3);
                plot(eegData(b).Data.EEG(strcmpi(eegData(b).Channels, 'PO7'), :));
                if (a == 1 && b == 1); title('PO7', 'FontWeight', 'bold'); end;
                if (count ~= 16); set(gca, 'XTick', []); end;
                count = count + 1;
        end
    end
end

