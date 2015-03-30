%% s_correlation_plot_network is taken from s_correlation_images & s_correlation_average. This code generates the mean BOLD signal (thresholded) overlaid on anatomical images
%   Written by Josh Grooms on 2/17/2012
%         Modified on 3/6/2012

% Initialize important workspace parameters
subjects_to_run = [1 2 4 5 7];
subject_scans = {...
    [1 2]
    [1 2]
    []
    [1 2]
    [1 2]
    []
    [1 2]};
scans_vector = 1:size(subject_scans,1);
electrodes_to_use = {'FPZ' 'P8'};
slices_to_examine = 48:4:64;
TR = 2;                         % <--- TR in seconds
time_shifts_to_try = -20:2:10;  % <--- Time shifts (in seconds) to try
time_shifts_to_plot = 1:3:16;
pos_threshold = [0.2107 0.2037];         % <--- From bh_fdr
neg_threshold = [-0.2057 -0.2015];        % <--- From bh_fdr

% Load data stored elsewhere
load EEG_labels.mat;
if ~exist('anatomical_data')
    load generic_anatomical_data.mat;
end
if exist('all_subject_maps') == 0        % <--- Allow loading before script is run (slow otherwise)
    load correlation_results_2012_03_05;
end

% Create the file names & image titles
title_starter = 'Subjects ';
title_ender = ' %s-fMRI Mean Thresholded Correlation';
for i = subjects_to_run
    title_starter = [title_starter num2str(i) ' (Scans ' num2str(subject_scans{i}) ')'];
    if i ~= subjects_to_run(end)
        title_starter = [title_starter ', '];
    else
        title_starter = [title_starter title_ender];
    end
end

%% Create the mean data
% Pre-allocate to avoid memory errors
s1 = size(all_subject_maps{1}{1});
num_scans = 0;
for i = 1:length(subject_scans)
    num_scans = num_scans + numel(subject_scans{i});
end
catdata = zeros([s1 num_scans]);

% Concatenate all subjects one matrix along the 6th dimension
k = 1;
for i = subjects_to_run
    for j = subject_scans{i}
        catdata(:, :, :, :, :, k) = all_subject_maps{i}{j};
        k = k + 1;
    end
end

% Average the data
mean_catdata = mean(catdata, 6);

%% Prepare data for plotting, create & save images
% Shape anatomical data
anatomical_segment_of_interest = anatomical_data(:, :, slices_to_examine);

% Add in dimension of time shift to maintain compatibility with functional data
for i = 1:length(time_shifts_to_plot)
    anatomical_segment_of_interest(:, :, :, i) = anatomical_data(:, :, slices_to_examine);
end

% Continue shaping data
anatomical_segment_of_interest = permute(anatomical_segment_of_interest,[2 1 3 4]);       % Make rows into columns and columns into rows 
anatomical_segment_of_interest = flipdim(anatomical_segment_of_interest,1);               % Flip the matrix upside down (first row becomes last row)

% Combine 4D data into 3D data (2D space plus time)
anatomical_segment_of_interest = combine_4Dto3D(anatomical_segment_of_interest, length(slices_to_examine));
    
% Combine 3D data into 2D data
anatomical_segment_of_interest = combine_3Dto2D(anatomical_segment_of_interest, 1);   

% Remove the 0s in the data to help ease of plot interpretation
anatomical_segment_of_interest(0 == anatomical_segment_of_interest) = NaN;

% Shape the functional data
for i = 1:length(electrodes_to_use)
    segment_of_interest = mean_catdata(:, :, slices_to_examine, :, i);
    segment_of_interest = permute(segment_of_interest,[2 1 3 4]);       % Make rows into columns and columns into rows 
    segment_of_interest = flipdim(segment_of_interest,1);               % Flip the matrix upside down (first row becomes last row)

    % Combine 4D data into 3D data (2D space plus time)
    segment_of_interest = combine_4Dto3D(segment_of_interest, length(slices_to_examine));

    % Combine 3D data into 2D data
    segment_of_interest = segment_of_interest(:, :, time_shifts_to_plot);
    segment_of_interest = combine_3Dto2D(segment_of_interest, 1);   
    
    % Calculate ticks for plot axes
    y_tick = size(segment_of_interest, 1);
    x_tick = size(segment_of_interest, 2);    
    y_tick_locations = 55:(600-55)/5:600;
    x_tick_locations = 50:(415-50)/4:415;
    
    % Remove the 0s in the data to help ease of plot interpretation
    segment_of_interest(0 == segment_of_interest) = NaN;
    
    %% Plot & save the data
    % Plot the data
    plot_name = sprintf(title_starter, electrodes_to_use{i});
    wrapped_plot_name = textwrap({plot_name}, 70);
    figure
    plot_network(anatomical_segment_of_interest, segment_of_interest, pos_threshold(i), [], neg_threshold(i))
    title(wrapped_plot_name)
    label_image_axes((slices_to_examine),'bottom',gcf, x_tick_locations)
    label_image_axes(time_shifts_to_try(time_shifts_to_plot),'left',gcf, y_tick_locations)
    ylabel('Time Shift (Seconds)')
    xlabel('Slice')
    saveas(gcf, [plot_name '.png'], 'png')

end






