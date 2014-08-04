function varargout = threshold(realData, nullData, varargin)
%THRESHOLD Provides cutoffs in data units for statistical significance.
%   This function thresholds input data for statistical significance. It is capable of using several
%   methods for computation of p-values and FWER correction, depending on user input. 
%
%   SYNTAX:
%   cutoff = threshold(realData, nullData, 'PropertyName', PropertyValue...)
%   [lowerCutoff, upperCutoff] = threshold(realData, nullData, 'PropertyName', PropertyValue...)
%
%   OUTPUTS:
%   cutoff:             The scalar cutoff (in input data units) above or below which the input data
%                       is significant. Direction (higher or lower) of statistical significance is
%                       determined by the user inputs for the "Tails" parameter. If no significance
%                       threshold is found, "NaN" is returned. 
%
%   lowerCutoff:        The scalar cutoff (in input data units) below which the input data is
%                       significant. If no significance threshold is found, "NaN" is returned.
%
%   upperCutoff:        The scalar cutoff (in input data units) above which the input data is
%                       significant. If no significance threshold is found, "NaN" is returned.
%
%   INPUTS:
%   realData:           The data array containing real tested measurements. This argument can be an
%                       array of any size or dimensionality, but must be numerical.
%
%   nullData:           The data array containing null measurements or distribution values. This
%                       argument can be an array of any size or dimensionality, but must be
%                       numerical and should be much larger than the real data set.
%
%   OPTIONAL INPUTS:
%   'Alpha':            The significance threshold, or Type I error rate for hypothesis testing. 
%                       DEFAULT: 0.05
%
%   'CDFMethod':        The method for converting data from data units into p-values.
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
%                       should be used in the generation of p-values. For very large data sets and
%                       arbitrary p-value generation, turning this on can significantly cut down
%                       computation time.
%                       DEFAULT: 'off'
%                       OPTIONS:
%                           'CPU' OR 'on'   - Engage multiple CPUs in p-value generation. This is
%                                             the second fastest option and will save a significant
%                                             amount of time compared to single-CPU usage. Even so,
%                                             this option is extremely slow compared to using a GPU
%                                             for processing.
%                           'GPU'           - Engage the graphics card in p-value generation. This
%                                             will process data the fastest of all parallel options.
%                                             Only use if you have a CUDA-capable NVIDIA graphics
%                                             card. 
%                           'off' OR false  - Generate p-values using only a single core CPU. This
%                                             is very slow and may require days or possibly weeks 
%                                             for large data sets.
%
%   'Tails':            A string that indicates on which side of the null distribution to look for
%                       statistical significance. 
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
%   Written by Josh Grooms on 20130627
%       20130628:   Updated to allow for outside input of variable structure.
%       20130702:   Updated to prevent input of incorrect data.
%       20130712:   Implemented parallel processing.
%       20130715:   Implemented GPU processing for massive speed gains during arbitrary p-value 
%                   generation. Updated documentation.
%       20130717:   Implmented FDR & Fisher's r-to-z transform.
%       20130803:   Updated for compatibility with updated progress bar code.
%       20131001:   Bug fix for single tailed p-values erroring out.
%       20131030:   Bug fix for not outputting a NaN no upper significance cutoff is found during
%                   two-tailed tests.
%       20140127:   Implemented GPU processing for SGoF and a faster CPU version of it as well.

% TODO: Implement Bonferonni correction
% TODO: Implement alternative statistical tests


%% Initialize
% Catch incorrect data input
if ~isnumeric(realData) || ~isnumeric(nullData)
    error('Unknown data input parameters. Both real and null data must be arrays of numerical data');
end

% Initialize defaults & settings
if length(varargin) == 1 && isstruct(varargin{1})
    % Allow for outside input of variable structure
    assignInputs(varargin{1}, 'varsOnly')
else
    % Defaults & input checking
    inStruct = struct(...
        'AlphaVal', 0.05,...
        'CDFMethod', 'arbitrary',...    
        'FWERMethod', 'sgof',...
        'Parallel', 'off',...
        'Tails', 'both');
    assignInputs(inStruct, varargin,...
        'compatibility', {'AlphaVal', 'alpha', 'significance';
                          'CDFMethod', 'cdf', 'pvals';
                          'FWERMethod', 'fwer', 'correction';
                          'Parallel', 'parallelprocessing', 'concurrency';
                          'Tails', 'direction', []});
