function cohData = initialize(cohData, cohStruct)
%INITIALIZE Initializes the coherence data object & sets up parameters for analysis.
%   This function assigns the user-specified input parameters to the coherence data object and
%   prepares the object for the subsequent coherence analysis. 
%   
%   WARNING: initialize is an internal method for cohObj and is not meant to be called externally.
%
%   Written by Josh Grooms on 20130911


%% Initialize
% % Determine the strings of the data to be correlated
% cohStruct = modalityDataStrs(cohStruct);

% Get the correlation parent data sets
cohStruct = findParentData(cohStruct);

% Get the subjects & scans to be used. If empty, use all available
cohStruct = findSubjectsScans(cohStruct);


%% Transfer Input Properties & Parameters to Data Object
% Get the properties to be tranferred & initialize object
propNames = fieldnames(cohStruct.Initialization);

% Transfer properties (depending on whether or not a null distribution is being generated)
if ~cohStruct.Coherence.GenerateNull
    
    % Initialize the object array
    cohData = dataArray(cohStruct);
    
    for a = cohStruct.Initialization.Subjects
        for b = cohStruct.Initialization.Scans{a}
            for c = 1:length(propNames)
                switch lower(propNames{c})
                    case {'subjects', 'scans'}
                        cohData(a, b).Subject = a;
                        cohData(a, b).Scan = b;
                    case 'parentdata'
                        cohData(a, b).ParentData = {cohStruct.Initialization.ParentData{1}{a};
                                                    cohStruct.Initialization.ParentData{2}{a}};
                    otherwise
                        cohData(a, b).(propNames{c}) = cohStruct.Initialization.(propNames{c});
                end
            end
            cohData(a, b).Parameters = cohStruct;
        end
    end
    
else
    
    % Initialize the data object array
    pairings = nullPairings(cohStruct.Initialization.Scans);
    cohData(size(pairings, 1)) = cohObj;
    
    for a = 1:length(pairings)
        
        % Assign parent data sets to the object
        for b = 1:2
            cohData(a).ParentData{b} = cohStruct.Initialization.ParentData{b}{pairings{a, b}(1)};
        end
        
        % Fill in all other object properties
        for b = 1:length(propNames)
            switch lower(propNames{b})
                case {'subjects', 'scans'}
                    cohData(a).Subject = [pairings{a, 1}(1), pairings{a, 2}(1)];
                    cohData(a).Scan = [pairings{a, 1}(2), pairings{a, 2}(2)];
                case 'parentdata'
                    cohData(a).ParentData = {cohStruct.Initialization.ParentData{1}{pairings{a, 1}(1)};
                                             cohStruct.Initialization.ParentData{2}{pairings{a, 2}(1)}};
                otherwise
                    cohData(a).(propNames{b}) = cohStruct.Initialization.(propNames{b});
            end
        end
        cohData(a).Parameters = cohStruct;
    end
end


end%================================================================================================
%% Nested Functions
% Determine which subjects & scans to use in the analysis
function cohStruct = findSubjectsScans(cohStruct)
    load masterStructs
    assignInputs(cohStruct.Initialization, 'varsOnly')
    if isempty(Subjects) || strcmpi(Subjects, 'all')
        cohStruct.Initialization.Subjects = paramStruct.general.subjects;
    end
    if isempty(Scans) || any(strcmpi(Scans, 'all'))
        cohStruct.Initialization.Scans = paramStruct.general.scans;
    end
end

% Generate an array of spectral data objects
function cohData = dataArray(cohStruct)
    assignInputs(cohStruct.Initialization, 'varsOnly');
    cohData(Subjects(length(Subjects)), max(cellfun(@max, Scans))) = cohObj;
end

% Determine which data sets to load
function cohStruct = findParentData(cohStruct)
    if isempty(cohStruct.Initialization.ParentData)
        load masterStructs
        assignInputs(cohStruct.Initialization, 'varsOnly');
        searchStr = cell(2, 1);
        modalities = segmentModalities(cohStruct);

        for a = 1:2
            searchStr{a} = ['_' ScanState '_'];
            if strcmpi(Bandwidth{a}, 'dc') || isequal(Bandwidth{a}, [0.01 0.08])
                searchStr{a} = [searchStr{a} 'dc'];
            elseif strcmpi(Bandwidth{a}, 'fb')
                searchStr{a} = [searchStr{a} 'fb'];
            end

            if istrue(GSR(a)); searchStr{a} = [searchStr{a} 'GRZ']; 
            else searchStr{a} = [searchStr{a} 'Z']; end;

            switch lower(modalities{a})
                case {'bold', 'fmri', 'bold nuisance', 'rsn'}
                    folderStr = '/BOLD';
                case {'eeg', 'eeg nuisance', 'blp'}
                    folderStr = '/EEG';
            end

            cohStruct.Initialization.ParentData{a} = get(fileData([fileStruct.Paths.DataObjects folderStr], 'Search', searchStr{a}), 'Path');
        end
    end
end

% Segment modalities string into parsable cells
function modalities = segmentModalities(cohStruct)
    modalities = regexpi(cohStruct.Initialization.Modalities, '([^-]*)', 'tokens');
    modalities = cat(2, modalities{:});
end

