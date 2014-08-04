%% 20140701 


%% 1458 - 
% Today's parameters
timeStamp = '201407011458';
analysisStamp = 'SWC Parameter Optimization';
dataSaveName = 'I:/Research/Today Data/201407011458 - BOLD-FPz SWC Parameter Optimization';
warning('off', 'all');
% matlabpool

% Analysis parameters
segmentLengths = 1:100;     % <--- Cover various window lengths (1 sample : 100 samples) = (2s : 200s)
segmentOffsets = 0:100;     % <--- Cover various segment offsets (0 samples : 100 samples) = (0s : 200s)

% Data objects temporarily located on desktop. SSD on the lab computer crashed again...
boldFiles = Search(Paths, 'Desktop', 'boldObject');
eegFiles = Search(Paths, 'Desktop', 'eegObject');

load(boldFiles{1});
load(eegFiles{1});

[funData, idsNaN] = ToMatrix(boldData);
ephysData = ToArray(eegData, 'FPz');

% Procedure outline
% - Take a segment of EEG data
% - Take a segment of BOLD data
% - For each segment length, determine the signal offset at which MI is maximized

miData = zeros(size(funData, 1), length(segmentOffsets), length(segmentLengths));

pbar = progress('Segments Finished', 'Offsets Finished');
for a = 1:length(segmentLengths)
    len = segmentLengths(a);
    
    % Get the first segment of EEG data
    currentEEG = Signal.discretize(ephysData(1:len));
    
    reset(pbar, 2);
    for b = 1:length(segmentOffsets)
        offset = segmentOffsets(b);
        for c = 1:size(funData, 1)
            idxStart = 1+offset;
            idxEnd = idxStart + len - 1;
            currentBOLD = Signal.discretize(funData(c, idxStart:idxEnd));
            miData(c, b, a) = Signal.entropy(currentEEG) - Signal.entropy(currentEEG, currentBOLD, 'conditional');
        end
        update(pbar, 2, b/length(segmentOffsets));
    end
    update(pbar, 1, a/length(segmentLengths));
end
close(pbar);

save([dataSaveName '.mat'], '-v7.3');

% Analysis is taking way too long. Need to optimize this code and get parallel processing involved (intimately, by the
% remaining time estimate of ~weeks). Interrupted at a = 7, b = 21, c = 80839. Saved current results in case they might
% be useful in the future.