function correlation_map = dataobject_bold_ephys_correlation(data_object, shifts_vector, trials_vector, channels_vector)
% DATAOBJECT_BOLD_EPHYS_CORRELATION
% Produces a correlation map of correlating the BOLD and ephys signals.
% Only works if they are sampled identically
%
% correlation_map           Cell array (once cell per trial), the first
%                           dimensions are spatial correlation (same as
%                           BOLD) the second to last dimension is shifts
%                           correlsponding to shifts_vector (below), the
%                           last dimension is channels
%   = dataobject_bold_ephys_correlation(
%       data_object,
%       shifts_vector,      Time shifts to calculate, in seconds
%       trials_vector,      Scans/trials to use (default all)
%       channels_vector     Channels to use (default all)
%       )
%
% Uses: fc_2D_manual_seed, ncc, combine_4Dto3D, split_2D_3D

% Get which trials
if ~exist('trials_vector','var') || isempty(trials_vector)
    trials_vector = 1:length(data_object.data.ephys);
end

% Get which channels
if ~exist('channels_vector','var')  || isempty(channels_vector)
    all_channels = true;
else
    all_channels = false;
end

% Allocate correlation map
correlation_map = cell(length(trials_vector),1);

% Loop through each trial and calculate correlation
for trial_index = trials_vector
    % Get sampling rate
    if (1./data_object.parameters.bold_tr(trial_index)) ~= data_object.parameters.ephys_sampling_rate(trial_index)
        error('BOLD and ephys are at different  sampling rates.');
    end
    sf = data_object.parameters.ephys_sampling_rate(trial_index);
    
    % Convert shifts in seconds to samples
    shifts_vector_samples = round(shifts_vector .* sf);
    % Get data
    BOLD = data_object.data.bold{trial_index};
    ephys = data_object.data.ephys{trial_index};
    mn = data_object.data.mn{trial_index};
    if length(size(mn)) >= 3
        mn = combine_3Dto2D(mn,1);
    end
    % Get parameters from ephys
    if size(ephys,1) > size(ephys,2)
        ephys = ephys';
    end
    if all_channels
        num_channels = size(ephys,1);
        channels_vector = 1:num_channels;
    end
    % Allocate
    size_BOLD = size(BOLD);
    these_maps = zeros([size_BOLD(1:(end-1)),length(shifts_vector_samples),length(channels_vector)]);
    % Calculate for each channel
    for channel_index = 1:length(channels_vector)
        % Get channel of interest
        channel = ephys(channels_vector(channel_index),:);
        % Calculate at each shift
        for shift_index = 1:length(shifts_vector_samples)
            % Combine 4D->2D
            if length(size_BOLD) >= 4
                BOLD = combine_4Dto3D(BOLD,1);
            end
            % Correlate with BOLD
            this_map = fc_2D_manual_seed(BOLD,mn,channel,shifts_vector_samples(shift_index));
            % Split 2D->4D
            if length(size_BOLD) >= 4
                this_map = split_2D_3D(this_map,[size_BOLD(1),size_BOLD(2)]);
            end
            % Store
            eval(['these_maps(' repmat(':,',[1 (length(size_BOLD) - 1)]) 'shift_index,channel_index) = this_map;']);
        end
    end
    % Garbage collect
    clear mn;
    clear BOLD;
    clear ephys;
    clear channel;
    % Store
    correlation_map(trial_index,1) = {these_maps};
end
