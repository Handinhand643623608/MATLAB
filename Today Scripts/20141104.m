%% 20141104 


%% 1234 - Concatenating RSN-EEG MS Coherence Data from 20141003
% Today's parameters
timeStamp = '201411041234';
analysisStamp = 'Concatenated RSN-EEG Coherence Data';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
networkNames = {...
    'AnteriorSalience',...
    'Auditory',...
    'BasalGanglia',...
    'DorsalDMN',...
    'HighVisual',...
    'Language',...
    'LeftExecutiveControl',...
    'PosteriorSalience',...
    'Precuneus',...
    'PrimaryVisual',...
    'RightExecutiveControl',...
    'Sensorimotor',...
    'VentralDMN',...
    'Visuospatial'};

cohTimeStamp = '201410311231';
cohFiles = Today.FindFiles(cohTimeStamp);

catCohData = emptystruct(networkNames{:});
for a = 1:length(networkNames)
    catCohData.(networkNames{a}) = emptystruct(channels{:});
end

for a = 1:length(cohFiles)
    cohData = cohFiles(a).Load();
    for b = 1:length(networkNames)
        for c = 1:length(channels)
            catCohData.(networkNames{b}).(channels{c}) = cat(2, catCohData.(networkNames{b}).(channels{c}), cohData.(networkNames{b}).(channels{c}));  
        end
    end
end
catCohData.Frequencies = cohData.Frequencies;
Today.SaveData(timeStamp, analysisStamp, catCohData);



%% 1250 - Averaging RSN-EEG Coherence Data Concatenated Above
% Today's parameters
timeStamp = '201411041250';
analysisStamp = 'Averaged RSN-EEG Coherence Data';
dataSaveName = 'X:/Data/Today/20141104/201411041250 - ';

meanCohData = emptystruct(networkNames{:});
for a = 1:length(networkNames)
    meanCohData.(networkNames{a}) = emptystruct(channels{:});
end

for a = 1:length(networkNames)
    for b = 1:length(channels)
        meanCohData.(networkNames{a}).(channels{b}).Mean = nanmean(catCohData.(networkNames{a}).(channels{b}), 2);
        meanCohData.(networkNames{a}).(channels{b}).STD = nanstd(catCohData.(networkNames{a}).(channels{b}), [], 2);
    end
end
meanCohData.Frequencies = catCohData.Frequencies;
Today.SaveData(timeStamp, analysisStamp, meanCohData);



