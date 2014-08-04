%% 20140528 


%% 0943 - Splitting Up BOLD-EEG SWC Correlation Files
% These were saved with all subjects' data placed into a single file, making them too large to load
% more than one at a time. They need to be divided up.

load masterStructs
savePath = [fileStruct.Paths.Desktop '/SWC Data'];
if ~exist(savePath, 'dir'); mkdir(savePath); end;

% PO8 data was split manually
dataStrs = struct(...
    'FPz', 'slidingWindowPartialCorr_FPZ_(20, 19)_20140421.mat',...
    'C3', 'slidingWindowPartialCorr_C3_(20, 19)_20140527.mat');

parameters = struct(...
    'Channel', [],...
    'Comments', 'All parameters listed here are in units of seconds.',...
    'ControlDelay', 4,...
    'Overlap', 38,...
    'SignalOffset', 4,...
    'WindowLength', 40);

channels = fieldnames(dataStrs);
for a = 1:length(channels)
    load(dataStrs.(channels{a}));
    parameters.Channel = channels{a};
    oldCorr = corrData;
    clear corrData;
    
    for b = 1:size(oldCorr, 5)
        corrData = oldCorr(:, :, :, :, b);
        save([savePath '/swpcData-' num2str(b) '_' channels{a} '_(40, 38)_20140528.mat'], 'corrData', 'parameters', '-v7.3');
    end
    
    clear oldCorr;
end



%% 1112 - Estimating the Correlation between SWPC Series (FPz, C3)
% Estimating the correlation between the volumes of SWPC data generated using different electrodes.
% In other words, correlation between correlations. This is being done to get a sense of how
% different the BOLD-EEG correlation mappings look depending on which electrode was used to generate
% them, which is proving to be very difficult by visual inspection alone. It may also lend some
% insight into how the BOLD signal couples with electrical signals from very different spatial
% locations.
%
% Correlation between the SWPC time series from the FPz and C3 electrodes will be tested first. From
% inspection, these looked very similar to one another across scans, with few noticeable differences
% that might be considered significant.

load masterStructs;
dataPath = [fileStruct.Paths.Desktop '/SWC Data'];
c3Files = get(fileData(dataPath, 'search', 'C3'), 'Path');
fpzFiles = get(fileData(dataPath, 'search', 'FPz'), 'Path');

corrData = [];
for a = 1:length(fpzFiles)
    fpz = load(fpzFiles{a});
    fpz = fpz.corrData;
    c3 = load(c3Files{a});
    c3 = c3.corrData;
    
    fpz = reshape(fpz, [], size(fpz, 4));
    c3 = reshape(c3, [], size(c3, 4));
    
    idsNan = isnan(fpz(:, 1));
    
    fpz(idsNan, :) = [];
    c3(idsNan, :) = [];
    
    corrData = cat(2, corrData, corr2(fpz, c3));
end    

figure;
plot(corrData);
title('Correlelation between SWPC Time Series (FPz, C3)');
ylabel('Correlation Coefficient');
xlabel('Scan Number');

% Results: Correlations between FPz and C3 volumes over time are in general high (except for
% scans 9, 10, & 11, oddly enough), although there is appreciable variability. Qualitatively,
% correlation coefficients range between ~0.275 & ~0.975 with the majority >= 0.7. Scans 9, 10, & 11
% are surprisingly low at ~0.3. This suggests that what I thought I was seeing is to a large extent
% true: the BOLD-EEG coupling for these two electrodes are very similar here. 


%% 1153 - Estimating the Correlation between SWC Series (FPz, PO8)
load masterStructs;
dataPath = [fileStruct.Paths.Desktop '/SWC Data'];
fpzFiles = get(fileData(dataPath, 'search', 'FPz'), 'Path');
po8Files = get(fileData(dataPath, 'search', 'PO8'), 'Path');

corrData = [];
for a = 1:length(fpzFiles)
    fpz = load(fpzFiles{a});
    fpz = fpz.corrData;
    po8 = load(po8Files{a});
    po8 = po8.corrData;
    
    fpz = reshape(fpz, [], size(fpz, 4));
    po8 = reshape(po8, [], size(po8, 4));
    
    idsNan = isnan(fpz(:, 1));
    
    fpz(idsNan, :) = [];
    po8(idsNan, :) = [];
    
    corrData = cat(2, corrData, corr2(fpz, po8));
