function appendBP(systolic, diastolic, heartRate, arm, varargin)
%APPENDBP Append blood pressure data to the data object.
%   This function appends recent blood pressure and heart rate measurements to an existing BLOODPRESSURE data object. It
%   also automatically fills in the time at which the measurement is entered.
%
%   SYNTAX:
%   appendBP(systolic, diastolic, heartRate, arm)
%   appendBP(systolic, diastolic, heartRate, arm, 'PropertyName', PropertyValue,...)
%
%   INPUTS:
%   systolic:   NUMERIC
%               The numeric systolic blood pressure entered in units of mmHg.
%   
%   diastolic:  NUMERIC
%               The numeric diastolic blood pressure entered in units of mmHg.
%
%   heartRate:  NUMERIC
%               The numeric heart rate measurement entered in units of BPM.
%
%   arm:        STRING
%               A string indicating on which arm (left of right) the measurement was taken.
%
%   OPTIONAL INPUT:
%   'Comment':  STRING
%               A user annotation on the current reading being entered.
%               DEFAULT: empty
%
%   'Date':     STRING
%               The date and time of the measurement that was taken expressed in 'yyyymmddTHHMMSS' format only:
%               DEFAULT: now
%               
%   'User':     STRING
%               A string representing the user for which the measurements are taken.
%               DEFAULT: 'Josh'
%               OPTIONS:
%                   'Josh'
%                   'Cake' OR 'Vanessa' or 'Vaneezy'
%
%   Written by Josh Grooms on 20131004
%       20131005:   Added a help & reference section.
%       20131101:   Added new input 'Date' for adding readings that happened in the past. Also implemented an input
%                   variable structure for inputs that I don't frequently use. Rewrote the append data section for
%                   better efficiency.
%       20131105:   Implemented a comment property for the object to add annotations on readings. Moved input variable
%                   formatting to ASSIGNINPUTS.


%% Append Data
% Deal with missing input arguments
if nargin < 4
    error('All inputs are required to append data to the blood pressure data object.');
end
inStruct = struct(...
    'Comment', {{[]}},...
    'DateNum', now,...
    'User', 'Josh');
assignInputs(inStruct, varargin,...
    'compatibility', {'DateNum', 'date'},...
    {'DateNum'}, 'if ischar(varPlaceholder); varPlaceholder = datenum(varPlaceholder, ''yyyymmddTHHMMSS''); end',...
    {'Comment'}, 'if ~iscell(varPlaceholder); varPlaceholder = {varPlaceholder}; end');

% Determine where data is currently being stored
load masterStructs
savePathStr = which('bpObject.mat');
load(savePathStr);

% Determine for which user data is being inputted
switch User
    case 'Josh'
        idxUser = 1;
    case {'Cake', 'Vanessa', 'Vaneezy'}
        idxUser = 2;
end

% Append data to the object
bpData(idxUser).Arm = [bpData(idxUser).Arm arm];
bpData(idxUser).Comment = [bpData(idxUser).Comment; Comment];
bpData(idxUser).Date = [bpData(idxUser).Date DateNum];
bpData(idxUser).Diastolic = [bpData(idxUser).Diastolic diastolic];
bpData(idxUser).HeartRate = [bpData(idxUser).HeartRate heartRate];
bpData(idxUser).Systolic = [bpData(idxUser).Systolic systolic];
        
% Save the updated data object
save(savePathStr, 'bpData');