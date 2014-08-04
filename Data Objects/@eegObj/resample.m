function resample(eegData, varargin)
%RESAMPLE Resamples EEG temporal data to a new sampling frequency.
%
%   SYNTAX:
%   resample(eegData, 'PropertyName', PropertyValue)
%
%   INPUT:
%   eegData:        An EEG data object.
%
%   OPTIONAL INPUT:
%   'Fs':           The desired output sampling frequency (in Hertz). Either this or "NumPoints"
%                   must be specified.
%
%   'NumPoints':    The desired number of time points in the output signals. This can be used
%                   alternatively to the "Fs" property if trying to match the sampling frequency of
%                   an equivalently long (but lower sampling rate) signal.
%   
%   Written by Josh Grooms on 20130814


%% Initialize
% Initialize default settings & values
inStruct = struct(...
    'Fs', [],...
    'NumPoints', []);
assignInputs(inStruct, varargin);


%% Resample the Data
pbar = progress('Resampling EEG Data', 'Scans Completed');
for a = 1:size(eegData, 1)
    reset(pbar, 2);
    for b = 1:size(eegData, 2)
        if ~isempty(eegData(a, b).Data)
            
            % Convert between number of points & sampling frequency
            currentNumPoints = size(eegData(a, b).Data.EEG, 2);
            if isempty(NumPoints)
                NumPoints = floor(currentNumPoints*Fs/eegData(a, b).Fs);
            end
            if isempty(Fs)
                Fs = NumPoints*eegData(a, b).Fs/currentNumPoints;
            end
            
            % Resample
            tempEEG = zeros(size(eegData(a, b).Data.EEG, 1), NumPoints);
            for c = 1:size(eegData(a, b).Data.EEG, 1)
                tempEEG(c, :) = resample(eegData(a, b).Data.EEG(c, :), NumPoints, currentNumPoints);
            end
            if ~isempty(eegData(a, b).Data.BCG)
                eegData(a, b).Data.BCG = resample(eegData(a, b).Data.BCG, NumPoints, currentNumPoints);
            end
            if ~isempty(eegData(a, b).Data.Global)
                tempGlobal = zeros(size(eegData(a, b).Data.Global, 1), NumPoints);
                for c = 1:size(eegData(a, b).Data.Global, 1)
                    tempGlobal(c, :) = resample(eegData(a, b).Data.Global(c, :), NumPoints, currentNumPoints);
                end
                eegData(a, b).Data.Global = tempGlobal;
            end
            
            % Fill in object properties
            eegData(a, b).Data.EEG = tempEEG;
            eegData(a, b).Fs = Fs;
            
        end
        update(pbar, 2, b/size(eegData, 2));
    end
    update(pbar, a/size(eegData, 1));
end
close(pbar);