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
%       20140902:   Implemented throwing of an error if the user tries to apply anything other than a Hamming window.
%                   Certain other windows may work out alright, but it's not safe to try for now. Made this function
%                   compatible with new data object status properties.
%       20141001:   Removed the option to use arrays of BOLD data objects with this method.

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

% Error checking
boldData.AssertSingleObject;
boldData.LoadData;
if ~strcmpi(Window, 'hamming')
    error('Filter windows other than the Hamming window have not been implemented yet');
end

% Build filter parameters
TR = boldData.TR/1000;
WindowLength = round(WindowLength / TR);
windowParams = window(eval(['@' lower(Window)]), WindowLength+1);
filterParams = fir1(WindowLength, Passband.*2.*TR, windowParams);



%% Filter the Data
% Gather the functional & nuisance signals & transpose to column-major format
[funData, idsNaN] = boldData.ToMatrix;
funData = funData';
[nuisanceData, nuisanceStrs] = boldData.ToArray('Nuisance');
nuisanceData = nuisanceData';

% Filter the signals
if (istrue(UseZeroPhaseFilter))
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
        boldData.Data.Nuisance.(nuisanceStrs{b}) = nuisanceData(b, :);
    end
end
boldData.Data.Nuisance.Motion = motionData;

% Replace the functional data in the data object
newFunData = nan(length(idsNaN), size(funData, 2));
newFunData(~idsNaN, :) = funData;
szBOLD = size(boldData.Data.Functional);
boldData.Data.Functional = reshape(newFunData, [szBOLD(1:3) size(newFunData, 2)]);

% Fill in object properties
Filter@humanObj(boldData, Passband, filterShift, UseZeroPhaseFilter, Window, WindowLength);