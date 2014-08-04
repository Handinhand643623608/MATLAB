function corrData = initialize(corrData, ccStruct)
%INITIALIZE Initialize the correlation data object & sets up parameters for analysis.
%   This function assigns the user-specified input parameters to the correlation data object & prepares the object for
%   the subsequent correlation analysis.
%
%   WARNING: INITIALIZE is an internal method for corrObj and is not meant to be called externally.
%
%   Written by Josh Grooms on 20130702
%       20130709:   Updated to remove "ScanDate" property, which has been deleted from all humanObj descendents. Bug 
%                   fixes for initialization during null generation (specifically with the "Modalities" & "Subject/Scan" 
%                   properties).
%       20130719:   Rewrote automated data set selection section so that data strings will be set regardless of parent 
%                   BOLD input.
%       20130906:   Rewrote function to allow for more flexibility in what is being correlated.
%       20130919:   Bug fix for not being able to distinguish global regression in parent data sets.
%       20131027:   Implemented RSN-EEG correlations & BOLD-BOLD nuisance correlations. Removed flexibility for modality 
%                   names (would be too difficult to keep up with throughout the code).
%       20131126:   Implemented BOLD-RSN correlations to test how well ICA is doing its job.
%       20131222:   Implemented BOLD-Motion nuisance parameter correlations.
%       20140217:   Added in an initialization segment for converting the general "BOLD Nuisance" control string into a
%                   cell array of the actual object field names. Added ability to run partial correlations between BOLD
%                   data and its global signal.


%% Initialize
% Determine the strings of the data to be correlated
ccStruct = modalityDataStrs(ccStruct);

% Get the correlation parent data sets
parentData = findParentData(ccStruct);

% Get the subjects & scans to be used. If empty, use all available
load masterStructs;
subjects = ccStruct.Correlation.Subjects;
scans = ccStruct.Correlation.Scans;
if isempty(subjects) || strcmpi(subjects, 'all')
    subjects = paramStruct.general.subjects; ccStruct.Correlation.Subjects = subjects;
end
if isempty(scans) || any(strcmpi(scans, 'all'))
    scans = paramStruct.general.scans; ccStruct.Correlation.Scans = scans;
end

% If BOLD control variables are being used, make sure they're in the proper format
if strcmpi(ccStruct.Correlation.Control, 'bold nuisance')
    ccStruct.Correlation.Control = {'Motion', 'Global', 'WM', 'CSF'};
end


%% Transfer Input Properties & Parameters to Data Object
% Get the properties to be tranferred
propNames = fieldnames(ccStruct.Initialization);

% Transfer properties (depending on whether or not a null distribution is being generated)
if ~ccStruct.Correlation.GenerateNull
    
    % Initialize the object array
    corrData(subjects(end), max(cellfun(@max, scans))) = corrObj;
    
    for a = subjects
        for b = scans{a}
            % Assign parent data sets to the object
            for c = 1:2
                corrData(a, b).ParentData{c} = parentData{c}{a};
            end
            
            for c = 1:length(propNames)
                % Fill in subject & scan properties
                corrData(a, b).Subject = a;
                corrData(a, b).Scan = b;
                
                % Fill in all other object properties
                corrData(a, b).(propNames{c}) = ccStruct.Initialization.(propNames{c});
            end
            corrData(a, b).Parameters = ccStruct;
        end
    end
    
else
    
    % Initialize the data object array
    pairings = nullPairings(scans);
    corrData(size(pairings, 1)) = corrObj;
    
    for a = 1:length(pairings)
        % Fill in subject & scan properties
        corrData(a).Subject = [pairings{a, 1}(1), pairings{a, 2}(1)];
        corrData(a).Scan = [pairings{a, 1}(2), pairings{a, 2}(2)];
        
        % Assign parent data sets to the object
        for b = 1:2
            corrData(a).ParentData{b} = parentData{b}{pairings{a, b}(1)};
        end
        
        % Fill in all other object properties
        for b = 1:length(propNames)
            switch propNames{b}
                case 'ParentBOLD'
                    corrData(a).ParentBOLD = ParentBOLD{pairings{a, 1}(1)};
                otherwise
                    corrData(a).(propNames{b}) = ccStruct.Initialization.(propNames{b});
            end
        end
        corrData(a).Parameters = ccStruct;
    end
end


end%================================================================================================
%% Nested Functions
% Determine data strings for parsing data sets
function ccStruct = modalityDataStrs(ccStruct)
    switch lower(ccStruct.Initialization.Modalities)
        case 'bold-eeg'
            ccStruct.Correlation.DataStrs = ccStruct.Correlation.Channels;
        case 'bold nuisance-eeg'
            ccStruct.Correlation.DataStrs = {'Motion', 'Global', 'WM', 'CSF'};
        case 'bold-global'
            ccStruct.Correlation.DataStrs = {'Global'};
        case {'rsn-eeg', 'bold-rsn'}
            ccStruct.Correlation.DataStrs = {'Unknown1', 'Executive', 'Cerebellum', 'DAN', 'Precuneus',...
                'Salience', 'CSF', 'ACC', 'RLN', 'BG', 'Auditory', 'WM', 'DMN', 'PCC', 'PVN', 'LVN',...
                'Unknown2', 'Noise', 'SMN', 'LLN'};
        case 'bold-bold nuisance'
            ccStruct.Correlation.DataStrs = {'Global', 'WM', 'CSF'};
        case 'bold-motion'
            ccStruct.Correlation.DataStrs = {'Motion1', 'Motion2', 'Motion3', 'Motion4', 'Motion5', 'Motion6'};
    end
end

% Determine what data sets to load
function parentData = findParentData(ccStruct)
    load masterStructs
    parentData = cell(1, 2); searchStr = cell(1, 2);
    modalities = segmentModalities(ccStruct);
    for a = 1:2
        searchStr{a} = ['_' ccStruct.Initialization.ScanState '_'];
        
        if strcmpi(ccStruct.Initialization.Bandwidth{a}, 'dc') || isequal(ccStruct.Initialization.Bandwidth{a}, [0.01 0.08])
            searchStr{a} = [searchStr{a} 'dc'];
        elseif strcmpi(ccStruct.Initialization.Bandwidth{a}, 'fb')
            searchStr{a} = [searchStr{a} 'fb'];
        end
        
        if istrue(ccStruct.Initialization.GSR(a)); searchStr{a} = [searchStr{a} 'GRZ']; 
        else searchStr{a} = [searchStr{a} 'Z']; end
        
        switch lower(modalities{a})
            case {'bold', 'fmri', 'bold nuisance', 'rsn', 'global'}
                folderStr = '/BOLD';
            case {'eeg', 'eeg nuisance', 'blp'}
                folderStr = '/EEG';
        end
        
        parentData{a} = get(fileData([fileStruct.Paths.DataObjects folderStr], 'Search', searchStr{a}), 'Path');
    end
end

% Segment modalities string into parsable cells
function modalities = segmentModalities(ccStruct)
    modalities = regexpi(ccStruct.Initialization.Modalities, '([^-]*)', 'tokens');
    modalities = cat(2, modalities{:});
end