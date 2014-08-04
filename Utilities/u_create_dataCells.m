function data_cells = u_create_dataCells(varargin)

switch length(varargin)
    case 1
        % Assign variables
        subjects = varargin{1};
        
        % Create the data cells
        data_cells = cell(length(subjects), 1);
    case 2
        % Assign variables
        subjects = varargin{1};
        scans = varargin{2};
        
        % Create the data cells
        data_cells = cell(length(subjects), 1);
        for i = subjects
            data_cells{i} = cell(length(scans{i}), 1);
        end
end
