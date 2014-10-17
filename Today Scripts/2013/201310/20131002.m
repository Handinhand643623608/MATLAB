%% 20131002


%% 1211
% Need to generate better images for publication, starting with removing unecessary time shifts
load masterStructs
ccPath = [fileStruct.Paths.DataObjects '/Partial Correlation/BOLD-EEG'];
searchStr = 'meanPartialCorrObject_*.*_dcCSRZ';
ccFiles = get(fileData(ccPath, 'search', searchStr), 'Path');

% AF7: -12:18
% C3: -4:18
% FPZ: -2:18
% PO8: -18:14
% PO10: -20:2

shiftStruct = struct(...
    'AF7', [-12:2:18],...
    'C3', [-4:2:18],...
    'FPZ', [-2:2:18],...
    'PO8', [-18:2:14],...
    'PO10', [-20:2:2]);

for a = 1:length(ccFiles)
    load(ccFiles{a})
    
    currentChannel = meanCorrData.Parameters.Correlation.Channels{1};
    currentShifts = shiftStruct.(currentChannel);
    
    brainData(a) = plot(meanCorrData,...
        'CLim', [-3 3],...
        'TimeShifts', currentShifts,...
        'Thresholding', 'on');
end
store(brainData, 'ext', {'png', 'fig'});
close(brainData)
