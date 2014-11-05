%% 20141031 


%% 1231 - Fixing Some File Name Formatting Problems for RSN-EEG Coherence Files
% I got sloppy when making the names for these files and when making names for the fields of the data structures that
% they contain. This really needs to be fixed.

% Today's parameters
timeStamp = '201410311231';
analysisStamp = '%02d - RSN-EEG Coherence';

cohStamp = '201410031646';
cohFiles = Today.FindFiles(cohStamp);

maskNames = {...
    'Salience_cort_subcort',...
    'Auditory_cort_subcort',...
    'Basal_Ganglia_cort_subcort',...
    'dDMN_cort_subcort',...         
    'high_Visual_cort_subcort',...
    'Language',...
    'LECN_cort_subcort',...
    'post_Salience_cort_subcort',...
    'Precuneus_cort_subcort',...
    'prim_Visual',...
    'RECN_cort_subcort',...
    'Motor_cort_subcort',...
    'vDMN_cort_subcort',...
    'Visuospatial'};
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

cohData = struct();
order = [1, 10, 11, 12, 2, 3, 4, 5, 6, 7, 8, 9];

fileNums = regexp({cohFiles.Name}', '-\s(\d+)\s', 'tokens');

for a = 1:length(cohFiles)
    oldData = cohFiles(a).Load();
    for b = 1:length(maskNames)
        cohData.(networkNames{b}) = oldData.(maskNames{b});
    end
    cohData.Frequencies = oldData.Frequencies;
    
    Today.SaveData(timeStamp, sprintf(analysisStamp, order(a)), cohData);
end



%% 1323 - Imaging RSN-EEG MS Coherence from 20141003
% Today's parameters
timeStamp = '201410311323';
analysisStamp = '%02d - RSN-EEG Coherence';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};
cohFiles = Today.FindFiles('201410311231');
todayFolder = Today.Data;

for a = 1:length(cohFiles)
    
    cohData = cohFiles(a).Load();
    rsnNames = fieldnames(cohData);
    for b = 1:length(rsnNames)
        
        if (strcmp(rsnNames{b}, 'Frequencies')); continue; end
        rsnFolder = [todayFolder '/' rsnNames{b}];
        
        if (~rsnFolder.Exists); rsnFolder.mkdir(); end
        
        for c = 1:length(channels)
            
            chanFolder = [rsnFolder '/' channels{c}];
            if (~chanFolder.Exists); chanFolder.mkdir(); end
            
            figure;
            plot(cohData.Frequencies, cohData.(rsnNames{b}).(channels{c}));
            xlabel('Frequency (Hz)');
            ylabel('Magnitude^2');
            
            saveas(gcf, [chanFolder.ToString() timeStamp ' - ' sprintf(analysisStamp, a) '.png'], 'png');
            saveas(gcf, [chanFolder.ToString() timeStamp ' - ' sprintf(analysisStamp, a) '.fig'], 'fig');
            
            close;
        end     
    end
end
        
        