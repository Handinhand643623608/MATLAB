%% 20141008 


%% 1339 - Proof of Volume Correlation Breakdown
% Attempting to prove to myself whether or not an alternative expression for autocorrelation is true. Here, I will be
% testing the autocorrelation of a single-subject BOLD volume over time. Only the time dimension will be considered for
% autocorrelation lags; the volume will not be shifted around in space with respect to itself (as would be true for
% typical image autocorrelation). Thus, the correlation between one volume and another will be evaluated as a single
% coefficient.
%
% In summary, I would like to show that the autocorrelation of a volumetric time series can be expressed as the sum of
% the autocorrelations for each individual voxel of that volume. 
%
% If this relationship is true, then I can easily and quickly calculate autocorrelations for volume series using
% existing functions. Otherwise, I'm going to have to write some functions that will probably end up being very time
% consuming to run.
%
% To test this theory, I will be estimating the autocorrelation of a single BOLD volume time series using the
% brute-force (i.e. highly time consuming) method of manual calculation. All volume pairings will have their constituent
% values multiplied and summed to create unscaled correlation values. These values, which are aligned to one another
% based on time shift, will then be added together.
%
% The brute-force results will be compared against the use of my xcorrArr function applied to the same flattened BOLD
% volume. This function will calculate the autocorrelation values for each voxel as a function of time shift. These
% values will then be added together and then directly compared. 

% Today's parameters
timeStamp = '201410081339';
analysisStamp = 'Manually vs. Automatically Calculated Volume Autocorrelations';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141008/201410081339 - ';

boldFiles = get(Paths, 'InfraslowBOLD');

% Get the flattened BOLD data & remove NaNs
load(boldFiles{1});
[funData, idsNaN] = boldData.ToMatrix();

% Initialize the brute-force output & indexing parameters
manCoeffs = zeros(boldData.NumTimePoints, 2*boldData.NumTimePoints - 1);
idsFirstTime = 1:boldData.NumTimePoints;
idsSecondTime = flipdim(idsFirstTime, 2);

% Manually produce the autocorrelation series (shift-specific data are stored by row)
for a = 1:length(idsSecondTime)
    for b = 1:length(idsFirstTime)
        manCoeffs(a, a + b - 1) = sum(funData(:, idsSecondTime(a)) .* funData(:, idsFirstTime(b)));
    end
end

% Add together the unscaled coefficients
manCorr = sum(manCoeffs, 1);

% Now automatically calculate the autocorrelation series for each voxel of this volume
autoCoeffs = xcorrArr(funData, [], 'Dim', 2, 'ScaleOpt', 'none');

% Add together the auto-calculated unscaled coefficients
autoCorr = sum(autoCoeffs, 1);

% Direct test for equality (but this basically never passes because of precision errors, even for doubles)
equalityTest = isequal(manCorr, autoCorr)

% Visually inspect equality of coefficients
figure; 
subplot(2, 1, 1);
plot(manCorr);
title('Unscaled Manually Calculated Autocorrelation Series');
subplot(2, 1, 2);
plot(autoCorr);
title('Unscaled Automatically Calculated Autocorrelation Series');

saveas(gcf, [dataSaveName analysisStamp '.png'], 'png');
saveas(gcf, [dataSaveName analysisStamp '.fig'], 'fig');

% Results:
% These two autocorrelation series appear identical to one another. This is proof enough to me that the method works.
% Using xcorrArr should save a lot of time calculating the autocorrelations of BOLD volume time series. The resulting
% correlation values can then be easily scaled so that autocorrelations at zero lag are always 1. 



%% 1600 - Generating BOLD & EEG Autocorrelation Series
% These will be used to implement the degrees of freedom corrections needed to properly convert BOLD-EEG correlation
% coefficients to z-scores for significance testing.

% Today's parameters
timeStamp = '201410081600';
analysisStamp = 'BOLD & EEG Autocorrelations';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141008/201410081600-%d ';

channels = {'FPz', 'FT7', 'FCz', 'FT8', 'TP9', 'CPz', 'TP10', 'PO9', 'POz', 'PO10'};

boldFiles = get(Paths, 'InfraslowBOLD');
eegFiles = get(Paths, 'InfraslowEEG');

autoCorrData = struct;

pb = Progress('Calculating BOLD & EEG Autocorrelation Series');
for a = 1:length(boldFiles)
    
    % Load & retrieve the infraslow data
    load(boldFiles{a});
    load(eegFiles{a});    
    funData = boldData.ToMatrix(true);
    ephysData = eegData(channels{:});
    
    % Calculate autocorrelation series (unscaled for BOLD, scaled for EEG)
    [funCorrData, lags] = xcorrArr(funData, [], 'ScaleOpt', 'none');
    ephysCorrData = xcorrArr(ephysData, [], 'ScaleOpt', 'coeff');
    
    % Scale the BOLD autocorrelations to coefficients within [-1 1] (zero-lag should always be maximum)
    funCorrData = sum(funCorrData, 1);
    funCorrData = funCorrData ./ funCorrData(lags == 0);
    
    % Store the data
    autoCorrData.Channels = channels;
    autoCorrData.Ephys = ephysCorrData;
    autoCorrData.Functional = funCorrData;
    autoCorrData.Lags = lags;
    save(sprintf([dataSaveName, analysisStamp], a), 'autoCorrData');
    
    pb.Update(a/length(boldFiles));
end
pb.close;