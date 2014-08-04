function route(networkData)





% Determine which neurons have just fired
firingData = [networkData.Neurons.IsFiring]';
firingNeurons = find(firingData);

% Loop through the firing neurons
for a = 1:length(firingNeurons)
    % Get data on the current output signal
    idxFiringNeuron = firingNeurons(a);
    firingParams = networkData.Neurons(idxFiringNeuron).Output;

    % Determine where to route the current signal & the signal's travel time
    targetNeurons = networkData.Connectivity(idxFiringNeuron, :);
    travelTimes = networkData.Distance(idxFiringNeuron, targetNeurons)./firingParams.Velocity;

    % Store signals in a buffer until travel times have elapsed & change neuron firing status
    buffer(networkData, targetNeurons, travelTimes, firingParams);
    networkData.Neurons(firingNeurons(a)).IsFiring = false;
end