%% 20141118 



%% 1212 - Removing MATFILE Storage System for Objects on my Flash Drive
% This system was an unexpectedly bad idea from the start. Today, it's gotten in my way for the last time. I'm
% recombining BOLD objects with their MATFILE data sets and am just going to have to suffer through the loading times
% from here forward. 

% Log parameters
timeStamp = '201411181212';
analysisStamp = '';

% Get references to infraslow BOLD & EEG data sets (20140630 version)
boldFiles = Files.BOLD;
matFiles = Paths.BOLD.FileSearch('boldData.*.mat');

pb = Progress('Removing MATFILE Associations from Infraslow BOLD');
for a = 1:length(boldFiles)
	
	boldFiles(a).Load();
	data = matFiles(a).Load();
	
	boldData.Data = data;
	
	boldData.Store('Path', Paths.BOLD.ToString());

	pb.Update(a/length(boldFiles));
end
pb.close();



%% 1307 - Shoehorning Old BOLD Data Objects into the Newest Class Format
% The BOLD data objects I've been using have never been updated to newer class formats and revisions that have occurred
% over the past year. I'm a little tired of seeing a slew of warnings show up in the console every time one of these
% data objects is loaded into the workspace. Although these warnings were always inconsequential, I'm finally doing
% something about them now.

% Log parameters
timeStamp = '201411181307';

% Get references to infraslow BOLD data sets
boldFiles = Files.BOLD;

params = boldObj.PrepParameters();
params.SegmentThresholds.CSFCutoff = 0.2;
params.SegmentThresholds.GrayMatterCutoff = 0.1;
params.SegmentThresholds.WhiteMatterCutoff = 0.15;
params.SignalCropping.NumTimePointsToRemove = 0;
params.StageSelection.UseNuisanceRegression = false;
params.TemporalFiltering.UseZeroPhaseFilter = false;

params.DataPaths = struct(...
	'MNIBrainTemplate',         '/shella-lab/Josh/Globals/MNI/template/T1.nii',...
    'MNIFolder',                '/shella-lab/Josh/Globals/MNI',...
    'OutputPath',               '/shella-lab/Josh/Data/Raw',...
    'RawDataPath',              '/shella-lab/Josh/Data/Raw',...
    'SegmentsFolder',           '/shella-lab/Josh/Globals/MNI/segments');

pb = Progress('Updating BOLD Object Preprocessing Parameters');
for a = 1:length(boldFiles)
	boldData = boldFiles(a).Load();
	
	boldData.IsGlobalRegressed = false;
	boldData.IsZScored = true;
	boldData.Preprocessing = params;
	boldData.SoftwareVersion = 2;
	
	boldData.Postprocessing.Filtering = struct(...
		'IsFiltered', true,...
		'Passband', [0.01, 0.08],...
		'PhaseDelay', 45,...
		'WindowName', 'hamming',...
		'WindowLength', 45,...
		'ZeroPhaseFiltered', false);
	boldData.Postprocessing.Detrending = struct(...
		'DetrendOrder', 2,...
		'IsDetrended', true);
	boldData.Postprocessing.Blurring = struct(...
		'IsBlurred', true,...
		'Size', 3,...
		'Sigma', 2);
	
	boldData.Store('Path', Paths.Desktop.ToString());
	
	pb.Update(a/length(boldFiles));
end
pb.close();



%% 1533 - Generating Unfiltered BOLD Data in the Newest Class Format
% Log parameters
timeStamp = '201411181533';
analysisStamp = '';

ufFiles = FileContents([Paths.BOLD '/Unfiltered']);
prepFiles = FileContents([Paths.BOLD '/Preprocessed']);

ufFiles(5:6) = [];
prepFiles(9:13) = [];

params = boldObj.PrepParameters();
params.SegmentThresholds.CSFCutoff = 0.2;
params.SegmentThresholds.GrayMatterCutoff = 0.1;
params.SegmentThresholds.WhiteMatterCutoff = 0.15;
params.SignalCropping.NumTimePointsToRemove = 0;
params.StageSelection.UseNuisanceRegression = false;
params.StageSelection.UseTemporalFiltering = false;
params.TemporalFiltering.UseZeroPhaseFilter = true;


params.DataPaths = struct(...
	'MNIBrainTemplate',         '/shella-lab/Josh/Globals/MNI/template/T1.nii',...
    'MNIFolder',                '/shella-lab/Josh/Globals/MNI',...
    'OutputPath',               '/shella-lab/Josh/Data/Raw',...
    'RawDataPath',              '/shella-lab/Josh/Data/Raw',...
    'SegmentsFolder',           '/shella-lab/Josh/Globals/MNI/segments');

pb = Progress('Finalizing Preprocessed BOLD Data');
for a = 1:length(ufFiles)
	
	ufData = ufFiles(a).Load();
	prepData = prepFiles(2*a - 1).Load();
	
	prepData.IsGlobalRegressed = false;
	prepData.IsZScored = true;
	prepData.Preprocessing = params;
	prepData.SoftwareVersion = 2;
	
	% Transfer information from the old data object
    prepData.Preprocessing = params;
    prepData.Data.Nuisance.Motion = ufData(1).Data.Nuisance.Motion;
    prepData.Data.Mean = ufData(1).Data.Mean;
    prepData.Data.Masks.Mean = (prepData.Data.Mean > params.SegmentThresholds.MeanImageCutoff);
    prepData.Data.Segments = ufData(1).Data.Segments;
	
	% Step through the final stages of preprocessing
    prepData.Blur(params.SpatialBlurring.Size, params.SpatialBlurring.Sigma, params.SpatialBlurring.ApplyToSegments);
    prepData.GenerateSegmentMasks();
	
	prepData.Mask(prepData.Data.Masks.Mean, NaN);
	
    prepData.PrepRegressNuisance();
    prepData.ZScore();
	
	prepData.Store('Path', [Paths.BOLD.ToString() '/Unfiltered']);
	
	
	
	prepData = prepFiles(2*a).Load();
	
	prepData.IsGlobalRegressed = false;
	prepData.IsZScored = true;
	prepData.Preprocessing = params;
	prepData.SoftwareVersion = 2;
	
	% Transfer information from the old data object
    prepData.Preprocessing = params;
    prepData.Data.Nuisance.Motion = ufData(2).Data.Nuisance.Motion;
    prepData.Data.Mean = ufData(2).Data.Mean;
    prepData.Data.Masks.Mean = (prepData.Data.Mean > params.SegmentThresholds.MeanImageCutoff);
    prepData.Data.Segments = ufData(2).Data.Segments;
	
	% Step through the final stages of preprocessing
    prepData.Blur(params.SpatialBlurring.Size, params.SpatialBlurring.Sigma, params.SpatialBlurring.ApplyToSegments);
    prepData.GenerateSegmentMasks();
	
	prepData.Mask(prepData.Data.Masks.Mean, NaN);
	
    prepData.PrepRegressNuisance();
    prepData.ZScore();
	
	prepData.Store('Path', [Paths.BOLD.ToString() '/Unfiltered']);
	
	pb.Update(a/length(ufFiles));
end
pb.close();


