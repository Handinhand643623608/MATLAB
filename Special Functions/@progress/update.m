function update(progData, varargin)
%UPDATE Update the progress bar completion percentage.
%   This function updates the progress bar completion percentage and expands the progress bar image to a size
%   proprotional to that completion. This function also calculates and implements the acceleration/deceleration effects
%   that the bar displays.
% 
%   Written by Josh Grooms on 20130215
%       20130322:   Updated to fix callback generating variable size warnings
%       20130329:   Updated to react to bar title changes. Also changed how events and direct calls are handled.
%       20130625:   Implemented multiple progress bars in a single window. Permament fix to bug causing variable size 
%                   warnings. Increased bar movement speed slightly.
%       20130804:   Implemented estimated time remaining for overall progress.
%       20130809:   Bug fix for time remaining estimation while multiple bars exist in a window.
%       20131030:   Updated to prevent warnings from being thrown when adjustments to the time remaining estimate are 
%                   very small.
%       20131210:   Implemented the "Fast" property, which turns off smooth animations & instantly jumps the progress
%                   bar to its final position.

% TODO: Fix parallel processing logs


%% Initialize
% Deal with non name/value input arguments
if nargin == 2
    tempComplete = progData.Complete;
    tempComplete(1) = varargin{1};
    varargin = {'complete', tempComplete};
elseif nargin == 3
    tempComplete = progData.Complete;
    tempComplete(varargin{1}) = varargin{2};
    varargin = {'complete', tempComplete};
end

% Initialize a defaults & settings structure
inStruct = struct(...
    'barNum', [],...
    'sourceData', [],...
    'eventData', [],...
    'complete', progData.Complete);
assignInputs(inStruct, varargin,...
    'compatibility', {'barNum', 'bar', [];...
                      'sourceData', 'source', 'src';...
                      'eventData', 'event', 'evt';...
                      'complete', 'progress', 'complete'});

% Workaround for parallel processing
if istrue(progData.Parallel)
    if ~exist('tempProg.txt', 'file');
        progID = fopen('tempProg.txt', 'w+');
        printStr = repmat('%d\n', 1, length(complete));
        fprintf(progID, printStr, complete);
        fclose(progID);
    else
        otherComplete = importdata('tempProg.txt')';
        if any(complete > otherComplete)
            progID = fopen('tempProg.txt', 'w+');
            printStr = repmat('%d\n', 1, length(complete));
            fprintf(progID, printStr, complete);
            fclose(progID);
        elseif any(complete < otherComplete)         
            complete = otherComplete;
        end
    end
end
            

%% Store Values in the Object
if isempty(sourceData)
    % If the function is called directly, only change property value so that the callback will move the bar
    progData.Complete = sigFig(complete, 'format', '0.000');
elseif ~isempty(sourceData)
    for a = 1:length(progData.(sourceData.Name));
        switch sourceData.Name
            case 'BarTitle'
                if iscell(progData.BarTitle)
                    set(progData.Text.BarTitle(a), 'String', progData.BarTitle{a});
                else
                    set(progData.Text.BarTitle, 'String', progData.BarTitle);
                end
                drawnow

            case 'Complete'
                % Get the current position of the progress bar & text
                barPatch = progData.Data(a);
                barTxt = progData.Text.BarText(a);
                currentBarData = get(barPatch, 'XData');
                currentPosition = max(currentBarData);
                currentTxtPosition = get(barTxt, 'Position');
                currentTxtNum = get(barTxt, 'String');
                currentTxtNum = str2num(strrep(currentTxtNum, '%', ''));

                % Determine how far the bar needs to expand
                newPosition = round(complete(a)*100) + 4;         % The "4" accounts for the size of the rounded bar edges
                diffPosition = sigFig(newPosition - currentPosition, 'format', '0.00');
                
                % Time the intervals between updates & keep a running average
                if diffPosition ~= 0 && a == 1
                    currentTime = now;
                    currentIterTime = currentTime - progData.Clock.PreviousTime;
                    numIterations = progData.Clock.NumIterations + 1;
                    averageTimePerIter = (currentIterTime + (numIterations-1)*progData.Clock.Average)/numIterations;

                    % Estimate how much time remains
                    itersRemaining = round(numIterations/progData.Complete(1)) - numIterations;
                    set(progData, 'Name', translateTime(averageTimePerIter*itersRemaining))
                    
                    % Store data
                    progData.Clock.NumIterations = numIterations;
                    progData.Clock.PreviousTime = currentTime;
                    progData.Clock.Average = averageTimePerIter;
                end


                %% Advance the Progress Bar
                if diffPosition ~= 0
                    idxSecondCap = 0.5*length(currentBarData) + 1;
                    if istrue(progData.Fast)
                        % Instantly move the bar, using no animation effects
                        currentBarData(idxSecondCap:end) = currentBarData(idxSecondCap:end) + diffPosition;
                        currentTxtPosition(1) = currentTxtPosition(1) + diffPosition;
                        currentTxtNum = currentTxtNum + diffPosition;
                        set(barPatch, 'XData', currentBarData);
                        set(barTxt, 'Position', currentTxtPosition, 'String', [num2str(sigFig(currentTxtNum, 'roundFormat', '0.0')) '%']);
                        drawnow
                    else
                        % Smoothly move the bar, using acceleration/deceleration
                        movements = 1:(diffPosition/74):diffPosition;
                        movementSpeed = gausswin(length(movements), 1/0.4);
                        movementSpeed = movementSpeed.*(diffPosition/sum(movementSpeed));
                        for i = 1:length(movements)
                            currentBarData(idxSecondCap:end) = currentBarData(idxSecondCap:end) + movementSpeed(i);
                            currentTxtPosition(1) = currentTxtPosition(1) + movementSpeed(i);
                            currentTxtNum = currentTxtNum + movementSpeed(i);
                            set(barPatch, 'XData', currentBarData);
                            set(barTxt, 'Position', currentTxtPosition, 'String', [num2str(sigFig(currentTxtNum, 'roundFormat', '0.0')) '%']);
                            pause(0.0001);
                        end
                    end
                end

                % Force percentage number in progress bar to be the same as the input ratio
                set(barTxt, 'String', [num2str(sigFig(100*complete(a), 'roundFormat', '0.0')) '%']);
        end
    end
end


end%================================================================================================
%% Nested Functions
% Translate time serial numbers to nice strings
function timeStr = translateTime(timeRemaining)
    warning('off', 'MATLAB:callback:error');
    unitStrs = {[], 'days', [], 'hrs', [], 'min', [], 's'};    
    timeRemaining = datestr(timeRemaining, 'DDHHMMSS');
    idxZeros = regexpi(timeRemaining, '(^0+)', 'end');
    
    if ~isempty(idxZeros)
        if mod(idxZeros, 2) ~= 0; idxZeros = idxZeros-1; end
        if length(idxZeros) == length(timeRemaining); idxZeros = length(timeRemaining)-2; end;
        timeRemaining(1:idxZeros) = [];
        unitStrs(1:idxZeros) = [];
    end
    
    timeStr = 'Remaining';
    for a = length(timeRemaining):-2:1
        if strcmpi(timeStr, '00')
            timeStr = 'Done!';
        else
            timeStr = sprintf('%s %s %s', timeRemaining(a-1:a), unitStrs{a}, timeStr);
        end
    end
end