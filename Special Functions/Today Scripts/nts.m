function nts
% NTS - Creates and opens a New Today Script to serve as a record of daily activities.
%   This function creates a New Today Script (hence NTS), which is a script intended to serve as a log of daily research
%   activities that take place in MATLAB. To this end, it automatically creates a new MATLAB .m script file inside of
%   the designated log script repository, which is defined by the personalized PATHS dictionary.
%
%   Newly created scripts are always named after the date that NTS is invoked on (in YYYYMMDD format) and are always
%   initialized to contain the very first time-stamped log section. Afterward, if a new section is desired, the related
%   shortcut function NTS should be invoked within the script.
%
%   INSTRUCTIONS:
%       1. Once per day (and only once), type "nts" without quotes into the MATLAB console window and press Enter 
%          keyboard key. A log file will be created with the current date as its file name.
%           1a. Invoking this method when a file named with the current date already exists is an error.
%       2. Use "ntss" to create any subsequent time-stamped log sections as desired.
%
%   SYNTAX:
%       nts
%
%   See also:   NTSS, TODAY, TODAY.CREATESCRIPT, TODAY.CREATESECTION

%% CHANGELOG
%   Written by Josh Grooms on 20141106



%% Create a New Today Script Log
Today.CreateScript();