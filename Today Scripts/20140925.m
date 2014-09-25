%% 20140925 


%% 1546 - Searching for EEG Channels to Use in BOLD-EEG Analyses
% BOLD-EEG manuscript reviewers didn't like the way we chose electrodes at all. We're now going to choose electrodes for
% comparison with BOLD data by sampling over the whole scalp (basically arbitrarily). This section is devoted to finding
% electrodes that aren't dead or missing across all subjects.

% Today's parameters
timeStamp = '201409251546';
channel = 'FT8';

eegFiles = GetEEG(Paths);
eegFiles(9:13) = [];        %<-- Get rid of subjects 5 & 6



fig = Window('Size', WindowSizes.FullScreen);

for a = 1:length(eegFiles)
    load(eegFiles{a});
    
    subplot(3, 4, a);
    plot(eegData(channel));
    
end

clear eegData;

% Results:
% Good central:         FPz, Fz, FCz, Cz, CPz, 
% Good left lateral:    F7, FT7, C5, TP9, P9, PO3, PO7, PO9
% Good right lateral:   F8, FT8, C6, T8, TP10, P10, PO4, PO8, PO10
%
% Bad electrodes:       T7, Pz, Oz, O9, O10, O1, O2
% Iffy electrodes:      POz