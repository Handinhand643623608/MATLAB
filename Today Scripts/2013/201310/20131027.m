%% 20131027

%% 1708
% Convert BOLD data to IMG files for ICA
load masterStructs
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', 'dcZ'), 'Path');

for a = 1:length(boldFiles)
    load(boldFiles{a});
    convertToIMG(boldData);
end

icaOutputFolder = ['E:\Graduate Studies\Lab Work\Data Sets\ICA Results\20131027 - GIFT Analysis Files (20 ICs, RS, DC, No GR)'];
mkdir(icaOutputFolder);


%% 1714 - Make a Mean IMG File for Masking (Forgot to Do This Earlier)
load masterStructs
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', 'dcZ'), 'Path');
imgSetFolder = 'E:\Graduate Studies\Lab Work\Data Sets\20130127 - GIFT IMG Files (RS, DC, No GR)';
imgFolders = get(fileData(imgSetFolder, 'Folders', 'on'), 'Path');

for a = 1:length(boldFiles)
    load(boldFiles{a})
    
    for b = 1:length(boldData)
        meanFileName = [imgFolders{a} '/Scan ' num2str(b) '/Mean.img'];
        writeimg(meanFileName, boldData(b).Data.Mean, 'double', [2 2 2], size(boldData(b).Data.Mean));
    end
end


%% 1942 - Identify IC Networks
componentIDs = {...
    'Unknown',...                1: A weird looking network that consistently shows up in all my data
    'Executive',...              2: 
    'Cerebellum',...             3: 
    'DAN',...                    4: Dorsal attention network
    'Precuneus',...              5: 
    'Salience',...               6: 
    'CSF',...                    7: Could be CSF (activity in median fissure & in empty spaces)
    'ACC',...                    8: Could be anterior cingulate cortex
    'RLN',...                    9: Right lateral network
    'BG',...                    10: I think this is basal ganglia
    'Auditory',...              11: Could be auditory, but active areas seem too large
    'WM',...                    12: White matter signal
    'DMN',...                   13: Default mode network
    'PCC',...                   14: Could be posterior cingulate cortex?
    'PVN',...                   15: Primary visual network
    'LVN',...                   16: Lateral visual network
    'Unknown',...               17: Medial-ventral activity, mostly (could be another executive)
    'Noise',...                 18: Looks like noise
    'SMN',...                   19: Sensorimotor network
    'LLN',...                   20: Left lateral network
    };
    

%% 2112 - Reading Anatomical Labels from xjview (Using AAL Library)
componentIDs = {...
    'Unknown1',...               1: Precuneus, middle frontal gyrus (bilateral)
    'Executive',...              2: Superior frontal gyrus (bilateral), anterior cingulate cortex
    'Cerebellum',...             3: Cerebellum, brain stem structures
    'DAN',...                    4: Dorsal attention network (postcentral gyrus, superior & inferior parietal cortices)
    'Precuneus',...              5: Precuneus & PCC
    'Salience',...               6: Inferior frontal gyrus (bilateral), middle temporal gyrus (bilateral), superior frontal gyrus (midline), medial frontal gyrus, 
    'CSF',...                    7: Cerebellar vermis, CSF spaces
    'ACC',...                    8: Anterior cingulate cortex, middle frontal gyrus, superior frontal gyrus, 
    'RLN',...                    9: Middle frontal gyrus (right), precuneus (right), inferior frontal gyrus (right), superior frontal gyrus (right)
    'BG',...                    10: Putamen (bilateral), caudate nucleus (bilateral)
    'Auditory',...              11: Superior temporal gyrus (bilateral)
    'WM',...                    12: White matter structures
    'DMN',...                   13: Superior frontal gyrus (bilateral), medial frontal gyrus, anterior cingulate cortex, posterior cingulate cortex, middle temporal gyrus (bilateral), angular gyrus (bilateral)
    'PCC',...                   14: Posterior cingulate, possible anterior-superior cerebellum
    'PVN',...                   15: Lingual gyrus, cuneus
    'LVN',...                   16: Inferior/middle occipital gyrus (bilateral), fusiform gyrus (bilateral), 
    'Unknown2',...              17: Caudate nucleus (bilateral), lenticular nucleus (bilateral), ACC, inferior frontal gyrus (bilateral), medial frontal gyrus, putamen (bilateral)
    'Noise',...                 18: White matter structures, superior temporal gyrus (bilateral), amygdala (bilateral), hippocampus (bilateral), 
    'SMN',...                   19: Precentral gyrus, postcentral gyrus, supplementary motor area, 
    'LLN',...                   20: Inferior parietal lobe (left), middle frontal gyrus (left), medial frontal gyrus, angular gyrus (left), 
    };


%% 2222 - Reading in time courses
% Get DC BOLD data files
load masterStructs
boldFiles = get(fileData([fileStruct.Paths.DataObjects '/BOLD'], 'Search', 'dcZ'), 'Path');

% Get the ICA data files
icaPath = 'E:\Graduate Studies\Lab Work\Data Sets\ICA Results\20131027 - GIFT Analysis Files (20 ICs, RS, DC, No Nuisance Regressions)\IC Time Courses';
icaFiles = get(fileData(icaPath, 'ext', 'img'), 'Path');

progBar = progress('Appending ICA Data to BOLD Objects');
for a = 1:length(boldFiles)
    % Load the appropriate BOLD data set
    load(boldFiles{a})
    
    for b = 1:2     % <--- Unfortunately, GIFT doesn't ever produce a time course for subject 6, scan 3
        
        % Import ICA data from the .img files & flip along time dimension (GIFT stores these weirdly)
        icaData = load_nii(icaFiles{1});
            icaFiles(1) = [];
        icaData = icaData.img;
        icaData = flipud(icaData);
        
        % Add time course data to the BOLD data object
        for c = 1:length(componentIDs)
            boldData(b).Data.ICA.(componentIDs{c}) = icaData(:, c)';
        end
    end
    
    store(boldData)
    clear boldData
    update(progBar, a/length(boldFiles));
end     


%% 0002 - Partial Cross Correlation between RSNs & EEG (No EEG CSR)
% Setup correlation parameters
ccStruct = struct(...
    'Initialization', struct(...
        'Bandwidth', {{[0.01 0.08], [0.01 0.08]}},...
        'GSR', [false false],...
        'Modalities', 'RSN-EEG',...
        'Relation', 'Partial Correlation',...
        'ScanState', 'RS'),...
    'Correlation', struct(...
        'Control', 'BOLD Nuisance',...
        'Channels', [],...
        'Fs', 0.5,...
        'GenerateNull', false,...
        'Mask', [],...
        'MaskThreshold', [],...
        'Scans', {{[1 2] [1 2] [1 2] [1 2] [1 2] [1 2] [1 2] [1 2]}},...      % <--- No ICA time courses for subject 6 scan 3
        'Subjects', [1:8],...
        'TimeShifts', [-20:2:20]),...
    'Thresholding', struct(...
        'AlphaVal', 0.05,...
        'CDFMethod', 'arbitrary',...
        'FWERMethod', 'sgof',...
        'Mask', [],...
        'MaskThreshold', [],...
        'Parallel', 'gpu',...
        'Tails', 'both'));
corrData = corrObj(ccStruct);
store(corrData)


%% 1249 - Threshold The Partial Correlations
load partialCorrObject_RS_RSN-EEG_dcZ_20131028;
meanCorrData = mean(corrData);
store(meanCorrData);
clear corrData
threshold(meanCorrData);
