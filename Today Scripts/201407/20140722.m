%% 20140722 


%% 0715 - Interelectrode EEG Correlations for Classical EEG Passbands
% Today's parameters
timeStamp = '201407220715';
analysisStamp = '%s Band EEG Interelectrode Correlations';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140722/201407220715 - %s%s';
imSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140722/%s/201407220715-%d - %s%s'

bandStrs = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
passbands = {[1, 4], [4, 8], [8, 13], [13, 30], [30, 100]};

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject', 'Ext', '.mat');

corrData = nan(68, 68, 17);

% Create & image correlations by scan
pbar = progress('EEG Interelectrode Correlations', 'Scans Completed');
for a = 1:length(bandStrs)
    
    currentAnalysis = sprintf(analysisStamp, bandStrs{a});
    
    reset(pbar, 2);
    for b = 1:length(eegFiles)
        load(eegFiles{b})
        Filter(eegData, 'Passband', passbands{a});
        ephysData = ToArray(eegData);
        corrData(:, :, b) = corrcoef(ephysData');

        figure;
        imagesc(corrData(:, :, b), [-1 1]);
        cbar = colorbar;
        set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
        set(cbar, 'YTick', -1:0.5:1);
        set(gca, 'FontSize', 20);
        set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
        xlabel('Electrode Index', 'FontSize', 25);
        ylabel('Electrode Index', 'FontSize', 25);
        imSaveStrPNG = sprintf(imSaveName, bandStrs{a}, b, currentAnalysis, '.png');
        imSaveStrFIG = sprintf(imSaveName, bandStrs{a}, b, currentAnalysis, '.fig');
        saveas(gcf, imSaveStrPNG, 'png');
        saveas(gcf, imSaveStrFIG, 'fig');
        close;

        update(pbar, 2, b/length(eegFiles));
    end

    % Average data together & save everything
    meanCorrData = nanmean(corrData, 3);
    dataSaveStr = sprintf(dataSaveName, currentAnalysis, '.mat');
    save(dataSaveStr, 'corrData', 'corrData', 'meanCorrData', '-v7.3');

    % Image the average interelectrode correlations
    figure;
    imagesc(meanCorrData, [-1 1]);
    cbar = colorbar;
    set(gca, 'XTick', 0:10:64, 'YTick', 0:10:64);
    set(cbar, 'YTick', -1:0.5:1);
    set(gca, 'FontSize', 20);
    set(get(cbar, 'YLabel'), 'String', 'r', 'FontSize', 25);
    xlabel('Electrode Index', 'FontSize', 25);
    ylabel('Electrode Index', 'FontSize', 25);
    imSaveStrPNG = sprintf(dataSaveName, analysisStamp, '.png');
    imSaveStrFIG = sprintf(dataSaveName, analysisStamp, '.fig');
    saveas(gcf, imSaveStrPNG, 'png');
    saveas(gcf, imSaveStrFIG, 'fig');
    close all;
    
    update(pbar, 1, a/length(bandStrs));
end
close(pbar);



%% 0908 - Plotting Infraslow EEG Channel Traces
% Today's parameters
timeStamp = '201407220908';
analysisStamp = '%s Infraslow EEG Traces';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140722/201407220908-%d - %s%s'

eegFiles = GetEEG(Paths);


for a = 1:length(eegFiles);
    
    load(eegFiles{a});
    [ephysData, channels] = ToArray(eegData);
    
    t = (1:size(ephysData, 2))./eegData.Fs;
    
    for b = 1:length(channels)
        
        figure;
        plot(t, ephysData(b, :));
        title(sprintf('%d - %s', a, channels{b}));
        xlabel('Time (s)');
        ylabel('Z-Scores');
        
        saveStr = sprintf(dataSaveName, a, sprintf(analysisStamp, channels{b}), '.png');
        saveas(gcf, saveStr, 'png');
        
        close
    end
end
    


%% 1147 - Working Out Manual Conversion of DICOM Mosaics to Volume Arrays
% Today's parameters
timeStamp = '201407221147';

numRows = 5;
numCols = 5;

load([get(Paths, 'Desktop') '/prepMotion.mat']);


mnDCM = boldData.Preprocessing.Files.MeanDCM;
mnIMG = boldData.Preprocessing.Files.IMG.Mean(1:end-2);
numSlices = boldData.Acquisition.NumberOfSlices;

mn = dicomread(mnDCM);
mn = double(mn);

stride = size(mn, 1)/numRows;

mnVolume = zeros(stride, stride, numRows*numCols);

idxRow = 0:stride:size(mn, 1);

c = 1;
for a = 1:length(idxRow) - 1
    
    for b = 1:length(idxRow) - 1
        
        mnVolume(:, :, c) = mn(idxRow(a)+1:idxRow(a + 1), idxRow(b)+1:idxRow(b + 1));
        c = c + 1;
    end
end

mnVolume = mnVolume(:, :, 1:numSlices);



%% 1213 - Working Out Manual NIFTI File Writing
% Today's parameters
timeStamp = '201407221213';

voxelSize = boldData.Acquisition.VoxelSize;

imgStruct = make_nii(mnVolume, voxelSize);

mnFile = [get(Paths, 'Desktop'), '/MeanImage.img'];

save_nii(imgStruct, mnFile);



%% 1237 - Working Out Manual Functional Image Permuation/Orientation for NIFTI Files
% Today's parameters
timeStamp = '201407221237';

mnIMG = load_nii(mnFile);
mnIMG = mnIMG.img;

mnIMG = permute(mnIMG, [2 1 3]);
mnIMG = flipdim(mnIMG, 2);


% brainPlot('mri', mnIMG, 'YTickLabel', 1:22);
for a = 1:22
    figure;
    imagesc(mnIMG(:, :, a));
end



%% 1510 - Working Out Manual Conversion of Anatomical DICOMs to NIFTI Files
% Today's parameters
timeStamp = '201407221510';

anatomicalFiles = search(boldData.Preprocessing.Folders.Anatomical, [], 'Ext', '.dcm');

anatomicalData = zeros(256, 256, length(anatomicalFiles));

for a = 1:length(anatomicalFiles)
    
    anatomicalData(:, :, a) = dicomread(anatomicalFiles{a});
    
end


for a = round(linspace(1, length(anatomicalFiles), 30))
    figure;
    imagesc(anatomicalData(:, :, a));
end
    
    