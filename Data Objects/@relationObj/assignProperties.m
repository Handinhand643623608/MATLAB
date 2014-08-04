function relationData = assignProperties(relationData, varargin)
%ASSIGNPROPERTIES Assigns relation data object properties based on constructor inputs. This function
%   also prepares the data object for subsequent analysis using parameters specified in a structure
%   under the 'Parameters' property. 
%
%   SYNTAX:
%   relationData = assignProperties(relationData, 'PropertyName', PropertyValue,...)
%
%   OUTPUTS:
%   relationData
%
%   PROPERTY NAMES:
%   'Bandwidth':
%
%   ('DataPath'):
%
%   'Modalities':
%
%   'Parameters':
%
%   'Relation':
%
%   ('Scan'):
%
%   ('Subject'):
%
%   ('ScanState'):
%
%   Written by Josh Grooms on 20130321
%       20130329:   Updated to handle only single subjects per function call
%       20130428:   Updated function to handle all subjects & scans simultaneously. Expanded the
%                   help section. 
%       20130613:   Added "Modalities" property to easily determine which data are being compared.
%                   Bug fix for problem caused by updates to "fileData" object.


%% Initialize
inStruct = struct(...
    'Bandwidth', [],...
    'DataPath', 'E:\Graduate Studies\Lab Work\Data Sets\Data Objects',...
    'Modalities', [],...
    'Parameters', [],...
    'ParentBOLD', [],...
    'ParentEEG', [],...
    'Relation', [],...
    'Scan', [],...
    'Subject', [],...
    'ScanState', 'RS');

assignInputs(inStruct, varargin, 'structOnly',...
    'compatibility', {'DataPath', 'path', 'dir';
                      'Relation', 'analysis', 'method';...
                      'Scan', 'scans', [];...
                      'ScanState', 'state', 'task'},...
    {'Relation'}, 'varPlaceholder(1) = upper(varPlaceholder(1))');
    
    
%% Gather the Data Sets to be Used
switch inStruct.Relation
    case 'Coherence'
        % Get the BOLD data files
        boldFiles = fileData([inStruct.DataPath '\BOLD'], 'Search', [inStruct.ScanState '_fbZ']);
        boldFiles = get(boldFiles, 'Name');
               
        % Gather the EEG data files
        eegFiles = fileData([inStruct.DataPath '\EEG'], 'Search', ['eegObject_' inStruct.ScanState '_fbZ']);
        eegFiles = get(eegFiles, 'Name');
        eegFiles = eegFiles{end};
                                
        % Condition the variables for transfer to the object
        inStruct.ParentBOLD = boldFiles;
        inStruct.ParentEEG = eegFiles;
        if isempty(inStruct.Bandwidth)
            inStruct.Bandwidth = [0 0.5];
        end
        
    case 'Correlation'
        
end

% Get the subjects & scans to be used. If empty, use all available
subjects = inStruct.Parameters.Subjects;
if isempty(subjects) || strcmpi(subjects, 'all')
    load eegObject_RS_dcGRZ_20130407;
    subjects = 1:size(eegData, 1);
    inStruct.Parameters.Subjects = subjects;
end
scans = inStruct.Parameters.Scans;
if isempty(scans) || strcmpi(scans, 'all')
    scans = cell(1, subjects(end));
    for a = subjects
        for b = 1:size(eegData, 2)
            if ~isempty(eegData(a, b).Data)
                scans{a}(b) = b;
            end
        end
    end
    inStruct.Parameters.Scans = scans;
end

    
%% Transfer Inputs to Object Properties
% Get the properties to be transferred to the object
propNames = fieldnames(inStruct);

% Initialize the relation data object array & fill in properties
if inStruct.Parameters.GenerateNull
    for a = 1:length(propNames)
        switch propNames{a}
            case {'DataPath'}
                continue
                
            case 'Subject'
                relationData.Subject = subjects;
                
            case 'Scan'
                relationData.Scan = scans;
            otherwise
                relationData.(propNames{a}) = inStruct.(propNames{a});
        end
    end
else
    relationData(subjects(end), max(cellfun(@max, scans))) = relationData;
    for a = subjects
        for b = scans{a}
            for c = 1:length(propNames)
                switch propNames{c}
                    case 'DataPath'
                        continue

                    case {'Subject', 'Scan'}
                        relationData(a, b).Subject = a;
                        relationData(a, b).Scan = b;

                    case {'ParentBOLD'}
                        relationData(a, b).ParentBOLD = inStruct.ParentBOLD{a};

                    otherwise
                        relationData(a, b).(propNames{c}) = inStruct.(propNames{c});
                end
            end 
        end
    end
end

