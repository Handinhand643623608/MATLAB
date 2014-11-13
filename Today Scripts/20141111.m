%% 20141111 
dof = 61.04;


%% 1608 - 
% Log parameters
timeStamp = '201411111608';
analysisStamp = '';
dataSaveName = 'X:/Data/Today/20141111/201411111608 - ';

nullTimeStamp = '201410031844';
nullPath = Path('C:\Users\jgrooms\Desktop\Today Data\20141003');
nullFiles = nullPath.FileSearch(nullTimeStamp);

corrTimeStamp = '201411061742';
corrFiles = Today.FindFiles(corrTimeStamp);


nullData = nullFiles(1).Load();
corrData = corrFiles(1).Load();


nullFPz = nullData.FPz;
corrFPz = corrData.FPz.Correlation;

nullFPz = atanh(nullFPz) .* sqrt(dof);


%%

p = empiricalcdf(corrFPz, nullFPz);