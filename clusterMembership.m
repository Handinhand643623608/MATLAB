%% EEG Cluster Membership Incidence Maps
% Written by Josh Grooms on 20130902


%% Initialize
% Custom parameters
maxNumClusters = 5;
distanceMetric = 'correlation';
linkageMethod = 'average';

% Load EEG data
load masterStructs
searchStr = 'RS_dcZ_';
eegFiles = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', searchStr), 'Path');

% Setup other parameters
subjects = paramStruct.general.subjects;
scans = paramStruct.general.scans;

% Initialize the output cluster memberships
idsCluster = zeros(68, 17);

c = 1;
for a = subjects
    load(eegFiles{a});
    for b = scans{a}
        if ~isempty(eegData(b).Data)
            
            currentEEG = eegData(b).Data.EEG;
            idsDead = isnan(currentEEG(:, 1));
            currentEEG(idsDead, :) = [];
            
            linkParams = linkage(currentEEG, linkageMethod, distanceMetric);
            currentClusterIds = cluster(linkParams, 'maxclust', maxNumClusters);
            idsCluster(~idsDead, c) = currentClusterIds; idsCluster(idsDead, c) = NaN;
                c = c + 1;
        end
    end
end

brainData = brainPlot('eeg', idsCluster, 'Colormap', jet(maxNumClusters), 'CLim', [1 maxNumClusters]);


%%