end

% Reshape the input data & get rid of NaNs & zeros
realData = realData(:); realData(isnan(realData)) = []; realData(realData == 0) = [];
lenReal = length(realData);
nullData = nullData(:); nullData(isnan(nullData)) = []; nullData(nullData == 0) = []; 
nullData = sort(nullData);
lenNull = length(nullData);


%% Convert Data into a CDF
% Calculate p-values of the data
pvals = zeros(2, length(realData));
switch lower(CDFMethod)
    case 'arbitrary'
        % Convert data into arbitrary p-values
        progBar = progress('Calculating Arbitrary PDF');
        
        switch lower(Parallel)
            case 'gpu'
                
%                 % Specify available GPU memory (in gigabytes, for convenience)
%                 gpuMem = 2;
%                 
%                 % Convert available memory to number of available double precision integers (enough to accommodate 3
%                 % arrays of equal size)
%                 doublesAvailable = (gpuMem*1024^3)/(8*3);
%                 numColsAvailable = floor(doublesAvailable/lenNull);
%                 
%                 % Put the appropriately sized null data array on the GPU
%                 nullData = gpuArray(repmat(nullData, [1, numColsAvailable]));
%                 
%                 for a = 1:numColsAvailable:lenReal
%                     % Determine the index of the real data colum to stop at
%                     idxEndCol = a + numColsAvailable - 1;
%                     
%                     % Generate a segment of real data to analyze. Account for possible mismatches in dimensions
%                     if (a + numColsAvailable - 1) > lenReal
%                         tempReal = realData(a:end)';
%                         nullData = nullData(:, 1:lenReal-a+1);
%                         idxEndCol = lenReal;
%                     else
%                         tempReal = realData(a:idxEndCol)';
%                     end
%                     tempReal = gpuArray(repmat(tempReal, [lenNull, 1]));
%                     
%                     % Calculate the upper tail p-values
%                     progBar.BarTitle = 'Calculating Lower Tail';
%                     if any(strcmpi(Tails, {'lower', 'l', 'both', 'all'}))
%                         compArray = sum(nullData <= tempReal, 1)./lenReal;
%                         pvals(1, a:idxEndCol) = gather(compArray);
%                         clear compArray
%                     end
%                     
%                     % Calculate the lower tail p-values
%                     progBar.BarTitle = 'Calculating Upper Tail';
%                     if any(strcmpi(Tails, {'upper', 'higher', 'h', 'both', 'all'}))
%                         compArray = sum(nullData >= tempReal, 1)./lenReal;
%                         pvals(2, a:idxEndCol) = gather(compArray);
%                         clear compArray
%                     end
%                     
%                     % Garbage collection on GPU
%                     clear tempReal;
%                     update(progBar, a/lenReal);
%                 end
%                 
%                 % Final GPU garbage collection
%                 clear nullData;


                % Run p-value generation on the GPU (fastest)
                realData = gpuArray(realData); %lenReal = gpuArray(length(realData));
                nullData = gpuArray(nullData); %lenNull = gpuArray(length(nullData));
                pvals = gpuArray(pvals);
                
                % Calculate upper & lower tails
                if any(strcmpi(Tails, {'lower', 'l', 'both', 'all'}))
                    reset(progBar); progBar.BarTitle = 'Calculating Lower Tail';
                    for a = 1:lenReal
                        pvals(1, a) = sum(nullData <= realData(a))/lenNull;
                        update(progBar, a/lenReal)
                    end
                end
                if any(strcmpi(Tails, {'upper', 'higher', 'h', 'both', 'all'}))
                    reset(progBar); progBar.BarTitle = 'Calculating Upper Tail';
                    for a = 1:lenReal
                        pvals(2, a) = sum(nullData >= realData(a))/lenNull;
                        update(progBar, a/lenReal)
                    end
                end
                
                % Pull data off of the GPU
                pvals = gather(pvals);
                realData = gather(realData);
                nullData = gather(nullData);
                
            case {'cpu', 'on'}
                
                % Run p-value generation on multiple CPUs (next fastest)
                if matlabpool('size') == 0
                    matlabpool
                end
                
                % Pad real data with zeros so that parfor progress can be tracked in increments of 1/100s
                numZeros = sigFig(lenReal, 'format', '000', 'round', 'ceil') - lenReal;
                realData = [realData; zeros(numZeros, 1)];
                lenReal = length(realData);

                % Calculate upper & lower tails
                if any(strcmpi(Tails, {'lower', 'l', 'both', 'all'}))
                    reset(progBar); progBar.BarTitle = 'Calculating Lower Tail';
                    for a = 1:100:lenReal
                        parfor b = a:a+99
                            pvals(1, b) = sum(nullData <= realData(b))/lenNull;
                        end
                        update(progBar, a/lenReal)
                    end
                end
                if any(strcmpi(Tails, {'upper', 'higher', 'h', 'both', 'all'}))
                    reset(progBar); progBar.BarTitle = 'Calculating Upper Tail';
                    for a = 1:100:lenReal
                        parfor b = a:a+99
                            pvals(2, b) = sum(nullData >= realData(b))/lenNull;
                        end
                        update(progBar, a/lenReal)
                    end
                end
            
            otherwise
                
                % Run p-value generation on a single CPU (slowest)
                for a = 1:lenReal
                    % Calculate upper & lower tails
                    if any(strcmpi(Tails, {'lower', 'l', 'both', 'all'}))
                        pvals(1, a) = sum(nullData <= realData(a))/lenNull;
                    end
                    if any(strcmpi(Tails, {'upper', 'higher', 'h', 'both', 'all'}))
                        pvals(2, a) = sum(nullData >= realData(a))/lenNull;
                    end
                    update(progBar, a/lenReal)
                end
        end
        close(progBar)
        
        % Get rid of rows of zeros (if only a single tail is called for)
        if ~any(pvals(1, :)), pvals(1, :) = [];
        elseif ~any(pvals(2, :)), pvals(2, :) = []; end
        
        % Get the mean of the null data (to determine tail locations later)
        meanNull = gather(mean(nullData));

    case {'fishers transform', 'r-to-z', 'fishers r-to-z', 'r-to-z transform'}
        % Transform correlation coefficients to z-scores
        zData = atanh(realData);
        pvals(1, :) = 1 - normcdf(zData, mean(zData), std(zData));
        pvals(2, :) = normcdf(zData, mean(zData), std(zData));
        
        % Get the mean of the null data (to determine tail locations later)
        meanNull = mean(zData);
