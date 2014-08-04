%% 20140702 


%% 1100 - 
% Today's parameters
timeStamp = '201407021100';

dcmFiles = get(fileData([get(Paths, 'Raw') '/101A_20110615/ep2d_RUN_1_Rest_6'], 'search', '\d\d\d\d\d', 'ext', '.dcm'), 'Path');

sub1 = [];
for a = 1:length(dcmFiles)
    sub1 = cat(3, sub1, dicomread(dcmFiles{a}));
end


sub1 = reshape(sub1, [], size(sub1, 3));
sub1 = nanmean(sub1, 1);

figure; plot(sub1);