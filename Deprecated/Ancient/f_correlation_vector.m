function [corr_vector mean_vector] = f_correlation_vector(correlation_data, electrodes_to_use, separate_electrode_data)
%% f_correlation_vector creates a vector of EEG-fMRI correlation data and a vector of all data averaged together.
%   
%   Syntax:
%   [corr_vector mean_vector] = f_correlation_vector(correlation_data, electrodes_to_use, separate_electrode_data)
%   
%   CORRELATION_DATA: The EEG-fMRI correlation matrix (all subjects and scans, unmodified).
%   ELECTRODES_TO_USE: A cell of electrode labels (strings) that correspond
%                      to the correlation data matrix (must also be in the same order).
%   SEPARATE_ELECTRODE_DATA: Enter "1" to return a matrix of correlation
%                            data, where rows correspond to correlation data for individual
%                            electrodes. Enter "0" to have all electrode
%                            data combined into one vector.
   
%   Written by Josh Grooms on 3/7/2012

%% Initialize function-specific parameters
num_electrodes = length(electrodes_to_use);
size_corr = size(correlation_data{1}{1});
catdata = cell(num_electrodes, 1);
mean_catdata = cell(num_electrodes, 1);

% Figure out the number of subjects and scans, and correlation entries
num_scans = 0;
i = 1;
corr_length = length(correlation_data);
while i <= corr_length
    if isempty(correlation_data{i})
        correlation_data(i) = [];
        corr_length = length(correlation_data);
    else
        num_scans = num_scans + length(correlation_data{i});
        i = i + 1;
    end
end
num_subjects = length(correlation_data);


%% Create the vectors
switch separate_electrode_data
    case 1
        % Pre-allocate to avoid memory errors
        num_corr_one_sub = numel(correlation_data{1}{1}(:, :, :, :, 1));
        num_corr = num_corr_one_sub * num_scans;
        mean_vector = zeros(num_electrodes, num_corr_one_sub);
        corr_vector = zeros(num_electrodes, num_corr);
        for i = 1:num_electrodes
            catdata{i} = zeros([size_corr(1:4) num_scans]);
        end        
       
        % Concatenate all subjects into one matrix along the fifth dimension per electrode
        for i = 1:num_electrodes
            for j = 1:num_subjects
                for k = 1:length(correlation_data{j})
                    for L = 1:num_scans
                        catdata{i}(:, :, :, :, L) = correlation_data{j}{k}(:, :, :, :, i);
                    end
                end
            end
        end
        
        % Create the vector of correlation results
        for i = 1:num_electrodes
            corr_vector(i, :) = catdata{i}(:);
        end
        
        % Create the mean vector of correlation results
        for i = 1:length(catdata)
            mean_catdata{i} = mean(catdata{i}, 5);
            mean_vector(i, :) = mean_catdata{i}(:);
        end
        
    case 0
        % Pre-allocate to avoid memory errors
        num_corr_one_sub = numel(correlation_data{1}{1});
        num_corr = num_corr_one_sub * num_scans;
        mean_vector = zeros(1, num_corr_one_sub);
        corr_vector = zeros(1, num_corr);
        catdata = zeros([size_corr num_scans]);
        
        % Concatenate all subjects into one matrix along the 6th dimension
        for i = 1:num_subjects
            for j = 1:length(correlation_data{i})
                for k = 1:num_scans
                    catdata(:, :, :, :, :, k) = correlation_data{i}{j};
                end
            end
        end
        
        % Create the vector of all correlation results
        corr_vector = catdata(:)';
        
        % Calculate the mean correlation vector
        mean_catdata = mean(catdata, 6);
        mean_vector = mean_catdata(:)';
end         
                
       