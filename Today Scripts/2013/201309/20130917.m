%% 20130917 - Today

%% 1429
% channels = {'C3', 'FPZ', 'PO8', 'PO10', 'AF7'};
channels = {'C3', 'PO8', 'PO10', 'AF7'};

cohStruct = parameters(cohObj);
cohStruct.Initialization.GSR = [false false];
cohStruct.Coherence.Masking.Threshold = 0.875;

for a = 1:length(channels)
    cohStruct.Coherence.Channels = channels(a);
    cohData = cohObj(cohStruct);
    store(cohData);
    meanCohData = mean(cohData);
    store(meanCohData);
    clear cohData meanCohData
end


%% 1840
% Noticed GM & WM masks are switched in BOLD data objects. This may have tragic consequences for
% data that depends on this :(
load masterStructs
boldFiles = get(fileData(fileStruct.Paths.Raw, 'Search', 'boldObject'), 'Path');

currentSubject = 8;
load(boldFiles{1});
tempGM = boldData.Data.Segments.WM;
boldData.Data.Segments.WM = boldData.Data.Segments.GM;
boldData.Data.Segments.GM = tempGM;
clear temp*

progBar = progress('Updating BOLD Data Objects');
for a = 2:length(boldFiles)
    currentBOLD = load(boldFiles{a});
    tempGM = currentBOLD.boldData.Data.Segments.WM;
    currentBOLD.boldData.Data.Segments.WM = currentBOLD.boldData.Data.Segments.GM;
    currentBOLD.boldData.Data.Segments.GM = tempGM;
    clear temp*
    
    if currentBOLD.boldData.Subject == currentSubject
        boldData(currentBOLD.boldData.Scan) = currentBOLD.boldData;
    else
        zscore(boldData);
        store(boldData);
        
%         for b = 1:length(boldData)
%             prepCondition(boldData(b))
%         end
%         
%         store(boldData)
        clear boldData
        
        boldData = currentBOLD.boldData;
        currentSubject = boldData.Subject;
    end
    update(progBar, a/length(boldFiles));
end
close(progBar)
    
    