%% 20140818 


%% 1544 - Plotting Infraslow (0.02-0.08 Hz) EEG Channel Traces
% Today's parameters
timeStamp = '201408181544';
analysisStamp = '%s Infraslow (0.02-0.08 Hz) EEG Traces';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140818/201408181544-%d - %s%s';


eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject');


for a = 1:length(eegFiles)
    
    load(eegFiles{a});
    Filter(eegData, 'Passband', [0.02 0.08]);
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
    
    

%% 1800 - 
% Today's parameters
timeStamp = '201408181800';
analysisStamp = '%s Infraslow (0.02-0.08 Hz) EEG Traces';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140818/201408181800-%d - %s%s';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject');

for a = 1:length(eegFiles)
    
    load(eegFiles{a});
    Filter(eegData, 'Passband', [0.02 0.08], 'UseZeroPhaseFilter', false);
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



%% 1816 - 
% Today's parameters
timeStamp = '201408181816';
analysisStamp = '%s Infraslow (0.03-0.08 Hz) EEG Traces';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140818/201408181816-%d - %s%s';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject');

for a = 1:length(eegFiles)
    
    load(eegFiles{a});
    Filter(eegData, 'Passband', [0.03 0.08], 'UseZeroPhaseFilter', false);
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



%% 2124 - 
% Today's parameters
timeStamp = '201408182124';
analysisStamp = '%s Infraslow (0.03-0.08 Hz) EEG Traces';
dataSaveName = 'E:/Graduate Studies/Lab Work/Data Sets/Today Data/20140818/201408182124-%d - %s%s';

eegPath = [get(Paths, 'EEG') '/Unfiltered'];
eegFiles = search(eegPath, 'eegObject');

for a = 1:length(eegFiles)
    
    load(eegFiles{a});
    Filter(eegData, 'Passband', [0.03 0.08], 'UseZeroPhaseFilter', false);
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