function u_convert_humanData(fileStruct, paramStruct, subjects, scans)

humanDataFilenames = u_filenames([fileStruct.paths.MAT_files '\BOLD\No Global Regression\'], 'human_data_', 'mat');
% load EEG_data_raw

if nargin == 2
    subjects = paramStruct.general.subjects;
    scans = paramStruct.general.scans;
end

progressbar('Files Converted', 'Scans Converted')
for i = subjects
    
    load(humanDataFilenames{i})
%     loadStr = ['BOLD_data_subject_' num2str(i) '.mat'];
%     if ~exist([fileStruct.paths.MAT_files '/BOLD/' loadStr])
        BOLD_data = f_CA_initialize_datastruct('BOLD', paramStruct, i, scans{i});
%     else
        load(['BOLD_data_subject_' num2str(i) '.mat'])
%     end
    
    progressbar([], 0)
    for j = scans{i}
        
        BOLD_data.BOLD(j).functional = human_data.data.bold{j};
        BOLD_data.BOLD(j).mean = human_data.data.mn{j};
        BOLD_data.anatomical = human_data.data.anatomical{j};
        BOLD_data.masks.WM = human_data.data.roi{j}(:, :, :, 1);
        BOLD_data.masks.GM = human_data.data.roi{j}(:, :, :, 2);
        BOLD_data.masks.CSF = human_data.data.roi{j}(:, :, :, 3);
%         EEG_data(i, j).data.EEG = human_data.data.ephys{j};
%         if paramStruct.preprocess.EEG.has_BCG(i)
%             if i < 5
%                 EEG_data(i, j).data.BCG = human_data.data.ephys{j}(61, :);
%                 EEG_data(i, j).data.EEG(61, :) = [];
%             else
%                 EEG_data(i, j).data.BCG = human_data.data.ephys{j}(69, :);
%                 EEG_data(i, j).data.EEG(69:70, :) = [];
%             end
%         end

    progressbar([], j/length(scans{i}))
    end
    
    save([fileStruct.paths.MAT_files '/BOLD/BOLD_data_subject_' num2str(i) '_noGR.mat'], 'BOLD_data', '-v7.3')
%     save([fileStruct.paths.MAT_files '/EEG/EEG_data_raw.mat'], 'EEG_data', '-v7.3')
    clear BOLD_data human_data
    
    progressbar(i/length(subjects), [])
end

