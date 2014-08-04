classdef corrObj < relationObj
    %CORROBJ Generates a standardized correlation data object.
    %   This class contains correlation data objects that compare EEG and fMRI modalities. Calls to
    %   this object run correlations between the data based on user inputs. This class also has
    %   defined methods for averaging, null distribution generation, statistical thresholding, and
    %   plotting of the data. 
    %
    %   The easiest way to use this object is to gather all input parameters using the PARAMETERS
    %   method. This way, a structure of all available inputs can be easily modified from default
    %   values and then supplied to the object at the time of instantiation.
    %   
    %   To gather input parameters, type the following ("corrObj" must be entered verbatim):
    %       paramStruct = parameters(corrObj)
    %
    %   Make the necessary changes to the parameter structure's various fields. A description of
    %   each variable in the structure can be found below. Then, when you are ready to run
    %   correlation between the data, type the following:
    %       corrParams = struct2var(paramStruct)   % Converts structure to a cell array
    %       corrData = corrObj(corrParams{:})      % Runs correlation with user inputs
    %
    %   SYNTAX: 
    %       corrData = corrObj('PropertyName', PropertyValue,...)
    %       corrData = corrObj(corrParams{:})
    %
    %   OUTPUTS:
    %   corrData:           A data object array containing correlations between EEG and fMRI data
    %                       for every subject and scan. This array is of size M-by-N, where M is the
    %                       number of subjects, and N is the maximum number of scans for all
    %                       subjects. 
    %                       WARNING: Certain elements of this array may be empty if some subjects
    %                                have more scans than others.
    %
    %   INPUTS:
    %
    %   'BOLDGSR':          A boolean indicating whether or not the BOLD data being used should have
    %                       its global signal regressed. This object does not perform any global
    %                       signal regression; this paramter is used to select the appropriate
    %                       parent data for correlation.
    %
    %   'EEGGSR':           A boolean indicating whether or not the EEG data being used should have
    %                       its global signal regressed. This object does not perform any global
    %                       signal regression; this paramter is used to select the appropriate
    %                       parent data for correlation.
    %
    %   OPTIONAL INPUTS:
    %   'Bandwidth':        A two-element vector indicating the passband of both the EEG and fMRI
    %                       data in Hertz. This object does not perform any filtering; this
    %                       parameter is used to select the appropriate parent data for correlation.
    %                       DEFAULT: [0.01 0.08]
    %
    %   'Modalities':       A string indicating which two modalities (separated by a hyphen) are to
    %                       be correlated together. This option is fairly flexible, and ordering
    %                       within the string is not important. This is also case insensitive.
    %                       DEFAULT: 'BOLD-EEG'
    %                       OPTIONS (any from the fMRI category with any from the EEG):
    %                           fMRI Category:
    %                               'BOLD' OR 'fMRI'
    %                               'BOLDGlobal' OR 'BOLDGS'
    %                               'IC'
    %                               'Nuisance'
    %
    %                           EEG Category:
    %                               'BLP'
    %                               'EEG'
    %                               'EEGGlobal' OR 'EEGGS'
    %
    %   'Relation':         A string indicating what type of correlation is to be run on the data.
    %                       DEFAULT: 'Correlation'
    %                       OPTIONS:
    %                           'Correlation'
    %                           'Partial Correlation'
    %                           'Sliding Window Correlation'
    %
    %   'ScanState':        A string indicating what state the data are in. This is used to select
    %                       the appropriate parent data for correlation.
    %                       DEFAULT: 'RS'
    %                       OPTIONS:
    %                           'RS'    - Resting state data
    %                           'PVT'   - Psychomotor vigilance task data
    %
    %   ANALYSIS PARAMETERS (Input these as a structure after the name 'Parameters')
    %   'Channels':         A cell array of EEG electrode strings indicating which channels to use
    %                       in the correlation analysis. If running certain correlations (e.g.
    %                       EEG-IC or EEG-Nuisance), this parameter is not used as all available
    %                       electrodes are included in the analysis.
    %
    %   'Fs':               The sampling frequency of both the fMRI and EEG data in Hertz. This
    %                       function does not perform any filtering; this parameter is used to
    %                       convert between time lags and sample lags. 
    %                       DEFAULT: 0.5
    %
    %   'GenerateNull':     A boolean dictating whether or not to generate a null distribution of
    %                       correlation values between modalities by mismatching pairs of data. The
    %                       null distribution is comprised of every possible data set mismatch
    %                       between subjects and scans, thus breaking any phase-locking that would
    %                       be expected to arise from coherent EEG and fMRI data.
    %                       DEFAULT: false
    %   
    %   'Mask':             A mask to be applied to the fMRI data prior to correlation. Using this
    %                       can dramatically reduce computational load and processing times. Specify
    %                       this input as a string (case insensitive).
    %                       DEFAULT: []
    %                       OPTIONS:
    %                           'gray' OR 'grey' OR 'gm'
    %                           'white' OR 'wm'
    %                           'csf'
    %
    %   'MaskThreshold':    The threshold for the data mask. Any mask values above this cutoff are
    %                       used, blocking equivalent fMRI image regions from analysis.
    %                       DEFAULT: []
    %
    %   'Scans':            A cell array of scans vectors dictating which specific scans are to be
    %                       included in the correlation analysis. This parameter also accepts an
    %                       input of 'all', which will include all available scans.
    %                       DEFAULT: 'all'
    %                       EXAMPLE: 
    %                           {[1 2] [1] [2 3]...} - Scans 1-2 from subject 1, scan 1 from
    %                                                    subject 2, scans 2-3 from subject 3
    %
    %   'Subjects':         A vector of integers dictating which specific subjects to include in the
    %                       correlation analysis. This parameter also accepts an input of 'all',
    %                       which will include all available subjects.
    %                       DEFAULT: 'all'
    %                       EXAMPLE:
    %                           [1 2 5 7 9] - Uses only subjects 1, 2, 5, 7, 9
    %   
    %   SIGNIFICANCE THRESHOLDING (Input these as a substructure of 'Parameters' called 'Thresholding')
    %   'AlphaVal':         The significance threshold, or Type I error rate for hypothesis testing
    %                       during the assessment of significance.
    %                       DEFAULT: 0.01
    %   
    %   'CDFMethod':        The method for converting data from correlation values into p-values.
    %                       DEFAULT: 'arbitrary'
    %                       OPTIONS:
    %                           'arbitrary'
    %
    %   'FWERMethod':       The method of correction for multiple comparisons (FWER).
    %                       DEFAULT: 'sgof'
    %                       OPTIONS:
    %                           'sgof'
    %   
    %   'Parallel':         A boolean or string indicating whether or not MATLAB parallel processing
    %                       should be used in the generation of p-values. For very large data sets
    %                       and arbitrary p-value generation, turning htis on can significantly cut
    %                       down computation time.
    %                       DEFAULT: 'off'
    %                       OPTIONS:
    %                           'on' OR true
    %                           'off' OR false
    %                       WARNING: this functionality has not yet been implemented.
    %   
    %   'Tails':            A string that indicates on which side of the null distribution to look
    %                       for statistical significance.
    %                       DEFAULT: 'both'
    %                       OPTIONS:
    %                           'upper' OR 'higher' OR 'h'  - One-tailed hypothesis test from upper side
    %                                                         of the null distribution.
    %                           'lower' OR 'l'              - One-tailed hypothesis test from lower side
    %                                                         of the null distribution.
    %                           'both' OR 'all'             - Two-tailed hypothesis test from both sides
    %                                                         of the null distribution.
    %   
    %
    %   Written by Josh Grooms on 20130702
    %       20130728:   Implemented partial correlation for EEG-BOLD relationships (with BOLD
    %                   nuisance parameters as the controlling variables)
    %       20130811:   Implemented Fisher's normalized r-to-z transformation to prevent bias 
    %                   introduced during the averaging of correlation coefficients.
    
    
    % TODO: Implement single-subject plotting.
    % TODO: Implement parallel processing.
    % TODO: Implement sliding window correlation.
    % TODO: Implement outputs to HDF5 data sets.
    % TODO: Implement data masking capabilities.
    % TODO: Implement coding for correlation between all possible modalities.
        
    
    %% Constructor Method
    methods
        function corrData = corrObj(ccStruct)
            %CORROBJ Constructs the correlation data object using the various input parameters.
            if nargin ~= 0
                corrData = initialize(corrData, ccStruct);
                switch lower(ccStruct.Initialization.Relation)
                    case 'correlation'
                        correlation(corrData);
                    case 'partial correlation'
                        partialCorrelation(corrData);
                end
            end        
        end
    end
    
    
    %% Public Methods
    methods
        % A method for masking MRI data
        maskedData = mask(boldData, maskData, confPct, replaceWith);
        % Average the data together
        meanCorrData = mean(corrData)
        % A method for returning a parameter structure with default values
        paramStruct = parameters(corrData);
        % Display the data
        varargout = plot(corrData, varargin)
        % Store the data
        store(corrData, varargin)
        % Threshold the data for significance
        threshold(meanCorrData, meanNullData)
    end
    
    
    %% Static Public Methods
    methods (Static)
       % Fisher's normalized r-to-z transform
       z = transform(r, n);
    end
    
    
    %% Protected Methods
    methods
        % Evaluate correlation between the data
        correlation(corrData)
        % Initialize the data object
        corrData = initialize(corrData, varargin)
        % Evaluate partial correlation between the data
        partialCorrelation(corrData)
    end
end
        