function folderStruct = createNestedFolders(varargin)
%CREATENESTEDFOLDERS Creates 2 levels of nested folder structure, depending on the inputs. This
%   function also outputs the paths to every folder inside of a structure with fields and subfields
%   named like the actual folder structure.
% 
%   Syntax:
%   folderStruct = createNestedFolders('varName1', varValue1,...,'varNameN', varValueN)
% 
%   OUTPUT:
%   folderStruct:           A folder structure that closely mirrors the hierarchy of the folders
%                           that are being created. However, there are some notable differences. Any
%                           folders that are created in multiples (e.g. 'folder 1' 'folder 2'...)
%                           are represented in the structure by the root name (i.e. 'folder') and
%                           contain subfields for each multiple('one', 'two'...). Primary folders 
%                           are listed earlier in the structure, with secondary subfolders listed
%                           later.
%                           EXAMPLES:
%                               
%                               To retrieve the path of a simple folder/subfolder arrangement:
%                                  folderStruct.folder.subfolder
%                               
%                               To retrieve the path of a primary/subfolder with multiple root-word
%                               primaries:
%                                   folderStruct.folder.one.subfolder
%                                   folderStruct.folder.two.subfolder                  
% 
%                               To retrieve the path of a single primary folder alone:
%                                   folderStruct.folder.root
% 
%                               To retrieve the path of a single primary folder whose root-word has 
%                               multiples:
%                                   folderStruct.folder.one.root
% 
%                               To retrieve the path of a subfolder (with multiples using its
%                               root-word) that lies under a primary with multiples from its
%                               root-word:
%                                   folderStruct.folder.one.subfolder.one
% 
%                           HINT: Any time a subfolder is involved in calling a desired path, the
%                           field "root" is not used. A call to any subfolder path ends with either 
%                           the subfolder name or the number of the root-word that is desired.
% 
%   PROPERTY NAMES:
%   ('inPath'):             The path string to the uppermost folder to be created. This can contain
%                           any number of folders that don't yet exist, but the nested folder
%                           structure will begin in the folder at the end of that path.
%                           DEFAULT: pwd (the current working directory)
% 
%   ('firstLevel'):         A string or cell array of strings of instructions on how to create the
%                           primary (first level) folders and what to name them. How the folder name 
%                           is typed in is exactly how it will appear in the file explorer. The
%                           following examples illustrate how the instructions work when typed in as
%                           the second entry in the name/value input.
%                           EXAMPLES:
%                   
%                               To create a primary folder named "Folder":
%                                   'Folder'
% 
%                               To create multiple primary folders:
%                                   {'First Folder'; 'Second Folder'; 'Third Folder'}
% 
%                               To create five folders that share a common first word (i.e.
%                               folders of the same name but having numerical differentiators):
%                                   {'Folder', [1 2 3 4 5]}
% 
%                               A mixed list of the above:
%                                   {'Folder', [2 4 6 8];
%                                    'New Folder', [];
%                                    'Directory', [9 10 11]}
%                               This creates "Folder 2", "Folder 4", "Folder 6", "Folder 8", a
%                               single "New Folder", and "Directory 9", "Directory 10", "Directory
%                               11" in the input (or working) directory.
% 
%                           DEFAULT: 'newFolder' (a single folder with this title will be created)
% 
%   ('secondLevel'):        A string or cell array of strings with instructions on how and where to
%                           create the secondary (subfolder level) folders and what to name them.
%                           This works in exactly the same way as the 'nameFirstLevel' parameter,
%                           but with an extra feature: subfolders and be created inside of select
%                           primary folders only and nowhere else. The following examples illustrate
%                           how to type in the instructions.
%                           EXAMPLES:
%           
%                               To create a subfolder named "Subfolder" in every primary folder:
%                                   'Subfolder'
% 
%                               To create multiple subfolders with different names in every primary
%                               folder:
%                                   {'First Subfolder'; 'Second Subfolder'; 'Third Subfolder'}
% 
%                               To create numbered subfolders that all share a common root-word in
%                               every primary folder:
%                                   {'Subfolder', [], [1 2 3 4 5 6]}
% 
%                               To create a single subfolder "Subfolder" in a single primary folder 
%                               "Folder" ONLY: 
%                                   {'Subfolder', 'Folder'}
%                               However, if the primary folder root-word has multiples, the single
%                               subfolder will be created in each of them.
% 
%                               To create multiple numbered subfolders in a single primary folder:
%                                   {'Subfolder', 'Folder', [1 2 3]}
%                               Like the previous example, when the primary folder has multiples,
%                               this will create all of the subfolders in each of them.
% 
%                               To create specific sets of subfolders inside of a specific primary
%                               folder with multiples, use a cell array of vectors inside the
%                               parameter value string that is the same length as the primary folder
%                               number length. For example, if there are 3 primary folders with the
%                               same root-word "Folder" (e.g. "Folder 1-3"):
%                                   {'Subfolder', 'Folder', {[1 2] [1] [1 2 3]}}
% 
%                               DEFAULT: 'newFolder' (a single subfolder with this title will be
%                               created in every primary folder)
% 
%   Written by Josh Grooms on 20130116
%       20130117:   Updated to support spaces in folder names. 20130120:   Updated to check for the
%                   existence of the uppermost folder 
%       20130202:   Updated to allow creation of only a single folder level 
%       20130324:   Bug fix for upper folders with non-sequential numbers (second-level folders were 
%                   not being assigned properly). Also updated to include variable compatibility 
%                   from assignInputs.


