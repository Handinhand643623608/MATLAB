function u_clean_rawFolders(subjects, fileStruct)

%% Initialize
% Get a list of subject folders
sub_foldernames = f_CA_filenames(fileStruct.paths.raw, 'dir');

%% Clean Out the Folders
for i = subjects
    
    % Get a list of the functional folder names
    functional_foldernames = u_filenames(sub_foldernames{i}, 'ep2d', 'dir');
    
    % Get the anatomical folder name
    anatomical_foldername = u_filenames(sub_foldernames{i}, 't1', 'dir');
    
    % Delete anatomical files
    delete([anatomical_foldername{1} '/anatomical_import.txt']);
    delete([anatomical_foldername{1} '/segments_import.txt']);
    
    % Delete functional files
    for j = 1:length(functional_foldernames)
        if exist([functional_foldernames{j} '/mean'], 'dir') == 7
            rmdir([functional_foldernames{j} '/mean'], 's')
        elseif exist([functional_foldernames{j} '/IMG'], 'dir')
            rmdir([functional_foldernames{j} '/IMG'], 's')
        end
        delete([functional_foldernames{j} '/ep2d*.*']);
    end
end
