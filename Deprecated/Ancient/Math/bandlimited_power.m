function [signal_in sample_shift] = bandlimited_power(signal_in,fs_in,highpass_in,lowpass_in,highpass_out,lowpass_out,win_type,win_params)
% BANDLIMITED_POWER
% Uses full-wave recfication (Leopold et al., 2003 Cerebral Cortex
% 13:422-433) to produce low frequency fluctuations of the envelope of a
% high frequency power band.
% 
% [
%  signal_out
%  sample_shift
% ] = bandlimited_power(
%                       signal_in,      Input signal
%                       fs,          Sampling rate of input signal
%                                       (default 1/length Hz)
%                       highpass_in,    Highpass frequency for power band
%                                       of interest. (required)
%                       lowpass_in,     Lowpass frequency for power band of
%                                       interest.  default = Inf = no lowpass.
%                       highpass_out,   Highpass frequency for envelope. default = 0
%                                       = no highpass.
%                       lowpass_out,    Lowpass frequency for envelope.
%                                       (required)
%                       win_type        Type of window (see below).
%                                       Default = 'fir1'
%                       win_params      Window parameters (see below).
%                                       Default = [0.5 * (1 / highpass_in)
%                                       0.5 * (1 / highpass_out)]
%                       )
%
% Window types
% 'fir1'        First order FIR filter.
%               win_params is two element vector of filter length for first
%               filtering (to freq. band of interest) and second filtering
%               (to envelope)
% 'fft'         Hard edged filter.
%               win_params is not used

% Check inputs
if ~exist('fs_in','var')
    fs_in = 1/size(signal_in,1);
else
    if isempty(fs_in)
        fs_in = 1/size(signal_in,1);
    end
end
if ~exist('lowpass_in','var')
    lowpass_in = Inf;
else
    if isempty(lowpass_in)
        lowpass_in = Inf;
    end
end
if ~exist('highpass_out','var')
    highpass_out = 0;
else
    if isempty(highpass_out)
        highpass_out = 0;
    end
end
if ~exist('win_type','var')
    win_type = 'fir1';
else
    if isempty(win_type)
        win_type = 'fir1';
    end
end
if ~exist('win_params','var')
    win_params = [];
end

% Default filter length determination
if isempty(win_params) && strcmp(win_type ,'fir1')
    if highpass_in > 0
        win_params_1 = 0.5 * (1/highpass_in);
    else
        win_params_1 = 0.5 * (1/fs_in);
    end
    if highpass_out > 0
        win_params_2 = 0.5 * (1/highpass_out);
    else
        win_params_2 = 0.5 * (1/fs_in);
    end
    win_params = [win_params_1 win_params_2];
end

% "Infinite" lowpass frequency is just Nyquist
if isinf(lowpass_in)
    lowpass_in = fs_in / 2;
end


% Step 1: Filter the data to the frequency of interest
switch win_type
    case 'fir1'
        [signal_in sample_shift] = firfilt(signal_in,highpass_in,lowpass_in,fs_in,round(win_params(1)));
    case 'fft'
        signal_in = bfilt(signal_in,highpass_in,lowpass_in,fs_in,0);
        sample_shift = 0;
    otherwise
        error([win_type ' is not a valid window type.']);
end

% Step 2: Full-wave rectify
signal_in = abs(signal_in);

% Step 3: Filter to get just the lowpass envelope
switch win_type
    case 'fir1'
        [signal_in sample_shift_add] = firfilt(signal_in,highpass_out,lowpass_out,fs_in,round(win_params(2)));
        sample_shift = sample_shift + sample_shift_add;
    case 'fft'
        signal_in = bfilt(signal_in,highpass_out,lowpass_out,fs_in,0);
end
