function outputData = u_notchFilter(inputData, samplingFreq, centerFreq, notchWidth, displaySwitch)

%% Initialize
% Condition the input data
if size(inputData, 2) > size(inputData, 1)
    inputData = inputData';
end

% Set the Nyquist frequency
fn = samplingFreq/2;

% Set the ratio between filter center frequency & Nyquist frequency
freqRatio = centerFreq/fn;

% Initialize the output data array
outputData = zeros(size(inputData));

%% Filter the Data
% Determine the poles & zeros of the notch filter
filterZeros = [exp(sqrt(-1)*pi*freqRatio), exp(-sqrt(-1)*pi*freqRatio)];
filterPoles = (1-notchWidth)*filterZeros;

% Determine the parameters of the filter's transfer function
b = poly(filterZeros);
a = poly(filterPoles);

if displaySwitch == 1
    figure; freqz(b, a, 10000, samplingFreq)
end

% Perform the filtering
for i = 1:size(inputData, 2)
    outputData(:, i) = filtfilt(b, a, inputData(:, i));
end