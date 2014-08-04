classdef Neuron < hgsetget
    
    
%% Implementation Ideas
%
%   Need methods for adjusting the firing threshold
%       - Should depend on recent activity
%           > Very recent activity would raise the threshold (refractoriness)
%           > Moderately recent activity would return the threshold to it's permanent value
%           > Past activity would 
%       - Should be unrelated (or distally related) to plasticity phenomena.
%           > Because it affects the efficacy of all synaptic inputs
%
%   Need a method for output frequency coding
%       - Pretty important to typical neurons
%       - Place coding implemented in the network

    
    %% Individual Neuron Properties
    properties
        Address
        FireCount
        FiringRate
        Input
        Output
        ParentNetwork
        Threshold
        TickCount
    end
    
    
    
    %% Constructor Method
    methods
        function neuronData = Neuron(varargin)
            
            % Override default properties with inputs
            inStruct = struct(...
                'Address', 1,...
                'Input', struct(...
                    'DecayConstant', 1,...
                    'Neurotransmitter', 'glutamate',...
                    'Value', 0),...
                'IsFiring', false,...
                'ParentNetwork', [],...
                'Threshold', struct(...
                    'LongTerm', 5,...
                    'ShortTerm', 5));
            assignInputs(inStruct, varargin);
            
            % Assign property values to the neuron
            assignProperties(inStruct, neuronData); 
        end
    end
    
    
    %% Neuron Functionality Methods
    methods
        % Method for updating internal neuron data per clock tick
        function update(neuronData)
            % Input decay
            if neuronData.Input.Value > 0
                neuronData.Input.Value = neuronData.Input.Value - 0.1*neuronData.Input.DecayConstant; 
                % Don't let input decay introduce refractoriness
                if neuronData.Input.Value < 0
                    neuronData.Input.Value = 0;
                end
            end
            
            % Excitability/refractoriness decay
            if neuronData.Threshold.Value < neuronData.Threshold.Default
                neuronData.Threshold.Value = neuronData.Threshold.Value + 0.1*neuronData.Input.DecayConstant;
            elseif neuronData.Threshold.Value > neuronData.Threshold.Default
                neuronData.Threshold.Value = neuronData.Threshold.Value - 0.1*neuronData.Input.DecayConstant;
            end
        end
        
        % Method for processing input information
        function input(neuronData, neurotransmitter, value)
            if strcmpi(neurotransmitter, neuronData.Input.Neurotransmitter)
                neuronData.Input.Value = neuronData.Input.Value + value;
                % If the threshold is met, report a firing event to the network, reset input potentials, & implement refractoriness
                if neuronData.Input.Value > neuronData.Threshold.Value
                    registerFiringEvent(neuronData.ParentNetwork, neuronData.Address);
                    neuronData.Input.Value = 0;
                    neuronData.Threshold.Value = 10;
                end
            end
        end
    end
    
    
    
    %% 
    methods
        % Override default neuron properties with input values
        function assignProperties(inStruct, neuronData)
            propNames = fieldnames(inStruct);
            for a = 1:length(propNames)
                neuronData.(propNames{a}) = inStruct.(propNames{a});
            end
        end
    end
end


%% Neuron Characteristics

% Processes inputs
%       Input compatibility
%               NT provided in input method must match the NT specified for this neuron's input
%       Sums compatible input values
%       Compares input summation to firing threshold
%               If threshold is met/exceeded, the neuron will fire an output
%                       Eventually will include a probabilistic component for error/natural variation
%                       Input value resets to zero
%               Tf threshold is not met, decays the input value
%                       Linearly at first, but will eventually be the more realistic exponential decay
%                       One decay increment per clock tick

% Generates an output
%       If triggered by input processing
%       Output specified by a value and an NT
%               NT here can be different than input NT
%                       Allows conversion & talk between network compartments

% Receives network clock ticks
%       Sub-threshold input values decay some amount every tick

% Implements refractoriness
%       Specified by a time length & excitability modification
