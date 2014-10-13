%% 20140709 


%% 1616 - Repairing BOLD Data Object MATFILE Associations
% These were broken when I had to transplant data after the SSD on the lab computer failed.

boldObjectFiles = Search(Paths, 'BOLD', 'boldObject');
boldDataFiles = Search(Paths, 'BOLD', 'boldData');

for a = 1:length(boldObjectFiles)
    load(boldObjectFiles{a});
    boldData.Data = matfile(boldDataFiles{a});
    save(boldObjectFiles{a}, 'boldData', '-v7.3');
end