%% Initialize
% Set the defaults
inStruct = struct(...
    'inPath', pwd,...
    'firstLevel', 'newFolder',...
    'secondLevel', 'newFolder');
assignInputs(inStruct, varargin,...
    'compatibility', {'inPath', 'path', 'dir';
                      'firstLevel', 'upperFolders', 'first';
                      'secondLevel', 'lowerFolders', 'second'},...
    {'firstLevel'; 'secondLevel'}, 'if ~iscell(varPlaceholder); varPlaceholder = {varPlaceholder}; end;',...
    {'inPath'}, 'regexprep(varPlaceholder, ''(\s$|\\$)'', '''')');

% Check to see if uppermost folder ("inPath") already exists
inPath = checkExisting(inPath, 'fileExt', 'dir');

% Condition the input variables
szFirstLevel = size(firstLevel);
szSecondLevel = size(secondLevel);
if szFirstLevel(2) ~= 2
    firstLevel = [firstLevel cell(szFirstLevel(1), (2 - szFirstLevel(2)))];
end
if szSecondLevel(2) ~= 3
    secondLevel = [secondLevel cell(szSecondLevel(1), (2 - szSecondLevel(2)))];
end
    
% Initialize the uppermost path for this function (input folderPath)
mkdir(inPath);


%% Build the First Level of Folders
% Initialize the first folder level of the output folder structure
firstVersions = cell(size(firstLevel, 1), 1);
for i = 1:size(firstLevel, 1)
    if ~isempty(firstLevel{i, 2})
        for j = 1:length(firstLevel{i, 2})
            currentPathStr = [inPath '\' firstLevel{i, 1} ' ' num2str(firstLevel{i, 2}(j))];
            currentFieldStr = regexprep(firstLevel{i, 1}, '\s', '');
            folderStruct.(currentFieldStr).(num2word(firstLevel{i, 2}(j))).root = currentPathStr;
            firstVersions{i}{j} = num2word(firstLevel{i, 2}(j));
            mkdir(currentPathStr);
        end
    else
        currentPathStr = [inPath '\' firstLevel{i, 1}];
        currentFieldStr = regexprep(firstLevel{i, 1}, '\s', '');
        folderStruct.(currentFieldStr).root = currentPathStr;
        mkdir(currentPathStr);
    end
end

% Garbage collect
clear current*

%% Build The Second Level of Folders
if ~isempty(secondLevel{1, 1})
    % Get the first level folder names
    firstFolders = fieldnames(folderStruct);
    for i = 1:size(secondLevel, 1)
        % If second level folder is matched with a first level, create these second level folders there only
        if ~isempty(secondLevel{i, 2})   
            % Second level folder matched to a specific first level folder
            secondMatchExpr = secondLevel{i, 2};
            matchedFolder = regexpi(firstLevel(:, 1), secondMatchExpr, 'match');
            idxFirstFolders = find(~cellfun(@isempty, matchedFolder));

        % Otherwise, subfolders are to be created in every primary folder
        else
            % Assign which folders to use below for primary folders
            idxFirstFolders = 1:length(firstFolders);
        end

        if ~isempty(secondLevel{i, 3})
            numSecondFolders = secondLevel{i, 3};
            currentSkipLoop = 0;
        else
            numSecondFolders = [];
            currentSkipLoop = 1;
        end

        for j = idxFirstFolders
            % Get the names of versions of first level folders
            currentFirstVersions = firstVersions{j};

            % If multiples of a primary folder exist...
            if ~isempty(currentFirstVersions)

                % Loop through each primary folder multiple
                for k = 1:length(currentFirstVersions)

                    % If multiple subfolders are going into multiples of the primary folder...
                    if ~currentSkipLoop

                        % If a cell is used to designate subfolders, get the current numbers from the primary folder index
                        if iscell(numSecondFolders)
                            currentFolderNums = numSecondFolders{k};
                        else
                            currentFolderNums = numSecondFolders;
                        end

                        % Loop though the subfolders indices & create them
                        for L = currentFolderNums
                            % Build the path string
                            currentPath = folderStruct.(firstFolders{j}).(currentFirstVersions{k}).root; 
                            currentAppendStr = [secondLevel{i, 1} ' ' num2str(L)];
                            currentPathStr = [currentPath '\' currentAppendStr];

                            % Assign the path string
                            currentFieldStr = regexprep(secondLevel{i, 1}, '\s', '');
                            folderStruct.(firstFolders{j}).(currentFirstVersions{k}).(currentFieldStr).(num2word(L)) = currentPathStr;
                            mkdir(currentPathStr);
                        end

                    % Otherwise, a single subfolder is going into the primary folder multiples
                    else
                        % Build the path string
                        currentPath = folderStruct.(firstFolders{j}).(currentFirstVersions{k}).root;
                        currentAppendStr = secondLevel{i, 1};
                        currentPathStr = [currentPath '\' currentAppendStr];

                        % Assign the path string
                        currentFieldStr = regexprep(secondLevel{i, 1}, '\s', '');
                        folderStruct.(firstFolders{j}).(num2word(k)).(currentFieldStr) = currentPathStr;
                        mkdir(currentPathStr);
                    end                                               
                end

            % If only a single primary folder exists & multiples of a subfolder are to be created...
            elseif ~currentSkipLoop            
                % Loop through the secondary folders
                for k = numSecondFolders
                    % Build the path string
                    currentPath = folderStruct.(firstFolders{j}).root;
                    currentAppendStr = [secondLevel{i, 1} ' ' num2str(k)];
                    currentPathStr = [currentPath '\' currentAppendStr];

                    % Assign the path string
                    currentFieldStr = regexprep(secondLevel{i, 1}, '\s', '');
                    folderStruct.(firstFolders{j}).(currentFieldStr).(num2word(k)) = currentPathStr;
                    mkdir(currentPathStr);
                end

            % Otherwise, a single subfolder is being created inside of a single primary folder
            else
                % Build the path string
                currentPath = folderStruct.(firstFolders{j}).root;
                currentAppendStr = secondLevel{i, 1};
                currentPathStr = [currentPath '\' currentAppendStr];

                % Assign the path string
                currentFieldStr = regexprep(secondLevel{i, 1}, '\s', '');
                folderStruct.(firstFolders{j}).(currentFieldStr) = currentPathStr;
                mkdir(currentPathStr);
            end
        end
    end
end
