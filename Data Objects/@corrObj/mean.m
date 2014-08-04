function meanCorrData = mean(corrData)
%MEAN Averages together the (null) correlation data.
%   This function generates averaged correlation data across all subjects and scans. If a null correlation distribution
%   is provided, it automatically calculates the appropriate grouping size of the data to be averaged and performs the
%   averaging. This ensures that the null data are not averaged from pools larger than the real correlation data.
%
%   SYNTAX:
%   meanCorrData = mean(corrData)
%
%   OUTPUT:
%   meanCorrData:   The correlation data object containing averaged correlations across subjects and scans.
%
%   INPUT:
%   corrData:       A correlation data object. This object can contain either real correlations or a null set of 
%                   correlation values.
%
%   Written by Josh Grooms on 20130702
%       20130709:   Re-wrote initialization section. Trying to copy over an element of corrData doesn't work.
%       20130711:   Re-wrote the averaging of null data sets in order to prevent memory errors.
%       20130811:   Updated for compatibility with changes to PROGRESS.
%       20130906:   Updated to work with improved correlation & initialization code for this object.
%       20131028:   Bug fix for averaging null data sets


%% Initialize
% Get data from the object
assignInputs(corrData(1, 1).Parameters.Correlation, 'varsOnly');

% Initialize the mean correlation data output object
meanCorrData = corrObj;

% Fill in object properties (this needs to be done first)
exemptStrs = {'averaged', 'data', 'parentdata', 'storagedate', 'storagepath', 'subject', 'scan'};
propNames = fieldnames(corrData(1, 1)); 
propNames(ismember(lower(propNames), lower(exemptStrs))) = [];
for a = 1:length(propNames)
    meanCorrData.(propNames{a}) = corrData(1, 1).(propNames{a});
end
meanCorrData.Averaged = true;
meanCorrData.Subject = meanCorrData.Parameters.Correlation.Subjects;
meanCorrData.Scan = meanCorrData.Parameters.Correlation.Scans;


%% Average the Data
if GenerateNull
    
    % Randomize the null data prior to averaging
    randOrder = randperm(length(corrData));
    corrData = corrData(randOrder);
    
    % Concatenate the null data & average (try the fast method first)
    try
        progBar = progress('Data Sets Completed', 'Null Components Averaged');
        for a = 1:length(DataStrs)
            % Calculate data sizes & indexing parameters
            totalScans = length(cat(2, Scans{:}));
            szCatCorr = [size(corrData(1).Data.(DataStrs{a})), totalScans];
            catCorrData = zeros(szCatCorr);
            catDataDim = length(szCatCorr);
            idxCat = repmat({':'}, 1, catDataDim);
            
            % Concatenate the correlation data
            d = 1;
            reset(progBar, 2)
            for b = 1:totalScans:length(corrData)
                for c = 1:totalScans
                    idxCat{catDataDim} = c;
                    if (b+c-1) <= length(corrData)
                        catCorrData(idxCat{:}) = corrData(b+c-1).Data.(DataStrs{a});
                    else
                        idxCat{catDataDim} = size(catCorrData, catDataDim);
                        catCorrData(idxCat{:}) = [];
                    end
                end
                idxCat{catDataDim} = d; d = d + 1;
                meanCorrData.Data.(DataStrs{a})(idxCat{:}) = nanmean(catCorrData, catDataDim);
                catCorrData = zeros(szCatCorr);
                update(progBar, 2, b/length(corrData));
            end
            
            update(progBar, 1, a/length(DataStrs));
        end
    catch
        warning('Fast method of averaging has failed. Prepare to wait');
        reset(progBar)
        for a = 1:length(DataStrs)   
            % Calculate some sizes & dimensionalities
            totalScans = length(cat(2, Scans{:}));
            szCorrData = size(corrData(1).Data.(DataStrs{a}));
            permOrder = 1:(length(szCorrData)+1);
            permOrder(1) = permOrder(end); permOrder(end) = 1;
            
            % Pre-allocate the concatenated correlation array
            szCatCorr = [szCorrData, totalScans]; szCatCorr = szCatCorr(permOrder);
            currentCatCorr = zeros(szCatCorr);            
            
            % Pre-allocate the averaged correlation array
            szMeanCorr = [szCorrData, floor(length(corrData)/totalScans)];
            szMeanCorr = szMeanCorr(permOrder);
            currentMeanCorr = zeros(szMeanCorr);
            
            c = 1;
            d = 1;
            reset(progBar, 2)
            for b = 1:length(corrData)
                % Concatenate the correlation data
                currentCatCorr(c, :) = corrData(b).Data.(DataStrs{a});
                
                % Create groupings of null data the same size as real data
                if c == totalScans
                    currentMeanCorr(d, :) = nanmean(currentCatCorr, 1);
                    currentCatCorr = zeros(szCatCorr);
                        c = 1;
                        d = d + 1;
                else
                    c = c + 1;
                end
                update(progBar, 2, b/length(corrData));
            end
            
            % Store the averaged data in the object
            meanCorrData.Data.(DataStrs{a}) = permute(currentMeanCorr, permOrder);
            update(progBar, 1, a/length(DataStrs));
        end
    end
    
else
    
    for a = 1:length(DataStrs)
        % Initialize the concatenated data storage arrays & determine averaging dimension
        catCorrData = [];
        parentDataFiles = {};
        catDataDim = ndims(corrData(1, 1).Data.(DataStrs{a})) + 1;
    
        % Concatenate the data & store
        for b = Subjects
            for c = Scans{b}
                catCorrData = cat(catDataDim, catCorrData, corrData(b, c).Data.(DataStrs{a}));
                
            end
            parentDataFiles = cat(1, parentDataFiles, corrData(b, 1).ParentData);
        end
        meanCorrData.Data.(DataStrs{a}) = nanmean(catCorrData, catDataDim);
        meanCorrData.ParentData = parentDataFiles;
    end
    
end

if exist('progBar', 'var')
    close(progBar)
end