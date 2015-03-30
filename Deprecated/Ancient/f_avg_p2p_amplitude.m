function avg_p2p = f_avg_p2p_amplitude(wave_data)
%% f_avg_p2p_amplitude finds the average peak-to-peak amplitude over a
% waveform
%
%   Syntax:
%   avg_p2p = f_avg_p2p_amplitude(wave_data)
%   
%   WAVE_DATA: A waveform vector for which peak-to-peak amplitudes are to
%              be determined
% 
%   Written by Josh Grooms on 3/12/2012

% Rectify the waveform in order to perform peak detection (only works for positive peaks)
rect_data = abs(wave_data);

% Perform the peak detection
[wave_peaks peak_locs] = findpeaks(rect_data);

% Acquire the peak-to-peak amplitudes over the waveform
peak_vals = wave_data(peak_locs);
p2p_vals = diff(peak_vals);

% Take absolute values of peak-to-peak differences
p2p_vals = abs(p2p_vals);

% Average the peak-to-peak amplitudes together
avg_p2p = mean(p2p_vals);