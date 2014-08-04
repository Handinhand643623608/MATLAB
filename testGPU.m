%% testGPU - Tests new GPU computing capabilities

% Parameters
timeShifts = -20:2:20;

if ~exist('boldData', 'var')
    load boldObject-1_RS_dcGRZ_20130623
end

% Initialize testing data
testBOLD = boldData(1).Data.Functional;
szBOLD = size(testBOLD);
testBOLD = reshape(testBOLD, [], szBOLD(4));
testBOLD(round(0.5*size(testBOLD, 1)):end, :) = [];

% Compute sample shifts
sampleShifts = timeShifts./boldData(1).TR;

% Load EEG data
load eegObject_RS_dcGRZ_20130625;
testEEG = eegData(1, 1).Data.EEG(strcmp(eegData(1, 1).Channels, 'FPZ'), :);

% Store the data on the GPU
% testBOLDGPU = gpuArray(testBOLD);
% testEEGGPU = gpuArray(testEEG);
% testEEGGPU = repmat(testEEGGPU, size(testBOLDGPU, 1), 1);


%% Regular Cross Correlation

testXCorr = zeros(size(testBOLD, 1), length(sampleShifts));
tic
for a = 1:size(testBOLD, 1)
    testXCorr(a, :) = xcorr(testBOLD(a, :), testEEG, 0, 'coeff');
end
tocCPU = toc;
disp('Finished')


%% GPU Cross Correlation

testXCorrGPU = gpuArray(zeros(size(testBOLD, 1), 1));
tic
testXCorrGPU = dot(testBOLDGPU, testEEGGPU, 2)./size(testEEGGPU, 2);

for a = 1:size(testBOLDGPU, 1)
    
    testXCorrGPU(a, :) = arrayfun(@times, (1/length(testEEG)), sum(arrayfun(@times, testBOLDGPU(a, :), testEEG)));
end
tocGPU = toc;
disp('Finished')

