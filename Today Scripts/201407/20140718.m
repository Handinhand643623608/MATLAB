%% 20140718 


pathStruct = struct(...
    'DerekData', '/home/dsmith374/Dynamic_Control_DA/PreprocessedDC',...
    'ChristineData', '/home/cgodwin9/DMC2/preprocessed');



%% 1001 - Imaging Derek's Existing BOLD Data

% Get the most recent preprocessed data
boldFiles = get(fileData([pwd '/PreprocessedDC'], 'Search', 'boldObject.*2014071(4|5)'), 'Path');

% Generate & save plots of the existing data
for a = 1:length(boldFiles)
    load(boldFiles{a});
    brainData = Plot(boldData);
    Store(brainData, 'Path', [pwd '/JKG/Images'], 'Overwrite', true);
    close(brainData);
end



% Results: subject 3 has the most obvious problems. After scan 1, the brain appears much larger than it should and may
% not be normalized to MNI space properly.


%% 1137 - Imaging More Slices of Derek's Data
% Plot parameters
slicesToPlot = round(linspace(1, 91, 21));

% Get the most recent preprocessed data
boldFiles = get(fileData([pwd '/PreprocessedDC'], 'Search', 'boldObject.*2014071(4|5)'), 'Path');

% Generate & save plots of the existing data
for a = 1:length(boldFiles)
    load(boldFiles{a});
    
    funData = ToArray(boldData);
    funData(funData == 0) = nan;
    
    timesToPlot = round(linspace(1, size(funData, 4), 21));
    
    brainData = brainPlot('mri', funData(:, :, slicesToPlot, timesToPlot),...
        'CLim', [-3 3],...
        'ColorbarLabel', 'Z-Scores',...
        'Title', sprintf('Subject %d Scan %d BOLD Data', boldData.Subject, boldData.Scan),...
        'XLabel', 'Time (s)',...
        'XTickLabel', timesToPlot.*(boldData.TR/1000),...
        'YLabel', 'Slice Number',...
        'YTickLabel', slicesToPlot);
    Store(brainData, 'Path', [pwd '/JKG/Images/Many Slices'], 'Overwrite', true);
    close(brainData);
end


% Results: slice z-locations are variable, which shouldn't be the case. Also, number of slices present varies between
% scans.



%% 1238 - Imaging Many Slices of Christine's Data

load pathStruct;

% Plot parameters
slicesToPlot = round(linspace(1, 91, 21));

% Get the most recent preprocessed data
boldFiles = get(fileData(pathStruct.ChristineData, 'Search', 'boldObject.*201407(09|10)'), 'Path');

% Generate & save plots of the existing data
for a = 1:length(boldFiles)
    load(boldFiles{a});
    
    funData = ToArray(boldData);
    funData(funData == 0) = nan;
    
    timesToPlot = round(linspace(1, size(funData, 4), 21));
    
    brainData = brainPlot('mri', funData(:, :, slicesToPlot, timesToPlot),...
        'CLim', [-3 3],...
        'ColorbarLabel', 'Z-Scores',...
        'Title', sprintf('Subject %d Scan %d BOLD Data', boldData.Subject, boldData.Scan),...
        'XLabel', 'Time (s)',...
        'XTickLabel', timesToPlot.*(boldData.TR/1000),...
        'YLabel', 'Slice Number',...
        'YTickLabel', slicesToPlot);
    Store(brainData, 'Path', [pwd '/Christine''s Data/Images/Many Slices'], 'Overwrite', true);
    close(brainData);
end



%% 1307 - Summary of Observations

% Some component of the preprocessing pipeline is clearly failing in a big way. In both Derek's & Christine's, four
% things stand out above all: variable numbers of brain slices, variable slice locations, signal dropout, and signal
% intensity issues in the first TR. These problems are visible in more than just one data set, too.
%
% Need to have a look at motion data for the problem scans as well as the reslicing procedure run during preprocessing
% (pretty sure this is one of the AFNI stages).
%
% Also still need to turn off slice timing correction.




%% 1408 - 
% Today's parameters
timeStamp = '201407181408';
analysisStamp = 'Derek''s Data - Motion Parameters';
dataSaveName = '/home/jgrooms/Desktop/Today Data/20140718/201407181408-%d-%d - %s%s';

boldFiles = search(pathStruct.DerekData, 'boldObject.*2014071(4|5)');

for a = 1:length(boldFiles)
    
    load(boldFiles{a});
    
    mparams = boldData.Data.Nuisance;
    mparams = mparams.Motion';
    time = (1:size(mparams, 1)).*boldData.TR/1000;
    
    windowObj('Size', 'fullscreen');
    plot(time, mparams, 'LineWidth', 4);
    
    title(sprintf('Subject %d Scan %d Motion Parameters', boldData.Subject, boldData.Scan), 'FontSize', 20);
    xlabel('Time (s)', 'FontSize', 20);
    set(gca, 'FontSize', 16);
    
    saveas(gcf, sprintf(dataSaveName, boldData.Subject, boldData.Scan, analysisStamp, '.png'), 'png');
    close
end
    


%% 1422 - 
% Today's parameters
timeStamp = '201407181422';
analysisStamp = 'Christine''s Data - Motion Parameters';
dataSaveName = '/home/jgrooms/Desktop/Today Data/20140718/201407181422-%d-%d - %s%s';

boldFiles = get(fileData(pathStruct.ChristineData, 'Search', 'boldObject.*201407(09|10)'), 'Path');

for a = 1:length(boldFiles)
    
    load(boldFiles{a});
    
    mparams = boldData.Data.Nuisance;
    mparams = mparams.Motion';
    time = (1:size(mparams, 1)).*boldData.TR/1000;
    
    windowObj('Size', 'fullscreen');
    plot(time, mparams, 'LineWidth', 4);
    
    title(sprintf('Subject %d Scan %d Motion Parameters', boldData.Subject, boldData.Scan), 'FontSize', 20);
    xlabel('Time (s)', 'FontSize', 20);
    set(gca, 'FontSize', 16);
    
    saveas(gcf, sprintf(dataSaveName, boldData.Subject, boldData.Scan, analysisStamp, '.png'), 'png');
    close
end
    