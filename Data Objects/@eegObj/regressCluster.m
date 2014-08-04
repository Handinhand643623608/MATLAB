function regressCluster(eegData)
%REGRESSCLUSTER Regress cluster signals from EEG data.
%
%   SYNTAX:
%   regressCluster(eegData)
%
%   INPUT:
%   eegData:    An EEG data object.
%
%   Written by Josh Grooms on 20130814
%       20131001:   Bug fix for a mistyped property name. Implemented a better regression method.


%% Regress Cluster Signals
% pbar = progress('Regressing Cluster Signals');
for a = 1:size(eegData, 1)
    for b = 1:size(eegData, 2)
        if ~isempty(eegData(a, b).Data)
            % Get the current EEG data
            currentEEG = eegData(a, b).Data.EEG;
            idsDead = isnan(currentEEG(:, 1));
            currentEEG(idsDead, :) = [];
            
            % Set up hierarchical clustering
            linkParams = linkage(currentEEG, 'average', 'correlation');
            idsCluster = nan(length(idsDead), 1);
            idsCluster(~idsDead) = cluster(linkParams, 'maxclust', 5);
            
            % Regress averaged cluster signals
            d = 1;
            currentClusterSig = zeros(max(idsCluster), size(currentEEG, 2));
            for c = 1:max(idsCluster)
                currentClusterSig(d, :) = mean(currentEEG(idsCluster == c, :), 1);
%                 currentEEG(idsCluster == c, :) = regressSignal(currentEEG(idsCluster == c, :), currentClusterSig(d, :));
                currentEEG(idsCluster == c, :) = (currentEEG(idsCluster == c, :)' - currentClusterSig(d, :)'*(currentClusterSig(d, :)'\currentEEG(idsCluster == c, :)'))';
                d = d + 1;
            end
            
            % Restore data dimensions
            tempEEG = currentEEG;
            currentEEG = nan(length(idsDead), size(currentEEG, 2));
            currentEEG(~idsDead, :) = tempEEG; clear temp*
            
            % Store data in the object
            eegData(a, b).Data.EEG = currentEEG;
            eegData(a, b).Data.Global = currentClusterSig;
            eegData(a, b).GSR = true;
            eegData(a, b).ZScored = false;
        end
    end
%     update(pbar, a/size(eegData, 1));
end
% close(pbar);