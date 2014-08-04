function ar_globalRegression(fileStruct, paramStruct)

%% Initialize
% Assign input structures to variables
assignInputs(paramStruct.globalRegression.EEG, 'createOnly')
assignInputs(fileStruct.analysis.globalRegression.EEG, 'createOnly')

% Load the EEG data
oldData = load(eegDataFile);

% Initialize function-specific parameters
maxScans = paramStruct.general.maxScans;
maxSubs = subjects(end);

% Allocate the output data structure
eegData(maxSubs, maxScans) = struct('data', [], 'info', []);

%% Perform the Clustering & Signal Regression
progressbar('EEG Cluster Signal Regression', 'Scans Completed')
for i = subjects
    progressbar([], 0);
    for j = scans{i}
        % Get the current EEG data
        currentEEG = oldData.eegData(i, j).data.EEG;
        
        % Allocate storage array for mean standard errors
        meanStdErr = zeros(1, maxClusters);
        
        for k = 1:maxClusters
            
            % Cluster the EEG data
            switch clusterMethod
                case 'kmeans'
                    % k-Means clustering
                    currentClusters = kmeans(currentEEG, k);
                case 'hierarchical'
                    % Hierarchical clustering
                    currentClusters = clusterdata(currentEEG, 'maxclust', maxClusters, 'distance', 'correlation');
            end

            % Allocate for the standard error
            currentStdErr = zeros(k, 1);

            % Calculate the standard error (error at each time point across all channels, then mean across all time points)
            for L = 1:k
                currentStd = std(currentEEG(currentClusters == L, :), [], 1);
                currentStdErr(L) = mean(currentStd ./ sqrt(size(currentEEG(currentClusters == L), 1)));
            end

            meanStdErr(k) = mean(currentStdErr);
        end
        
        % Find the best result
        [NU currentNumClusters] = min(log(meanStdErr) + (1:maxClusters));
        
        % Cluster using that size
        switch clusterMethod
            case 'kmeans'
                currentClusters = kmeans(currentEEG, currentNumClusters);
            case 'hierarchical'
                currentClusters = clusterdata(currentEEG, 'maxclust', currentNumClusters, 'distance', 'correlation');
        end
        
        % Allocate for the global signals being regressed
        globalSigs = zeros(currentNumClusters, size(currentEEG, 2));
        
        for k = 1:currentNumClusters
            % Get the current cluster of EEG data & mean signal
            currentCluster = currentEEG(currentClusters == k, :);
            currentGlobal = mean(currentCluster, 1);
            
            % Regress the cluster signal
            currentCluster = u_regress_signal(currentCluster, currentGlobal);
            
            % Store the output data
            currentEEG(currentClusters == k, :) = currentCluster;
            globalSigs(k, :) = currentGlobal;
        end
        
        % Store the data in the output structure
        eegData(i, j).data = struct(...
            'EEG', [currentEEG],...
            'BCG', [oldData.eegData(i, j).data.BCG],...
            'globalSignal', [globalSigs]);
        
        % Fill in the information section of output structure
        eegData(i, j).info = struct(...
            'dataFormat', 'EEG: (Channels x Time Points) ClusterSigs: (Cluster Number x Time Points)',...
            'subject', i,...
            'scan', j,...
            'channels', {oldData.eegData(i, j).info.channels},...
            'Fs', oldData.eegData(i, j).info.Fs,...
            'filterShift', oldData.eegData(i, j).info.filter_shift,...
            'numClusters', currentNumClusters,...
            'comments', comments);
            
        progressbar([], j/length(scans{i}));
    end
    
    progressbar(i/length(subjects), []);
    
    % Garbage collect
    clear current* NU 
end

% Garbage collect
clear temp* oldData

saveStr = [savePathData '\eegData_' saveTag '_' saveID '.mat'];
save(saveStr, 'eegData', '-v7.3')