end
            
% Create a CDF from the data
if any(strcmpi(Tails, {'both', 'all'}))
    cdfVals = 2*min(pvals(1, :), pvals(2, :));
else
    cdfVals = pvals;
end


%% Correct for FWER (Multiple Comparisons) if Called For
switch lower(FWERMethod)
    case 'bonferonni'
        % Not yet developed...
        
    case {'fdr', 'bhfdr'}
        cutoff = bh_fdr(cdfVals, AlphaVal);
    
    case 'sgof'
        % Sequential Goodness of Fit method
        if strcmpi(Parallel, 'gpu') && exist('gpuSGoF.m', 'file')
            cutoff = gpuSGoF(cdfVals, AlphaVal); 
        else
            cutoff = sgof(cdfVals, AlphaVal);
        end

    otherwise
        % No FWER correction
        tempCDFVals = sort(cdfVals);
        numSig = sum(tempCDFVals <= AlphaVal);
        if numSig == 0, cutoff = NaN; else
            cutoff = tempCDFVals(numSig);
        end
        clear temp*        
end


%% Find Cutoff Thresholds in Data Units
if ~isnan(cutoff)
    
    % Determine tail locations in the data & indices of significant p-values
    idsLowerTail = realData' < meanNull;
    idsUpperTail = realData' > meanNull;
    idsSig = cdfVals <= cutoff;
    
    upperCutoff = NaN;
    switch lower(Tails)
        case {'lower', 'l'}
            lowerCutoff = max(realData(idsLowerTail & idsSig));
            
        case {'upper', 'higher', 'h'}
            % Assign this to be the lower cutoff even though it's not (helps with output argument assignment)
            lowerCutoff = min(realData(idsUpperTail & idsSig));
            
        otherwise
            lowerCutoff = max(realData(idsLowerTail & idsSig));
            upperCutoff = min(realData(idsUpperTail & idsSig));
            if isempty(upperCutoff); upperCutoff = NaN; end
    end
    if isempty(lowerCutoff), lowerCutoff = NaN; end
     
else
    lowerCutoff = NaN;
    upperCutoff = NaN;
end

% Assign outputs
assignOutputs(nargout, pvals, lowerCutoff, upperCutoff);