function Filter(boldData, varargin)
%FILTER - Filters BOLD data to the desired passband.
%   This function temporally filters BOLD voxel data according to the input parameters. Currently, this process is
%   limited to using FIR1 filters only. Phase shifts imposed by the filter are automatically cropped out of the signals,
%   unless zero-phase filtering is used.
%
%   Default parameters filter down to infraslow (0.01-0.08 Hz) frequencies using a 45s Hamming window.
%
%   WARNING: This function likely won't accept many filter windows that are available in MATLAB (besides Hamming
%   windows). This will have to be fixed in the future. Changing the filter passband or filter length to any values
%   should be fine, though.
%
%
%   SYNTAX:
%   Filter(boldData)
%   Filter(boldData, 'PropertyName', PropertyValue,...)
%
%   INPUT:
%   boldData:               BOLDOBJ 
%                           A BOLD data object.
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
%                           The name of the window to be used in filtering of the BOLD data. This input is specified as
%                           a string.
%                           DEFAULT: 'hamming'
%
%   'WindowLength':         INTEGER
%                           The length of the window (in seconds) for the FIR filter.
%                           DEFAULT: 45

%% CHANGELOG
%   Written by Josh Grooms on 20130818
%       20140612:   Updated the documentation for this method.
%       20140707:   Implemented zero-phase FIR filtering. Updated this method for compatibility with the new MATFILE
%                   storage system. Updated documentation accordingly.

%% TODOS
% Immediate Todos
% - Implement the ability to use windows other than hamming windows.



%% Initialize
% Initialize default values & settings
inStruct = struct(...
    'Passband', [0.01 0.08],...
    'UseZeroPhaseFilter', true,...
    'Window', 'hamming',...
    'WindowLength', 45);
assignInputs(inStruct, varargin);

% Build filter parameters
TR = boldData(1).TR/1000;
WindowLength = round(WindowLength/TR);
windowParams = window(eval(['@' lower(Window)]), WindowLength+1);
filterParams = fir1(WindowLength, Passband.*2.*TR, windowParams);



%% Filter the Data
pbar = progress('Scans Filtered');
for a = 1:numel(boldData)
    
    % Load the full object data set, because modifications to core data are occurring
    if strcmpi(class(boldData(a).Data), 'matlab.io.matfile')
        boldData(a).Data = load(boldData(a).Data.Properties.Source);
    end
    
    % Gather the functional & nuisance signals & transpose to column-major format
    [funData, idsNaN] = ToMatrix(boldData(a));
    funData = funData';
    [nuisanceData, nuisanceStrs] = ToArray(boldData(a), 'Nuisance');
    nuisanceData = nuisanceData';
    
    % Filter the signals
    if istrue(UseZeroPhaseFilter)
        funData = filtfilt(filterParams, 1, funData);
        funData = funData';
        nuisanceData = filtfilt(filterParams, 1, nuisanceData);
        nuisanceData = nuisanceData';
        filterShift = 0;
    else
        funData = filter(filterParams, 1, funData);
        funData = funData';
        funData(:, 1:WindowLength) = [];
        nuisanceData = filter(filterParams, 1, nuisanceData);
        nuisanceData = nuisanceData';
        nuisanceData(:, 1:WindowLength) = [];
        filterShift = floor(WindowLength/(2*1/TR));
    end
    
    % Replace the nuisance data in the data object
    motionData = [];
    for b = 1:length(nuisanceStrs)
        if strcmpi(nuisanceStrs{b}, 'Motion')
            motionData = cat(1, motionData, nuisanceData(b, :));
        else
            boldData(a).Data.Nuisance.(nuisanceStrs{b}) = nuisanceData(b, :);
        end
    end
    boldData(a).Data.Nuisance.Motion = motionData;
    
    % Replace the functional data in the data object
    newFunData = nan(length(idsNaN), size(funData, 2));
    newFunData(~idsNaN, :) = funData;
    szBOLD = size(boldData(a).Data.Functional);
    boldData(a).Data.Functional = reshape(newFunData, [szBOLD(1:3) size(newFunData, 2)]);

    % Fill in object properties
    boldData(a).Bandwidth = Passband;
    boldData(a).Filtered = true;
    boldData(a).FilterShift = filterShift;
    boldData(a).ZScored = false;
    
    update(pbar, a/numel(boldData));
end
close(pbar);