end    

figure;
plot(corrData);
title('Correlelation between SWPC Time Series (FPz, PO8)');
ylabel('Correlation Coefficient');
xlabel('Scan Number');

saveas(gcf, [fileStruct.Paths.Desktop '/FPz-PO8 SWPC Correlation.png'], 'png');

% Results: Correlations between FPz and PO8 volumes over time are considerably lower than those from
% the section above. Values range between ~0 & ~0.975, with the majority between [0.3, 0.8]. Scans 9
% & 10 (not 11 this time) are again very low at ~0.01 & ~0.075, respectively. This suggests that the
% BOLD-EEG coupling differs appreciably for these two electrodes, which is indeed visible (although
% not always easily) from the raw image data alone.
%
% To me, the unusually low coefficients from scans 9, 10, & 11 calls into question the validity of
% the data sets from those scans (subject 5, and subject 6-1). However, a quick inspection of the
% raw SWPC volume images reveals nothing obviously wrong. The images show the same kinds of salient
% features (i.e. correlations resembling RSNs & RSN-related structures) that are seen in other
% subjects. So, it's unclear why these particular scans differ so much from the general trends here.


%% 1231 - Reflections on SWPC Analyses So Far

% Sliding window partial correlations (SWPC) between BOLD and three EEG channels (all at infraslow
% frequencies) has revealed some very interesting results. Although I haven't yet observed any
% really consistent or obvious patterns in the data, the raw correlation images from every scan show
% that EEG and BOLD signals transiently synchronize across time. Moreover, in a number of scans
% (not necessarily all) these signals become in-phase in important brain regions that resemble RSNs.
% For instance, the default mode and task positive network topologies are readily observable in many
% SWPC time series.
%
% Producing summary statistics or measures that can be used to compare data from different scans has
% thus far not been possible. The nature of this analysis, dynamic correlation that depends on time,
% prevents the use of any of these stationarity-requiring methods. I had originally hoped to find
% repeating spatiotemporal patterns in the SWPC data, which would have allowed for summarization
% across scans to proceed and probably would have helped out SNR problems visible in the raw data
% greatly. 
%
% However, to my eye no such patterns exist. Positive and/or negative correlations with the DMN do
% commonly exist in the data. Ditto for the TPN. In a few, these relationships switch signs at later
% time points just like QPPs do and in-line with what Garth found in his recent paper on the topic
% in rats. It may be that this is an example of the patterns I was looking for. Unfortunately, what
% evidence does exist in my data that favors this phenomenon also suggests that such a pattern
% evolves over a very long time (quite a bit longer than the duration of the scans here). This means
% that I cannot use or even observe them. However, they may not have been useful to begin with
% because the apparent frequency of them appears pretty variable and, in other scans, they don't
% necessarily follow that progression anyway (i.e. DMN anticorrelation can appear and then re-appear
% later in time, without a shift to positive correlation in between).
%
% My latest attempt to work around this problem was to investigate how the volumes of SWPC data for
% different EEG electrodes relate to one another. This is what's shown above in this file, and it
% hasn't been as informative as I'd hoped. Correlations were always positive and typically pretty
% high, indicating that on average the BOLD-EEG coupling across the brain is more similar than it is
% different. This sort of suggests that regional electrophysiology isn't all that important to
% driving the BOLD signal because (assuming causality here) it would all be accomplishing roughly
% the same thing.
%
% It could still be true that regional EEG couples differently to BOLD. It's tough to say right now.
% If that is the case, then maybe the differences between the SWPC series are important but aren't
% very prevalent, meaning that they are being understated by the correlation summary statistic.
% Alternatively, or perhaps concurrently, the difference itself is a phase offset between the SWPC
% series. This means that patterns of coupling are similar across the brain, but occur at slightly
% different times. This could result in the high instantaneous correlation being seen while also
% suggesting that there is an ordering to the coupling that takes place.
%
% Honestly, though, I'm starting to feel a little naive for thinking that such simple patterns could
% be identified here. In a system such as the brain that is, by our ability to measure it, so
% chaotic and unpredictable, there simply may not be any way to compare resting-state data on such
% short time scales in the way that I'm trying to do it.  