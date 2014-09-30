function Preprocess(params)
%PREPROCESS - Preprocesses raw BOLD data & stores output in a BOLD human data object. 
%
%   SYNTAX:
%   boldObj.Preprocess
%   boldObj.Preprocess(paramStruct)
%
%   OPTIONAL INPUT:
%   paramStruct:    STRUCT
%                   The preprocessing parameter structure, which is an aggregation of all parameters and user input
%                   needed to autonomously import, preprocess, and store raw BOLD functional data. 

%% CHANGELOG
%   Written by Josh Grooms on 20130707
%       20130710:   Changed method names to be more concise and easily understood. Combined the two separate mean image
%                   methods into one. Implemented storage of raw (unconditioned) BOLD data so later changes in
%                   conditioning don't have to invoke the whole preprocessing algorithm.
%       20130711:   Updated so that user can control object output path through parameter structure input. Updated
%                   inputs to CLEANRAWFOLDERS so that this function can work with different data sets. Implemented a
%                   "Large Data" switch that saves each individual scan to the hard disk, clears it out before
%                   processing another, then aggregates all scans together at the end.
%       20130716:   Updated the aggregating function (for large data sets) to work correctly when requested scans are 
%                   not sequential.
%       20130730:   Implemented ability to convert objects into human_data structures.
%       20130803:   Updated for compatibility with updated progress bar code.
%       20140612:   Updated the documentation for this method.
%       20140702:   Changed object storage to always save a new data object per individual scan processed. Saving arrays 
%                   of data objects is now completely unsupported. This helps keep the size of data sets more
%                   manageable, lowers the RAM requirements for this procedure, and makes it much less costly if errors
%                   occur in the middle of processing a subject.
%       20140721:   Implemented SPM motion correction and turned off slice-timing correction (temporarily). Now Linux is
%                   no longer required to run BOLD preprocessing. STC is currently not needed because my data are
%                   already preprocessed and the Schumacher lab data has a TR of 700 ms, which is plenty fast to forgo
%                   that step. STC will be an optional stage in the next revision of this software. This also allowed me
%                   to delete the mean dicom generation function, since this is done in SPM motion correction
%                   automatically.
%       20140829:   Converted this function into a static method of the BOLD data object class.
%       20140929:   Major overhaul of this function to work with the preprocessing parameter structure overhaul.


%% TODOS
% Immediate Todos
% - Implement skipping of unnecessary anatomical segmentations
% - Hide SPM & AFNI echoing
% - Implement ability to choose AFNI or SPM for motion correction
%   > Save reference to motion parameters file for use in PrepCondition
%
% Future Todos
% - Implement parallel data preprocessing
%   > Not likely to happen soon because of RAM requirements



%% Initialize
% Get the default preprocessing parameter structure if a custom one isn't provided
if nargin == 0; params = boldObj.PrepParameters; end

% Clean out any previous preprocessed data in the raw data folders
boldObj.CleanRawFolders(...
    params.DataPaths.RawDataPath,...
    'AnatomicalFolderStr', params.DataFolderIDs.AnatomicalFolderID,...
    'FunctionalFolderStr', params.DataFolderIDs.FunctionalFolderID,...
    'SubjectFolderStr', params.DataFolderIDs.SubjectFolderID);

% Set progress bar parameters
numSteps = 8;



%% Preprocess Raw BOLD Data
progBar = progress('', '', '');
for a = params.DataSelection.SubjectsToProcess
    
    progBar.BarTitle{1} = ['Processing Subject ' num2str(a)];
    reset(progBar, 2)
    
    for b = params.DataSelection.ScansToProcess{a}
        
        progBar.BarTitle{2} = ['Processing Scan ' num2str(b)];
        reset(progBar, 3)
        
        % [ TESTED ] Initialize a new BOLD data object & fill in known object properties
        boldData = boldObj;
        boldData.Subject = a;
        boldData.Scan = b;
        boldData.ScanState = params.DataSelection.ScanState;
        boldData.Preprocessing = params;
        boldData.SoftwareVersion = boldObj.LatestVersion;
        
        % [ TESTED ] Initialize file & folder references in the data object
        progBar.BarTitle{3} = 'Importing Acquisition Data';
        PrepInitialize(boldData);
        update(progBar, 3, 1/numSteps);
                
        % [ TESTED ] Convert DICOM functional files to NIFTI format
        progBar.BarTitle{3} = 'Converting DICOM Images to NIFTI Format';
        PrepDCMToIMG(boldData);
        update(progBar, 3, 2/numSteps);
        
        % [ TESTED ] Segment the anatomical image
        progBar.BarTitle{3} = 'Segmenting Anatomical Data';
        PrepSegment(boldData);
        update(progBar, 3, 3/numSteps);
        
        % [ TESTED ] Correct for subject motion during scanning
        progBar.BarTitle{3} = 'Correcting Motion Artifacts';
        PrepMotion(boldData);
        update(progBar, 3, 4/numSteps);
        
        % [ TESTED ] Register functional images to anatomical images
        progBar.BarTitle{3} = 'Registering Functional to Anatomical Images';
        PrepRegister(boldData);
        update(progBar, 3, 5/numSteps);
        
        % [ TESTED ] Normalize data to MNI space
        progBar.BarTitle{3} = 'Normalizing to MNI Space';
        PrepNormalize(boldData);
        update(progBar, 3, 6/numSteps);
        
        % [TESTED ] Import IMG files to MATLAB workspace
        progBar.BarTitle{3} = 'Importing IMG Files into MATLAB Workspace';
        PrepImportIMG(boldData);
        update(progBar, 3, 7/numSteps);
        
        % Store temporary files at this point so alterations in conditioning can easily occur later
        rawStoreName = sprintf('boldObject-%d-%d_%s_raw.mat', a, b, params.DataSelection.ScanState);
        Store(boldData, 'Name', rawStoreName, 'Path', OutputPath);

        % Condition the BOLD signals for analysis
        progBar.BarTitle{3} = 'Conditioning BOLD Time Series Data';
        PrepCondition(boldData);
        update(progBar, 3, 8/numSteps);
        
        % Store the BOLD data object 
        if istrue(ConvertToStructure)
            boldStruct = ToStruct(boldData);
            saveNameStr = sprintf('%s/boldStruct-%d-%d_%s_%s.mat', OutputPath, a, b, ScanState, datestr(now, 'yyyymmdd'));
            save(saveNameStr, 'boldStruct', '-v7.3');
            clear boldStruct;
        else
            Store(boldData, 'Path', OutputPath);
        end
        clear boldData;
                
        update(progBar, 2, b/length(Scans{a}));
    end
    update(progBar, 1, find(Subjects == a)/length(Subjects));
end
close(progBar);