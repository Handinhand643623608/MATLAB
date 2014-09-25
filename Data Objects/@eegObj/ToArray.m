function [eegArray, legend] = ToArray(eegData, dataStr)
%TOARRAY - Extract data arrays from EEG data objects.
%   This function extracts specific numeric data from EEG data objects and returns it to the user along with an optional
%   legend identifying the signals inside the array. It is intended for use as a shortcut alternative to constantly
%   dot-indexing the numerous fields that the object contains or continuously comparing strings to get single electrode
%   signals. Either the entire EEG data array or any number of specific channels can be outputted. 
%
%   SYNTAX:
%   eegArray = ToArray(eegData)
%   eegArray = ToArray(eegData, dataStr)
%   [eegArray, legend] = ToArray(...)
%
%   OUTPUT:
%   eegArray:       [DOUBLE]
%                   The desired data array pulled from the data object. The size of the array depends completely on the
%                   type of data that is being extracted, but the array itself will always be either one- or
%                   two-dimensional. Individual signals are placed into rows of the array such that time points span the 
%                   columns (i.e. [SIGNALS x TIME]). 
%
%   OPTIONAL OUTPUT:
%   legend:         {STRINGS}
%                   A cell array of strings that identify each signal in the outputted data array. This parameter can be
%                   optionally outputted for any data request. The length of this legend will always equal the number of
%                   rows in the data array and each string element of this cell directly identifies the signal in the
%                   corresponding array row. 
%
%   INPUT:
%   eegData:        EEGOBJ
%                   A single EEG data object.
%
%   OPTIONAL INPUT:
%   dataStr:        STRING or {STRINGS}
%                   A string or cell array of strings representing what data should be extracted from the object. This
%                   parameter is always case insensitive.
%                   DEFAULT: 'EEG'
%                   OPTIONS:
%                           *Any EEG Channel Label (Case Insensitive)*
%                           'BCG'
%                           'EEG'
%                           'Global'

%% CHANGELOG
%   Written by Josh Grooms on 20140711



%% Error Checking
% Fill in missing inputs
if nargin == 1; dataStr = 'EEG'; end
   
% Error check
eegData.AssertSingleObject;

% Convert the data string to a cell, if necessary
if ~iscell(dataStr); dataStr = {dataStr}; end



%% Gather Data from the EEG Data Object
eegArray = [];
legend = {};
for a = 1:length(dataStr)
    switch upper(dataStr{a})
        case eegData.Channels
            eegArray = cat(1, eegArray, eegData.Data.EEG(strcmpi(eegData.Channels, dataStr{a}), :));     
        case {'BCG', 'EEG', 'GLOBAL'}
            eegArray = cat(1, eegArray, eegData.Data.(upper(dataStr{a})));
        otherwise
            error('Extracting %s from EEG data is not supported.', dataStr{a});
    end
    
    if strcmpi(dataStr{a}, 'EEG')
        legend = cat(1, legend, eegData.Channels);
    else
        legend = cat(1, legend, dataStr{a});
    end
end

% Output the requested data
assignOutputs(nargout, eegArray, legend);
            
