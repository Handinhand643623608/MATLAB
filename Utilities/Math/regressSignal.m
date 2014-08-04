function regData = regressSignal(inData, regSignal)
%REGRESSSIGNAL Regress one or more signals from input data
%   This function performs signal regression on input data. This is useful for regressing nuisance
%   signals (known to be artifactual or uninteresting) from data sets. The regression is performed
%   in a vectorized fashion using the following method:
%
%       1. The signal being regressed is mean-centered and scaled to unit Euclidean length.
%       2. The scalar projection of the data onto the unit regression signal is calculated (this is
%          a simple dot product).
%       3. The signal being regressed is scaled up or down by the projection number and subtracted
%          from the input data.
%
%   The signal being regressed can be a single signal or an array of signals (with the time or
%   observation dimension spanning the columns (dimension 2) of the array). All data being inputted
%   must currently be two dimensional.
%
%   SYNTAX:
%   regData = regressSignal(inData, regSignal)
%
%   OUTPUT:
%   regData:        The input data set after being regressed of one or more inputted regression
%                   signals.
%
%   INPUTS:
%   inData:         The input data array. Currently this argument must be two dimensional, with
%                   columns representing time points or observations and rows representing
%                   individual signals.
%
%   regSignal:      The signal(s) being regressed from the input data array. Like the input data, 
%                   this may be a 1-by-N array or an M-by-N array, with M being individual signals
%                   to be regressed and N being the number of time points or observations. This data
%                   and the input data must contain the same number of columns.
%                   WARNING: Pay attention to the ordering of signals being regressed, in case it
%                            matters to your implementation of this function.
%
%   Written by Josh Grooms on 20130728


%% Regress the Signal from the Data
for a = 1:size(regSignal, 1)
    % Normalize the signal being regressed to a vector of unit Euclidean length
    currentSignal = (regSignal(a, :) - mean(regSignal(a, :)))./norm(regSignal(a, :));
    currentSignal = repmat(currentSignal, size(inData, 1), 1);
    
    % Determine the scalar projection of data onto the signal being regressed
    currentProj = dot(inData, currentSignal, 2);
    currentProj = repmat(currentProj, 1, size(currentSignal, 2));
    
    % Perform the regression
    inData = inData - (currentProj.*currentSignal);
end

% Transfer regressed input data to the function output
regData = inData;