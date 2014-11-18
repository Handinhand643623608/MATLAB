%% 20141118 


%% 0942 - 
% Temporarily disabled write access protections so that I could easily transfer over some data from older unused data
% objects.

% Log parameters
timeStamp = '201411180942';
analysisStamp = '';

params = boldObj.PrepParameters();

% Get references to infraslow BOLD & EEG data sets
boldPath = [Paths.BOLD '/Preprocessed'];
boldFiles = boldPath.FileContents();

oldDataPath = [Paths.BOLD '/Unfiltered'];
oldDataFiles = oldDataPath.FileSearch('.*_fbZ_20131001.mat');

% Remove subjects 5 & 6
boldFiles(9:13) = [];
oldDataFiles(5:6) = [];

pb = Progress('Finalizing Unfiltered BOLD Preprocessing');
for a = 1:length(oldDataFiles)
    
    oldData = oldDataFiles(a).Load();
    
    % Load the data object corresponding wtih the first scan of the old data
    boldData = boldFiles(2*a - 1).Load();
    boldData.LoadData();
    
    % Transfer information from the old data object
    boldData.Preprocessing = params;
    boldData.Data.Nuisance.Motion = oldData(1).Data.Nuisance.Motion;
    boldData.Data.Mean = oldData(1).Data.Mean;
    boldData.Data.Masks.Mean = (boldData.Data.Mean > params.SegmentThresholds.MeanImageCutoff);
    boldData.Data.Segments = oldData(1).Data.Segments;
    
    % Step through the final stages of preprocessing
    boldData.Blur(params.SpatialBlurring.Size, params.SpatialBlurring.Sigma, params.SpatialBlurring.ApplyToSegments);
    boldData.GenerateSegmentMasks();
    boldData.PrepRegressNuisance();
    boldData.ZScore();
    
    % Save the modified unfiltered BOLD data
    boldData.Store('Path', [Paths.BOLD.ToString() '/Unfiltered']);
    
    % Load the data object corresponding with the second scan of the old data
    boldData = boldFiles(2*a).Load();
    boldData.LoadData();
    
    % Transfer information from the old data object
    boldData.Preprocessing = params;
    boldData.Data.Nuisance.Motion = oldData(2).Data.Nuisance.Motion;
    boldData.Data.Mean = oldData(2).Data.Mean;
    boldData.Data.Masks.Mean = (boldData.Data.Mean > params.SegmentThresholds.MeanImageCutoff);
    boldData.Data.Segments = oldData(2).Data.Segments;
    
    % Step through the final stages of preprocessing
    boldData.Blur(params.SpatialBlurring.Size, params.SpatialBlurring.Sigma, params.SpatialBlurring.ApplyToSegments);
    boldData.GenerateSegmentMasks();
    boldData.PrepRegressNuisance();
    boldData.ZScore();
    
    boldData.Store('Path', [Paths.BOLD.ToString() '/Unfiltered']);
    
    
    pb.Update(a/length(oldDataFiles));
end
pb.close();