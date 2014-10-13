%% 20140716 


%% 1651 - 
% Today's parameters
timeStamp = '201407161651';
analysisStamp = 'EEG Signal Phase Over Time';
imSaveName = '201407161651 - %03d%s';

imFolderPath = 'C:/Users/jgrooms/Desktop/Today Data/20140716/%d';

load('C:\Users\jgrooms\Desktop\Today Data\20140715\201407151200 - EEG Phase Mapping.mat')


for a = 1:size(phaseData, 3)
    
    currentFolder = sprintf(imFolderPath, a);
    if ~exist(currentFolder, 'dir'); mkdir(currentFolder); end
    
    for b = 1:size(phaseData, 2)
        
        
        map = eegMap(phaseData(:, b, a),...
            'Color', 'k',...        
            'Labels', 'off');
        
        
        currentName = sprintf(imSaveName, b, '.png');
        saveas(map.FigureHandle, [currentFolder '/' currentName], 'png');
        
        close(map);
    end
end
            
        
        
        
        