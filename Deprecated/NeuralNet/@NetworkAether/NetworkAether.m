classdef NetworkAether < hgsetget
    %NETWORKAETHER A virtual space that connects neurons and transmits signals between them. 
    %
    %   This object acts as a virtual "wiring" that connects neurons to one another, performing functions similar to an
    %   axon. On its own, a single aether object connects only two neurons (one presynaptic, one postsynaptic). However,
    %   this object is designed to be included in an array with the same dimensionality as the adjacency matrix that
    %   dictates which neurons in a network are connected. In this latter form, the elements of the aether array (or
    %   aether space) emulate the real-world physical network that joins neurons together.
    %
    %   Aether objects perform several functions beyond acting as simple signal relays. They keep track of firing rates,
    %   conduction velocity, interneuronal distance, signal gain, and output neurotransmitters, and they use these data
    %   to model neuronal plasticity processes. For example, signal gain through the aether can be modulated to achieve
    %   effects similar to STDP, LTD, and LTP. Additionally, the aether acts as a signal buffer that stores signals
    %   outputted by a presynaptic neuron and inputs them to the postsynaptic one only after the appropriate travel time
    %   has elapsed. This adds a spatial dependency that's seen in real biological systems and is likely critically
    %   important to nervous tissue function. 
    
    
%% Implementation Ideas
%
%   Need a method for providing inhibitory inputs
%       - Going to be trick, because these are the basis for critically important control loops
%           > Meaning their placement can't be completely arbitrary
%           > Nonetheless, probably going to try arbitrary placement first to see if it can work
%       - Could be implemented as a negative signal gain
%
%   Need methods for strengthening & weakening connections
%       - Should be based on input frequency over time, to model real plasticity
%       - Could be implemented via changes in signal gain
%           > Possibly using a fast/simplified BCM algorithm
%       - Could depend on inhibitory/excitatory nature of the input
%           > Probably not, at first, for simplicity
%       - Possible method outline
%           > Long-term low frequency activity would lower signal gain (emulating LTD)
%           > Long-term high frequency?
%           > Short-term low frequency?
%           > Short-term high frequency activity would raise signal gain (LTP)
%
%   Will eventually need higher dimensional aether arrays
%       - Necessary to support 3D network models
%       - Could even higher dimensions offer any advantage?
%           > 4D hyperbrains!
%
%   Might intentionally omit modeling of axonal "pruning"
%       - Keep things simplistic to start
%       - Investigate keeping the model permanently flexible
%           > The "true" Fountain of Youth!
%           > Unused axons would still develop signal gains of ~0, so this might work...
%
%   Need methods for changing the axonal conduction velocity
%       - Could emulate axonal myelination or differences axon diameters
%       - Not sure how often this measure changes in real neurons, but real neurons can change their spatial locations
%           > Not planning on letting my neurons relocate. Too complicated.
%           > However, similar effects (e.g. new timings, synchronization) can be achieved via conduction velocities
%       - Not sure what conditions will cause this just yet...
%           > Maybe distance between nodes?


    
    
    %% Aether Properties
    properties (SetObservable, AbortSet)
        
        Address
        ConductionVelocity
        Distance
        FireCount
        FiringRate
        IsConnected
        Listeners
        Neurotransmitter
        ParentNetwork
        SignalGain
        SignalRegistry
        TickCount
        
    end
    
    
    %% Constructor Method
    methods
        function aetherData = NetworkAether(varargin)
            %NETWORKAETHER Constructs a virtual network element or array of elements between neurons.
            
            % Initialize default values & settings
            inStruct = struct(...
                'Address', [1, 1],...
                'ConductionVelocity', 1,...
                'Distance', [],...
                'IsConnected', false,...
                'Neurotransmitter', 'glutamate',...
                'ParentNetwork', [],...
                'SignalGain', 1,...
                'Size', 1);
            assignInputs(inStruct, varargin);

            % If a size is specified, output an object array
            if length(Size) == 1; Size = [Size, Size]; end
            aetherData(Size(1), Size(2)) = NetworkAether;

            % Assign property values to the aether objects
            assignProperties(aetherData, inStruct);
            
            % Create listeners for property changes
            createListeners(aetherData);
                
        end
    end
    
    
    %% Public Methods
    methods
        
        
    end
    
    %% Protected Methods
    methods (Access = protected)
        % Method for transferring user inputs to object properties
        function assignProperties(aetherData, inStruct)
            propNames = properties(aetherData(1));
            for a = 1:numel(aetherData)
                for b = 1:length(propNames)
                    
                    % Transfer field values only if fields are common to both the input structure & object
                    if isfield(inStruct, propNames{b})
                        % If arrays of inputs are given, transfer elements to the corresponding object
                        if numel(aetherData) == numel(inStruct.(propNames{b}))
                            aetherData(a).(propNames{b}) = inStruct.(propNames{b})(a);
                        else
                            aetherData(a).(propNames{b}) = inStruct.(propNames{b});
                        end
                    end
                    
                end
            end
        end
        
        % Method for adding listeners for property changes
%         function createListeners(aetherData)
%             aetherData.Listeners = addlistener(aetherData, {...
%                 'TickCount
%             
    end
    
    
end