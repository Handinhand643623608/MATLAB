function dataOutput = f_CA_initialize_datastruct(dataType, paramStruct, varargin)
% F_CA_DATASTRUCT_INITIALIZE Produce a data structure suited for either EEG
%   or BOLD data. The structure contains blank areas for data and completed
%   information sections based on the data that is inputted. 
% 
%   Syntax:
%   data_output = f_CA_datastruct_initialize(data_type, subject, param_struct)
% 
%   DATA_TYPE: A string of either 'BOLD' or 'EEG' denoting which type of
%              data structure should be constructed.
%   PARAM_STRUCT: A parameter structure created earlier in this analysis.
% 
%   Written by Josh Grooms on 6/13/2012
%       Modified on 6/30/2012 to accomodate parallel computing capabilities

%% Create the Data Structure
switch dataType
    case 'BOLD'
        
        % Assign variables
        subject = varargin{1};
        scans = varargin{2};
        
        % Create the BOLD data structure
        dataOutput.BOLD(length(scans)) = struct('functional', [], 'mean', []);
        dataOutput.info = struct(...
            'struct_format', 'BOLD_data.data(scan).fieldname...',...        
            'subject', subject,...
            'scans', scans,...
            'data_format', '(X x Y x Z x Time)',...
            'TR', paramStruct.initialize.BOLD.TR,...
            'TE', paramStruct.initialize.BOLD.TE,...
            'voxel_size', paramStruct.initialize.BOLD.voxel_size);

        dataOutput.masks = struct('GM', [], 'WM', [], 'CSF', []);
                
    case 'EEG'
        % Assign variables
        if length(varargin) > 0
            subjects = varargin{1};
            scans = varargin{2};
        else            
            subjects = paramStruct.general.subjects;
            scans = paramStruct.general.scans;
        end
         
        % Determine the maximum number of scans the structure must accommodate
        max_scans = 0;
        for i = 1:length(scans)
            if iscell(scans)
                if ~isempty(scans{i})
                    test_scans = length(scans{i});
                    if test_scans > max_scans
                        max_scans = test_scans;
                    end
                end
            else
                max_scans = length(scans);
            end
        end
        
        % Create the EEG data structure
        dataOutput(length(subjects), max_scans) = struct('data', [], 'info', []);
                
        for i = 1:length(subjects)
            
            % Determine the type of input
            if iscell(scans)
                lenScans = length(scans{i});
                scans = scans{i};
            else
                lenScans = length(scans);
            end
            
            for j = 1:lenScans
                dataOutput(i, j).data = struct('EEG', [], 'BCG', []);
                dataOutput(i, j).info = struct(...
                    'struct_format', 'EEG_data(subject, scan).fieldname...',...
                    'data_format', '(Channels x Time Points)',...
                    'subject', subjects(i),...
                    'scan', scans(j));
            end
        end
end

