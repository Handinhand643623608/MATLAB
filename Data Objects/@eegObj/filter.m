function Filter(eegData, varargin)
%FILTER - Filters EEG data to the desired passband.
%   This function temporally filters EEG electrode data according to the input parameters. Currently, this function is
%   limited to using FIR1 filters only. Phase shifts imposed by the filter are automatically cropped out of the signals,
%   unless zero-phase filtering is used.
%
%   Default parameters filter down to infraslow (0.01-0.08 Hz) frequencies using a 45 s Hamming window.
%
%   WARNING: This function likely won't accept many filter windows that are available in MATLAB (besides Hamming
%   windows). This will have to be fixed in the future. Changing the filter passband or filter length to any values
%   should be fine, though.
%
%   SYNTAX:
%   Filter(eegData, 'PropertyName', 'PropertyValue',...)
%
%   INPUT:
%   eegData:                EEGOBJ or [EEGOBJ]
%                           An EEG data object.
%
%   OPTIONAL INPUTS:
%   'Passband':             [DOUBLE, DOUBLE]
%                           The passband (in Hertz) that is desired. This is specified as a two-element vector in the 
%                           form [HIGHPASS LOWPASS].
%                           DEFAULT: [0.01 0.08]
%
%   'UseZeroPhaseFilter':   BOOLEAN
%                           A Boolean indicating whether or not to use a zero-phase distorting filter. Using this kind
%                           of filter means that no phase delay is imposed on the functional data set and thus no
%                           samples need to be cropped out.
%                           DEFAULT: true
%
%   'Window':               STRING
%                           The name of the window to be used in filtering of the EEG data. This input is specified as a
%                           string. 
%                           DEFAULT: 'hamming'
%
%   'WindowLength':         INTEGER
%                           The length of the window (in seconds) for the FIR filter.
%                           DEFAULT: 45

%% CHANGELOG
%   Written by Josh Grooms on 20130814
%       20140714:   Rewrote this function so that it mirrors the BOLD data object FILTER method. Implemented zero-phase
%                   FIR filtering of time series. Implemented a workaround for compatibility with the new MATFILE data
%                   storage system. Updated documentation accordingly.
%       20140829:   Cleaned up some of the code here.



%% Initialize
% Initialize default values & settings
inStruct = struct(...
    'Passband', [0.01 0.08],...
    'UseZeroPhaseFilter', true,...
    'Window', 'hamming',...
    'WindowLength', 45);
assignInputs(inStruct, varargin);

% Build filter parameters
WindowLength = round(WindowLength.*eegData(1).Fs);
windowParams = window(eval(['@' lower(Window)]), WindowLength+1);
filterParams = fir1(WindowLength, Passband.*2./eegData(1, 1).Fs, windowParams);



%% Filter the Data
pbar = progress('Scans Filtered');
for a = 1:numel(eegData)
    
    % Workaround for MATFILE data storage
    eegData(a).LoadData;
    
    % Gather the EEG data & transpose to column-major format
    ephysData = eegData(a).ToArray;
    ephysData = ephysData';
    
    % Filter the signals
    if istrue(UseZeroPhaseFilter)
        ephysData = filtfilt(filterParams, 1, ephysData);
        ephysData = ephysData';
        filterShift = 0;
    else
        ephysData = filter(filterParams, 1, ephysData);
        ephysData = ephysData';
        ephysData(:, 1:WindowLength) = [];
        filterShift = floor(WindowLength/(2*eegData(a).Fs));
    end
    
    % Replace the EEG data in the data object
    eegData(a).Data.EEG = ephysData;
    
    % Fill in object properties
    eegData(a).Bandwidth = Passband;
    eegData(a).IsFiltered = true;
    eegData(a).FilterShift = filterShift;
    eegData(a).IsZScored = false;
    
    update(pbar, a/numel(eegData));
end
close(pbar);