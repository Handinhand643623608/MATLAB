function [fileStruct paramStruct] = f_CA_initialize(fileStruct, paramStruct)
% F_CA_INITIALIZE Produce two structures. The first contains information on
%   the data collected (a parameter structure). The second contains
%   information on file & data paths as well as wildcards for finding other
%   data. Structures produced are not complete; data will be added to them
%   in subsequent functions.
% 
%   Syntax:
%   [file_struct param_struct] = f_CA_initialize(file_struct, param_struct)
% 
%   Written by Josh Grooms on 6/14/2012
%       Modified heavily on 6/30/2012 to perform a more refined function


switch paramStruct.general.append
    case 0
        %% Determine the Total Number of Subjects & Scans
        % Initialize
        subject_foldernames = f_CA_filenames(fileStruct.paths.raw, 'dir');
        scans_foldernames = {};
        for i = 1:length(subject_foldernames)
            scans_foldernames{i} = f_CA_filenames(subject_foldernames{i}, 'ep2d', 'dir');
        end
        
        if strcmp(paramStruct.general.subjects, 'auto') || isempty(paramStruct.general.subjects)
            % Determine the number of subjects collected so far
            subjects = 1:length(subject_foldernames);

            % Determine the total number of scans per subject
            scans = {};
            for i = subjects    
                scans{i} = 1:length(scans_foldernames);    
            end

            % Fill in values in parameter structure
            paramStruct.general = struct('subjects', subjects, 'scans', {scans});
        end
        
        subjects = paramStruct.general.subjects;
        scans = paramStruct.general.scans;

        %% Add Functional, Anatomical, & EEG data paths to the file structure
        % Initialize relevant sections in the file structure
        fileStruct.paths.anatomical = f_CA_create_data_cells(subjects);
        fileStruct.paths.raw_functional = f_CA_create_data_cells(subjects);
        fileStruct.paths.EEG = f_CA_create_data_cells(subjects);

        % Fill in the new fields
        for i = subjects
            temp_EEG = f_CA_filenames(subject_foldernames{i}, 'EEG', 'dir');
            temp_anatomical = f_CA_filenames(subject_foldernames{i}, 't1', 'dir');

            fileStruct.paths.anatomical{i} = temp_anatomical{1};
            fileStruct.paths.EEG{i} = temp_EEG{1};
            fileStruct.paths.raw_functional{i} = f_CA_filenames(subject_foldernames{i}, 'ep2d', 'dir');
        end

        %% Initialize Fields for Later Use
        % Initialize fields that require subject & scan cells
        [...
            fileStruct.files.mean,...
            fileStruct.paths.mean,...
            fileStruct.paths.corrected_functional] = deal(f_CA_create_data_cells(subjects, scans));

        % Initialize fields that require only subject celss
        [...
            fileStruct.files.segments,...
            fileStruct.files.anatomical] = deal(f_CA_create_data_cells(subjects));

        %% Clear Data from Previous Imports from Raw Data Folders
        f_CA_clean_folders(paramStruct.general.subjects, fileStruct);

        %% Initialize the MATLAB Parallel Computing Capabilities
        % if matlabpool('size') == 0
        %     matlabpool;
        % end

        %% Initialize SPM for Batch Processing
        spm_jobman('initcfg');

        %% Create Folders for Preprocessed Data
        f_CA_create_folders('Preprocessed Data', fileStruct.paths.main, paramStruct.general.subjects, paramStruct.general.scans);
        fileStruct.paths.preprocessed = [fileStruct.paths.main '/Preprocessed Data'];

        %% Create an Analysis Folder for Storing Results
        if exist([fileStruct.paths.main '/Analyses'], 'dir') ~= 7
            mkdir([fileStruct.paths.main '/Analyses'])
        end
        fileStruct.paths.analyses = [fileStruct.paths.main '/Analyses'];

        clc
    
    case 1
        %% Determine the number of new subjects
        oldSubjects = length(f_CA_filenames(fileStruct.paths.preprocessed, 'Subject', 'dir'));
        newSubjectFoldernames = f_CA_filenames(fileStruct.paths.raw, 'dir');
        appendSubjects = (oldSubjects + 1):length(newSubjectFoldernames);
        
        % Store the difference in subject numbers in the parameter structure
        paramStruct.general.appendSubjects = appendSubjects;
        
        % Determine the number of scans for each new subjects
        for i = appendSubjects
            scansFoldernames = f_CA_filenames(newSubjectFoldernames{i}, 'Rest', 'middle', 'dir');
            
            % Fill in values in the parameter structure
            paramStruct.general.subjects(i) = i;
            paramStruct.general.scans{i} = 1:length(scansFoldernames);
        end
            
        %% Add Functional, Anatomical, & EEG data paths to the file structure
        % Initialize relevant sections in the file structure
        for i = appendSubjects
            fileStruct.paths.anatomical{i} = f_CA_filenames(newSubjectFoldernames{i}, 't1', 'dir');
            fileStruct.paths.raw_functional{i} = f_CA_filenames(newSubjectFoldernames{i}, 'ep2d', 'dir');
            fileStruct.paths.EEG{i} = f_CA_filenames(newSubjectFoldernames{i}, 'EEG', 'dir');
        end
        
        %% Initialize Fields for Later Use
%         fileStruct.files.mean = [fileStruct.files.mean; f_CA_create_data_cells(appendSubjects, paramStruct.general.scans{i})];
%         fileStruct.paths.mean = [fileStruct.paths.mean; f_CA_create_data_cells(appendSubjects, paramStruct.general.scans{i})];
%         fileStruct.paths.corrected_functional = [fileStruct.paths.corrected_functional; f_CA_create_data_cells(appendSubjects, paramStruct.general.scans{i})];
%         fileStruct.files.segments = [fileStruct.files.segments; f_CA_create_data_cells(appendSubjects)];
%         fileStruct.files.anatomical = [fileStruct.files.anatomical; f_CA_create_data_cells(appendSubjects)];
   
        %% Clear Data from Previous Imports from Raw Data Folders
        f_CA_clean_folders(appendSubjects, fileStruct);
                
        %% Initialize SPM for Batch Processing
        spm_jobman('initcfg');
        
        %% Create Folders for Preprocessed Data
        f_CA_create_folders('Preprocessed Data', fileStruct.paths.main, appendSubjects, paramStruct.general.scans);
end
              