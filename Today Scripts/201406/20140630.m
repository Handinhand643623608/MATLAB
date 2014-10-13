%% 20140630 



%% 1448 - Refactor EEG Data Objects to Match New BOLD Object System
% Today's parameters
timeStamp = '201406301448';

eegFiles = GetEEG(Paths, '_dcZ');

paths = Paths;

for a = 1:length(eegFiles)
    load(eegFiles{a});
    
    for b = 1:length(eegData)
        if ~isempty(eegData(b).Data)         
            Store(eegData(b), 'Path', paths.EEG);
        end
    end
end



%% 1737 - BOLD-EEG Mutual Information
% Today's parameters
myPaths = Paths;
timeStamp = '201406301737';
analysisStamp = 'BOLD - EEG Mutual Information';
dataSaveName = 'I:/Research/Today Data/201406301737 - %s.mat'
dataSaveName = sprintf('%s/%s - %s.mat', myPaths.Desktop, timeStamp, analysisStamp);


channels = {'AF7', 'FPz', 'C3', 'PO8', 'PO10'};

boldFiles = GetBOLD(Paths);
eegFiles = GetEEG(Paths);

miData(length(boldFiles)) = struct('Data', []);

pbar = progress('BOLD-EEG Mutual Information', 'Channels Completed');
for a = 1:length(boldFiles)
    
    load(boldFiles{a});
    load(eegFiles{a});
    
    % Extract BOLD data
    funData = ToMatrix(boldData);
    idsNan = isnan(funData(:, 1));
    funData(idsNan, :) = [];
   
    % Extract EEG data
    ephysData = ToArray(eegData, channels);
    
    reset(pbar, 2);
    for b = 1:length(channels)
        
        % Discretize the EEG data
        ephysData(b, :) = Signal.discretize(ephysData(b, :));
        
        % Initialize the data storage
        currentData = nan(length(idsNan), 1);
        tempMI = zeros(size(funData, 1), 1);
        
        % Evaluate mutual information
        for c = 1:size(funData, 1)
            funData(c, :) = Signal.discretize(funData(c, :));
            tempMI(c) = Signal.entropy(funData(c, :)) - Signal.entropy(funData(c, :), ephysData(b, :), 'conditional');
        end
        
        % Store results in the data structure
        currentData(~idsNan) = tempMI;
        miData(a).Data.(channels{b}) = reshape(currentData, [91, 109, 91]);
        
        update(pbar, 2, b/length(channels));
    end
    
    update(pbar, 1, a/length(boldFiles));
end
close(pbar);
            

save(dataSaveName, 'miData', '-v7.3');



%% 2327 - Imaging Results from Above
% Today's parameters
load masterStructs;
timeStamp = '201406302327';
% analysisStamp;
dataSaveName = 'I:/Research/Today Data/201406302327 - ';


for a = 1:length(miData)
    dataToPlot = zeros(91, 109, 91, length(channels));
    for b = 1:length(channels)
        
        dataToPlot(:, :, :, b) = miData(a).Data.(channels{a});
        
    end
    
    brainData(a) = brainPlot('mri', dataToPlot(:, :, 48:4:64, :), 'XTickLabel', channels);
end


        
        