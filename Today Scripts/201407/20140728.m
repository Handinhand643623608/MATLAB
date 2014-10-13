%% 20140728 


%% 1548 - Imaging Many Slices of My Data to See if NIFTI Conversion Problem Affects It
% Today's parameters
timeStamp = '201407281548';
analysisStamp = 'Many Slices of BOLD Data';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140728/201407281548 - %s%s';
imSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20140728/201407281548-%d - %s%s';

slicesToPlot = round(linspace(1, 91, 21));

boldFiles = GetBOLD(Paths);

for a = 1:length(boldFiles)
    load(boldFiles{a});
    brainData = Plot(boldData, 'Slices', slicesToPlot);
    saveas(brainData.FigureHandle, sprintf(imSaveName, a, analysisStamp, '.png'), 'png');
    close(brainData);
end

    


