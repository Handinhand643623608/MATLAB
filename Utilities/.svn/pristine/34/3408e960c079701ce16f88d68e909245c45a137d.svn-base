function u_aggregate_timeCourses(fileStruct, paramStruct)

%% Initialize
% Initialize function-specific parameters
if isempty(paramStruct.ICA.subjects)
    subjects = paramStruct.general.subjects;
    scans = paramStruct.general.scans;
else
    subjects = paramStruct.iCA.subjects
    scans = paramStruct.general.scans;
end
components = paramStruct.ICA.componentIdents;
componentNums = paramStruct.ICA.componentNums;

% Initialize the data storage structure
timeCourses(length(subjects), paramStruct.general.maxScans) = struct('data', [], 'info', []);

% Get a list of the time course data files
timeCourseFilenames = u_CA_filenames(fileStruct.paths.timeCourses, 'RSN', 'img');

%% Aggregate the Time Courses
imgCount = 1;
for i = subjects
    for j = scans{i}
        
        % Load the current subject & scan IMG file
        currentData = load_nii(timeCourseFilenames{imgCount});
            imgCount = imgCount + 1;
        
        % Condition the data & flip around first dimension (GIFT stores waveforms this way for some reason...)
        currentData = double(currentData.img);
        currentData = flipdim(currentData, 1);
        
        % Store the network time courses in the output structure
        componentCount = 1;
        for k = componentNums
            timeCourses(i, j).data.(components{componentCount}) = currentData(:, k);
                componentCount = componentCount + 1;
        end
        
        % Fill in the information section of the structure
        timeCourses(i, j).info = struct(...
            'subject', i,...
            'scan', j,...
            'componentIdents', {components});
        
    end
end

save([fileStruct.paths.MAT_files '\BOLD\timeCourses_RSN_20_noGR.mat'], 'timeCourses', '-v7.3')
        