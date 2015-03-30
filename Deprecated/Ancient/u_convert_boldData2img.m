function u_convert_boldData2img(fileStruct, paramStruct, varargin)

%% Initialize
switch length(varargin)
    case 0
        subjects = paramStruct.general.subjects;
        scans = paramStruct.general.scans;
    case 1
        subjects = varargin{1};
        scans = paramStruct.general.scans;
    case 2
        subjects = varargin{1};
        scans = varargin{2};
    otherwise
        error('Improper number of input arguments');
end

% Initialize an output folder structure for IMG files
savePaths = u_create_folders('GIFT IMG Files', fileStruct.paths.preprocessed, subjects, scans);

%% Convert the MAT Data Files to IMG Files for ICA or SPM
for i = subjects
    
    % Load the BOLD data to be converted
    load(['BOLD_data_subject_' num2str(i) '_noGR.mat']);    
    
    for j = scans{i}
        
        % Get the current scan's data
        currentBOLD = BOLD_data.BOLD(j).functional;
        
        % Initialize an index for counting images
        m = 1;
        
        for k = 1:size(currentBOLD, 4)
            
            % Get the current image to be converted
            currentImage = currentBOLD(:, :, :, k);
            currentImage = double(currentImage);
            currentImage(isnan(currentImage)) = 0;
            
            % Convert the current image to IMG format
            currentImageFilename = sprintf('%03d.img', m);
                m = m + 1;
            currentImageDir = [savePaths{i}{j} '\' currentImageFilename];
            u_convert_mat2img(currentImageDir, currentImage, 'double', [2 2 2], size(currentImage));
            
        end
    end
end
            
        
        