%% 20140627 



%% 1715 - Refactoring BOLD Data Objects into Individual Scans & Implementing MATFILE Functionality on Data
% Today's parameters
load masterStructs;
timeStamp = '201406271715';
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', '_dcZ'), 'Path');

% 
pbar = progress('Refactoring BOLD Data Objects');
for a = 1:1 %length(boldFiles)
    load(boldFiles{a})
    
    for b = 1:length(boldData);
        Store(boldData(b), 'Path', [fileStruct.Paths.DataObjects '/BOLD']);
    end
    update(pbar, a/length(boldFiles));
end
close(pbar);