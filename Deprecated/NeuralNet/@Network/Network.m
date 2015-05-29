classdef Network < hgsetget
    
    
    
    %TODO: Optimize internodal distance calculations
    %TODO: Implement higher dimensional (>2) neuron arrays
    
    
    %% Network Properties
    properties
        Aether
        Buffer
        Clock
        Connectivity
        Distance
        Neurons
        Visualization
    end
    
    
    %% Constructor Method
    methods
        function networkData = NeuralNet(varargin)
            
            % Initialize a list of usable neurotransmitters
            ntList = {'glutamate'};
%             
%             ntList = {...
%                 'glutamate',...
%                 'dopamine',...
%                 'serotonin',...
%                 'epinephrine',...
%                 'norepinephrine',...
%                 'histamine',...
%                 'gaba',...
%                 'glycine',...
%                 'acetylcholine',...
%                 'vasopressin',...
%                 'oxytocin',...
%                 'histamine',...
%                 };
            
            % Initialize the discretized network space (one element per neuron)
            networkDim = 10;
            
            % Compute distances between all possible node pairings
            distanceArray = zeros(networkDim^2);
            for a = 1:size(distanceArray, 1)
                for b = 1:size(distanceArray, 2)
                    [row1, col1] = ind2sub(networkDim, a);
                    [row2, col2] = ind2sub(networkDim, b);
                    distanceArray(a, b) = sqrt((row1-row2)^2 + (col1-col2)^2);
                end
            end
            
            % Initialize the network aether
            aetherSpace(networkDim^2, networkDim^2) = NetworkAether;
            connectivityArray = logical(randi(2, size(aetherSpace)) - 1);
            for a = 1:size(aetherSpace, 1)
                for b = 1:size(aetherSpace, 2)
                    set(aetherSpace(a, b),...
                        'ConductionVelocity', 1,...
                        'Distance', distanceArray(a, b),...
                        'Neurotransmitter', 'glutamate',...
                        'SignalGain', 1);
                    
                    if connectivityArray(a, b)
                        aetherSpace(a, b).IsConnected = true;
                    end
                end
            end
                            
            
            
            
            
            

            % Populate a spatial environment with neurons
            neuronArray(networkDim, networkDim) = Neuron;
            networkData.Neurons = neuronArray;
            for a = 1:numel(networkData.Neurons)
                set(networkData.Neurons(a),...
                    'Address', a,...
                    'Input', struct(...
                        'DecayConstant', 1,...
                        'Neurotransmitter', 'glutamate',...
                        'Value', 0),...
                    'Output', struct(...
                        'Neurotransmitter', 'glutamate',...
                        'Velocity', 1),...
                    'ParentNetwork', networkData,...
                    'Threshold', struct(...
                        'Default', 5,...
                        'Value', 5));
            end
            
            % Initialize the signal buffer
            bufferArray(networkDim, networkDim) = SignalBuffer;

        end
    end
        
    
    %% Network Runtime Methods
    methods    
        % Method for continuous network operation
        function run(networkData)
            while true
                % Detect firing neurons & route their signals to the appropriate targets
                route(networkData)
                % Update the user's network visualization
                visualize(networkData)
                % Increment the clock & update all clock-dependent functions
                tick(networkData)
            end
        end
        
        % Method for updating clock-dependent functions & properties
        function update(networkData)
            % Update clock-dependent properties of each neuron
            for a = 1:numel(networkData.Neurons); tick(networkData.Neurons(a)); end
            % Update clock-dependent network properties
            if ~isempty(networkData.Buffer)
                networkData.Buffer.TravelTimes = networkData.Buffer.TravelTimes - 0.1;
                while networkData.Buffer.TravelTimes(1) <= 0
                    targetNeuron = networkData.Buffer.TargetNeurons(1);
                    neurotransmitter = networkData.Buffer.Neurotransmitters{1};
                    value = networkData.Buffer.Values(1);

                    input(networkData.Neurons(targetNeuron), neurotransmitter, value);

                    networkData.Buffer.Neurotransmitters(1) = [];
                    networkData.Buffer.TargetNeurons(1) = [];
                    networkData.Buffer.TravelTimes(1) = [];
                    networkData.Buffer.Values(1) = [];
                end
            end
        end
        
        % Register neuronal outputs to the signal buffer
        function registerFiringEvent(networkData, firingNeuronAddress)
            targetNeurons = networkData.Connectivity(firingNeuronAddress, :);
            
            
        end
        
        % Method for routing signals to the correct neurons
        route(networkData)
        % Method for storing signals until travel time has elapsed
        buffer(networkData)
        % Method for visualizing network activations
        visualize(networkData)
        

    end
end


%% Characteristics of the Neural Network Environment


% Maintains an environment for neurons to exist in
%       Compartmentalized by neurotranmitter type
%               Assigns groups of neurons to each compartment
%       Maintains excitability indices for each compartment
%               Initialized to some value at first
%               Eventually will be dynamic & modulated by neuronal activity
%       Maintains a clock to synchronize actions


% Maintains the neuronal population
%       Initializes neuronal population
%               Provides neurotranmitter type
%               Provides spatial location
%       Adds & removes connections
%               Random initialization
%               Eventually reshapes connections based on Hebbian principles
%       Adds & removes neurons


% Routes signals throughout the network
%       Uses a neuron address table
%               Assigns coded addresses to every individual neuron
%       Implements signal delays
%               Based on distance & conduction velocity
