function dataStruct = dataStructImportDCM(dataStruct)
%DATASTRUCTIMPORTDCM Imports anatomical & mean DICOM image files for processing.
%   This function is a re-write of Garth Thompson's "dataobject_dicom_import" function used in human
%   fMRI data preprocessing. It is written to be more efficient, less error-prone, and removes a
%   number of extraneous options that were never used.
%
%   SYNTAX:
%   dataStruct = dataStructDicomImport(dataStruct)
%
%   OUTPUT:
%   dataStruct:     The data structure with imported DICOM files & references.
%
%   INPUT:
%   dataStruct:     The input human data structure.
%
%   Written by Josh Grooms on 20130628


%% Initialize
% Get values from the data structure
meanDicomFile = dataStruct.Files.MeanDicom;
anatomicalFolder = dataStruct.Files.AnatomicalFolder;
imgFolder = dataStruct.Files.IMGFolder;

% Determine whether or not folders need clearing
anatomicalLogFile = [anatomicalFolder 'anatomical_import.txt'];
if exist(anatomicalLogFile, 'file')
    error('Junk data present in data folders. Run "cleanRawFolders" before preprocessing')
end

% Import the anatomical data
anatomicalFiles = get(fileData(anatomicalFolder, 'ext', '.dcm'), 'Path');

% Get anatomical & mean image information
anatomicalInfo = dicominfo(anatomicalFiles{1});
meanInfo = dicominfo(meanDicomFile);


%% Import DICOM Files
% Setup SPM batch processing
matlabbatch{1}.spm.util.dicom = struct(...
    'convopts', struct(...
        'format', 'img',...
        'icedims', 0),...
    'data', {[anatomicalFiles; {meanDicomFile}]},...
    'outdir', {{imgFolder}},...
    'root', 'flat');

% Run the SPM batch
outData = spm_jobman('run', matlabbatch);

% Match data based on series numbers
[~, outName, ~] = cellfun(@(x) fileparts(x), outData{1}.files, 'UniformOutput', false);
currentSNs = regexp(outName, '-(\d\d\d\d)-', 'tokens');
currentSNs = cat(1, currentSNs{:}); 
currentSNs = cellfun(@(x) eval(x), cat(1, currentSNs{:}));
try
    dataStruct.Files.IMG.Anatomical = outData{1}.files{anatomicalInfo.SeriesNumber == currentSNs};
    dataStruct.Files.IMG.Mean = outData{1}.files{meanInfo.SeriesNumber == currentSNs};
catch
    error('Problem locating output files from DICOM import. Structrual or mean missing');
end
    

%% Save a Log for the Anatomical Data
anatomicalLogID = fopen(anatomicalLogFile, 'w');
fprintf(anatomicalLogID, '%s\n', dataStruct.Files.IMG.Anatomical);
fclose(anatomicalLogID);