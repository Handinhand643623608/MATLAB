function buffer(networkData, targetNeurons, travelTimes, firingParams)



% Pull buffer data from the network
if isempty(networkData.Buffer)
    networkData.Buffer = struct(...
        'Neurotransmitters', [],...
        'TargetNeurons', [],...
        'TravelTimes', [],...
        'Values', []);
end
buffer = networkData.Buffer;

% Replicate single values to match other input lengths
ntAppend = repmat({firingParams.Neurotransmitter}, [1, length(targetNeurons)]);
valueAppend = repmat(firingParams.Value, [1, length(targetNeurons)]);

% Append inputs to the buffer list
buffer.Neurotransmitters = [buffer.Neurotransmitters ntAppend];
buffer.TargetNeurons = [buffer.TargetNeurons targetNeurons];
buffer.TravelTimes = [buffer.TravelTimes travelTimes];
buffer.Values = [buffer.Values valueAppend];

% Sort the buffer by travel times
bufferStrs = {'Neurotransmitters', 'TargetNeurons', 'Values'};
[buffer.TravelTimes, sortOrder] = sort(buffer.TravelTimes, 'ascend');

for a = 1:length(bufferStrs)
    buffer.(bufferStrs{a}) = buffer.(bufferStrs{a})(sortOrder);
end

% Store updated buffer data in the network
networkData.Buffer = buffer;