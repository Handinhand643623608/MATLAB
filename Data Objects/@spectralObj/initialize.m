function spectralData = initialize(spectralData, specStruct)
%INITIALIZE Initializes the spectral data object & sets up parameters for analysis
%
%   WARNING: INITIALIZE is an internal method and is not meant to be called externally.
%
%   Written by Josh Grooms on 20130910


%% Initialize
% Get the subject & scans to be used. If empty, use all available
specStruct = findSubjectsScans(specStruct);

% Initialize the spectral data object
spectralData = dataArray(specStruct);

% Get the spectra parent data sets
specStruct = findParentData(specStruct);
    

%% Transfer Important Properties to the Spectral Object
propNames = fieldnames(specStruct.Initialization);

for a = specStruct.Initialization.Subjects
    for b = specStruct.Initialization.Scans{a}
        for c = 1:length(propNames)
                switch lower(propNames{c})
                    case 'parentdata'
                        spectralData(a, b).ParentData = specStruct.Initialization.ParentData{a};
                    case {'subjects', 'scans'}
                        spectralData(a, b).Subject = a;
                        spectralData(a, b).Scan = b;
                    otherwise
                        spectralData(a, b).(propNames{c}) = specStruct.Initialization.(propNames{c});
                end
        end
            % Move other properties to the spectral data object
            spectralData(a, b).Averaged = false;
            spectralData(a, b).Parameters = specStruct;
            spectralData(a, b).Channels = specStruct.Spectrum.Channels;
    end
end


end%================================================================================================
%% Nested Functions
% Determine which subjects & scans to use in the analysis
function specStruct = findSubjectsScans(specStruct)
    load masterStructs
    assignInputs(specStruct.Initialization, 'varsOnly')
    if isempty(Subjects) || strcmpi(Subjects, 'all')
        specStruct.Initialization.Subjects = paramStruct.general.subjects;
    end
    if isempty(Scans) || any(strcmpi(Scans, 'all'))
        specStruct.Initialization.Scans = paramStruct.general.scans;
    end
end

% Generate an array of spectral data objects
function spectralData = dataArray(specStruct)
    assignInputs(specStruct.Initialization, 'varsOnly');
    spectralData(Subjects(length(Subjects)), max(cellfun(@max, Scans))) = spectralObj;
end

% Determine which data sets to load
function specStruct = findParentData(specStruct)
    load masterStructs
    assignInputs(specStruct.Initialization, 'varsOnly');
    if isempty(ParentData)
        searchStr = ['_' ScanState '_'];
        if strcmpi(Bandwidth, 'dc') || isequal(Bandwidth, [0.01 0.08])
            searchStr = [searchStr 'dc'];
        elseif strcmpi(Bandwidth, 'fb')
            searchStr = [searchStr 'fb'];
        end
        if istrue(GSR); searchStr = [searchStr 'GR']; end
        specStruct.Initialization.ParentData = get(fileData([fileStruct.Paths.DataObjects '/EEG'], 'Search', searchStr), 'Path');
    end
end