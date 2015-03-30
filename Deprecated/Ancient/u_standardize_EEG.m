function outputData = u_standardize_EEG(inputData, inputChannels, paramStruct)

%% Initialize
allChannels = paramStruct.general.channels;

% Initialize the output array
outputData = zeros(length(allChannels), size(inputData, 2));

%% Arrange EEG-Based Data Array to Have a Standard Number of Channels
for i = 1:length(allChannels)
    compCheck = strcmp(allChannels{i}, inputChannels);
    if sum(compCheck)
        matchInd = find(compCheck);
        outputData(i, :) = inputData(matchInd, :);
    else
        outputData(i, :) = NaN;
    end
end


