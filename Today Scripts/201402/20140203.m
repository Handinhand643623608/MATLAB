%% 20140203


%% 0004 - Thresholding Mean BOLD-EEG Partial Coherence Data
load masterStructs
cohFiles = get(fileData([fileStruct.Paths.DataObjects '/Partial Coherence'], 'Search', 'meanPartial.*fb_.*_GSControl'), 'Path');



for a = 2:length(cohFiles)
    load(cohFiles{a});
    threshold(meanCohData);
    clear meanCohData;
end
    