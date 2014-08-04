function relationData = convertDataStruct(relationData, varargin)
%CONVERTDATASTRUCT Converts relation data from old-style data structures into the new data objects.
%This relationData class-specific method is a protected method not intended for general purpose use.
%
%   Written by Josh Grooms on 20130428
%       20130611:   Updated to convert old correlation data structures.


%% Initialize
% Initialize a defaults & settings structure
inStruct = struct(...
    'Bandwidth', [],...
    'DataStruct', [],...
    'Filtered', [],...
    'FilterShift', [],...
    'GlobalRegressed', [],...
    'ParentBOLD', [],...
    'ParentEEG', [],...
    'Modalities', [],...
    'Relation', [],...
    'Parameters', [],...
    'Scan', [],...
    'ScanDate', [],...
    'ScanState', [],...
    'StorageDate', [],...
    'StoragePath', [],...
    'Subject', [],...
    'ZScored', []);

% Get the data structure
inStruct.DataStruct = varargin{1};
varargin(1) = [];

% Assign the remaining arguments to the input structure
assignInputs(inStruct, varargin, 'structOnly');
propNames = fieldnames(inStruct);

% Initialize the object data is being transferred to
relationData(size(inStruct.DataStruct, 1), size(inStruct.DataStruct, 2)) = relationObj;


%% Move Data from Structure to Object
for i = 1:size(inStruct.DataStruct, 1)
    for j = 1:size(inStruct.DataStruct, 2)
        if ~isempty(inStruct.DataStruct(i, j).data)            
            % Transfer properties & data
            for k = 1:length(propNames)
                
                switch propNames{k}
                    case 'DataStruct'
                        
                        % Deal with the data structure according to the relationship that was examined
                        switch lower(inStruct.Relation)
                            
                            case 'coherence'
                                
                                % If coherence was run, get the electrodes used & determine the BOLD masking method
                                channels = inStruct.Parameters.channels;
                                switch lower(inStruct.Parameters.maskMethod)
                                    case {'correlation', 'corrdata', 'corr', 'xcorrdata', 'xcorr'}
                                        
                                        % If correlation data were used as the mask, loop through the channels used & transfer data
                                        for L = 1:length(channels)                                        
                                            relationData(i, j).Data.Coherence.(['corr' channels{L}]) = inStruct.DataStruct(i, j).data.(channels{L})(1, :);
                                            relationData(i, j).Data.Coherence.(['acorr' channels{L}]) = inStruct.DataStruct(i, j).data.(channels{L})(2, :);
                                        end
                                        
                                end
                                
                                % Transfer over the frequencies that were used in the coherence analysis
                                relationData(i, j).Data.Frequencies = inStruct.DataStruct(i, j).info.freqs;
                                                                
                            case 'correlation'
                                                                                                
                                % If correlation was run, transfer the data
                                if isstruct(inStruct.DataStruct(i, j).data)
                                    dataFields = fieldnames(inStruct.DataStruct(i, j).data);
                                    for L = 1:length(dataFields)
                                        relationData(i, j).Data.Correlation.(dataFields{L}) = inStruct.DataStruct(i, j).data.(dataFields{L});
                                    end
                                else
                                    relationData(i, j).Data.Correlation = inStruct.DataStruct(i, j).data;
                                end
                                if isfield(inStruct.Parameters, 'Channels')
                                    if isempty(inStruct.Parameters.Channels)
                                        if isfield(inStruct.DataStruct(i, j).info, 'channels')
                                            inStruct.Parameters.Channels = inStruct.DataStruct(i, j).info.channels;
                                        elseif isfield(inStruct.DataStruct(i, j).info, 'electrodes')
                                            inStruct.Parameters.Channels = inStruct.DataStruct(i, j).info.electrodes;
                                        end
                                    end
                                end
                        end
                        
                    case 'ParentBOLD'
                        
                        % If the parent BOLD field is empty, this can be determined for coherence (full-band)
                        if isempty(inStruct.ParentBOLD) && strcmpi(inStruct.Relation, 'coherence')
                            boldFiles = fileData('E:\Graduate Studies\Lab Work\Data Sets\Data Objects\BOLD');
                            boldFiles = get(boldFiles, 'Name', 'search', ['boldObject-' num2str(i) '_' inStruct.ScanState '_fbZ']);
                            relationData(i, j).ParentBOLD = boldFiles{end};
                        elseif ~isempty(inStruct.ParentBOLD) && length(inStruct.ParentBOLD) > 1
                            relationData(i, j).ParentBOLD = inStruct.ParentBOLD{i};
                        elseif ~isempty(inStruct.ParentBOLD) && length(inStruct.ParentBOLD) == 1
                            relationData(i, j).ParentBOLD = inStruct.ParentBOLD;
                        else
                            error('Unknown or empty input provided for "ParentBOLD" parameter.')
                        end
                        
                        
                    case 'ScanDate'
                        
                        % Get the original scan date of the subject being analyzed
                        if isempty(inStruct.ScanDate)
                            % Get the original scan date of the data
                            load masterStructs                            
                            scanFiles = fileData([fileStruct.Paths.DataStructs '\human_data\No BOLD Global Regression'], 'search', 'human_data');
                            fileNames = get(scanFiles, 'Name');
                            dateExpr = '_(\d\d\d\d\d\d\d\d)_';
                            humanDataDates = regexp(fileNames, dateExpr, 'tokens');
                            humanDataDates = cat(1, humanDataDates{:});
                            scanDates = cat(1, humanDataDates{:});
                            inStruct.ScanDate = scanDates{i};
                        end
                        relationData(i, j).ScanDate = inStruct.ScanDate;   
                        
                    case {'StorageDate', 'StoragePath'}
                        continue
                    
                    case {'Subject', 'Scan'}
                       
                        % Fill in the subject & scan section
                        relationData(i, j).Subject = i;
                        relationData(i, j).Scan = j;

                    otherwise
                        
                        % If one of the other properties is being addressed, just transfer it over
                        if isempty(inStruct.(propNames{k}))
                            error(['No input provided for property ' propNames{k} '. Input must be provided for most parameters']);
                        else
                            relationData(i, j).(propNames{k}) = inStruct.(propNames{k});
                        end
                end
            end
        end
    end
end