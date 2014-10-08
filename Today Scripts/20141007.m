%% 20141007 


%% 1013 - 
% Today's parameters
timeStamp = '201410071013';
analysisStamp = 'Correlation Data Z-Scores';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141007/201410071013 - ';

corrPath = 'C:\Users\jgrooms\Desktop\Today Data\20141003';

corrTimeStamp = '201410031752';
nullTimeStamp = '201410031844';

corrFiles = searchdir(corrPath, corrTimeStamp);
nullFiles = searchdir(corrPath, nullTimeStamp);



%% 1322 - 
% Today's parameters
timeStamp = '201410071322';
analysisStamp = 'BOLD & EEG Autocorrelation Sequence';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141007/201410071322 - '

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

boldFiles = get(Paths, 'InfraslowBOLD');
eegFiles = get(Paths, 'InfraslowEEG');

autoCorrData = struct;

for a = 1:length(boldFiles)
    
    load(boldFiles{a});
    load(eegFiles{a});
    
    [funData, idsNaN] = boldData.ToMatrix();
    ephysData = eegData(channels{:});
    
    [funCorr, lags] = xcorrArr(funData, []);
    ephysCorr = xcorrArr(ephysData, []);
    
    autoCorrData.Functional = struct('Data', funCorr, 'IdsNaN', idsNaN);
    autoCorrData.Ephys = struct('Channels', channels, 'Data', ephysCorr);
    autoCorrData.Lags = lags;
    
    
    