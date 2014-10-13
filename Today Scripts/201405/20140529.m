%% 20140529 


%% 1512 - Investigating Outputs from ICA on Combined BOlD-FPz/C3 SWPC Volumes


% Interpreting ICA Aggregate Data Folder 
% FPz and C3 data were combined to faciliate the use of ICA & ensure consistent decomposition of the
% data (needed for drawing comparisons between "equivalent" components later on). Inside this
% folder, any directories named without dashes (e.g. 1) are data from BOLD-FPz SWPC volumes. The
% remaining directories with dashes in their names (e.g. 1-1) are data from the BOLD-C3 SWPC.

load masterStructs;
icaPath = [fileStruct.Paths.Desktop '/ICA Aggregate Output'];
swcPath = [fileStruct.Paths.Desktop '/SWC Data'];
idxBG = 2;
idxSalience = 4;
idxDMN = 8;
idxPVN = 9;
idxTPN = 11;
idxSMN = 16;
idxLLN = 17;
idxRLN = 20;
idxLVN = 22;
idxPrecuneus = 24;


% Every odd-numbered file is from FPz SWPC series, while even-numbered files are from C3 data
tcFiles = get(fileData(icaPath, 'search', 'RSN_sub..._timecourses'), 'Path');

rsnFPZCoupling(17) = struct(...
    'DMN', [],...
    'TPN', []);
rsnC3Coupling = rsnFPZCoupling;

% Look at FPz data first
fpzFiles = 1:2:length(tcFiles);
for a =  1:length(fpzFiles);
    currentData = load_nii(tcFiles{fpzFiles(a)});
    currentData = flipdim(currentData.img, 1);
    
    % Get the DMN & TPN data only for now
    rsnFPZCoupling(a).DMN = currentData(:, idxDMN)';
    rsnFPZCoupling(a).TPN = currentData(:, idxTPN)';
end

% Now get the C3 data
c3Files = 2:2:length(tcFiles);
for a = 1:length(c3Files)
    currentData = load_nii(tcFiles{c3Files(a)});
    currentData = flipdim(currentData.img, 1);
    
    rsnC3Coupling(a).DMN = currentData(:, idxDMN)';
    rsnC3Coupling(a).TPN = currentData(:, idxTPN)';
end
