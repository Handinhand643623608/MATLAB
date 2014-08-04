classdef Signal < hgsetget
%SIGNAL 
%   
%   SYNTAX:
%   y = Signal(x)
%
%   OUTPUT:
%   y:              SIGNAL
%
%   INPUT:
%   x:              VECTOR
%
%   OPTIONAL INPUTS:
%   Bandpass:       [DOUBLE, DOUBLE]
%
%   Fs:             DOUBLE
%
%   ID:             ANYTHING
%
%   TimeDim:        INTEGER
%
%   Units:          STRING
%
%   ZScored:        BOOLEAN

%% CHANGELOG
%   Written by Josh Grooms on 20140610
%       20140618:   Implemented some basic math and statistics functions. Implemented overloads for common shorthand
%                   operators. Implemented methods for subscripted references and assignments. Implemented static
%                   methods for linear regression and entropy calculation.
%       20140623:   Implemented a static and class method for discretizing signals. Implemented a method for plotting a
%                   histogram of signal amplitude data.
   
%% OBJECT DEPENDENCIES
% 
%   entropy
%   struct2var

%% TODOS
% Immediate Todos
% - Test this object and its methods
% - Fill out signal processing methods
%   > Filter
%   > Regress


    
    %% Signal Properties
    % Public properties
    properties (AbortSet, SetObservable)
        
        Bandpass            % The minimum and maximum frequencies present in the signal.
        Data                % The vector of data points making up the signal.
        Fs                  % The sampling rate (in Hz = samples/second).
        ID                  % Any identifying data or additional signal details the user wants to specify.
        TimeDim = 2;        % An integer indicating which array dimension contains time points of signals.
        Units               % A string indicating the units of signal amplitude.
        ZScored = false;    % Boolean indicating whether or not the data have been converted to standard scores.
         
    end
    
    
    
    %% Constructor Method
    methods
        function y = Signal(x, varargin)
            %SIGNAL Converts a vector representing a signal into a managed data object.
            
            if nargin ~= 0
                % Check that the input data is a vector. If not, error out
                if ~ismatrix(x)
                    error('The signal being bound to this object must be at most two-dimensional');
                end
                
                % Transfer the input data to the object's data vector
                y.Data = x;

                % Transfer any user-defined properties to the object
                AssignProperties(y, varargin{:});
            end
        end
    end
    
    
    
    %% Object Conversion Methods
    methods
        % Convert a signal or array of signals to a MATLAB array
        function y = ToArray(x)
            %TOARRAY Converts a signal or array of signals to a MATLAB array of doubles.
            y = x.Data;
        end
        % Convert a Signal to a structure, preserving only the public fields
        function y = ToStruct(x)
            %TOSTRUCT Converts a signal object to a structure.
            propNames = properties(x);
            y = struct();
            for a = 1:length(propNames); y.(propNames{a}) = x.(propNames{a}); end
        end
    end
    
    
    
    %% Overloads of Shorthand Math & Logical Operations
    methods
        % Test for equality
        function z = eq(x, y)
            funStr = 'Element-wise equality test';
            CheckSizeEquality(x, y, true, funStr);
            if issignal(x) || issignal(y)
                z = ToData(x) == ToData(y);
            else
                IncompatibleError(x, y, funStr);
            end
        end
        % Greater-than-or-equality test        
        function z = ge(x, y)
            funStr = 'Greater-than-or-equal test';
            CheckSizeEquality(x, y, true, funStr);
            if issignal(x) || issignal(y)
                z = ToData(x) >= ToData(y);
            else
                IncompatibleError(x, y, funStr);
            end            
        end
        % Greater-than test
        function z = gt(x, y)
            funStr = 'Greater-than test';
            CheckSizeEquality(x, y, true, funStr);
            if issignal(x) || issignal(y)
                z = ToData(x) > ToData(y);
            else
                IncompatibleError(x, y, funStr);
            end            
        end
        % Test for complete data equality
        function z = isequal(x, y)
            z = all(eq(x, y));
        end
        % Test for equality, treating NaNs as equal
        function z = isequaln(x, y)
            x(isnan(x)) = 0;
            y(isnan(y)) = 0;
            z = isequal(x, y);
        end
        % Get indices of any NaNs in the data
        function z = isnan(x)
            z = isnan(x.Data);
        end
        % Less-than-or-equality test
        function z = le(x, y)
            funStr = 'Less-than-or-equal test';
            CheckSizeEquality(x, y, true, funStr);
            if issignal(x) || issignal(y)
                z = ToData(x) <= ToData(y);
            else
                IncompatibleError(x, y, funStr);
            end            
        end
        % Less-than test
        function z = lt(x, y)
            funStr = 'Less-than test';
            CheckSizeEquality(x, y, true, funStr);
            if issignal(x) || issignal(y)
                z = ToData(x) < ToData(y);
            else
                IncompatibleError(x, y, funStr);
            end            
        end
        % Subtraction
        function z = minus(x, y)
            funStr = 'Subtraction';
            CheckSizeEquality(x, y, true, funStr);
            sigVars = ToInputVars(x, y);
            if issignal(x) || issignal(y)
                z = Signal(ToData(x) - ToData(y), sigVars{:});
            else
                IncompatibleError(x, y, funStr);
            end
            z.ZScored = false;
        end
        % Matrix power
        function mpower(x, y)
            sigVars = ToInputVars(x, y);
            if issignal(x) || issignal(y)
                z = Signal(ToData(x) ^ ToData(y), sigVars{:});
            end
            z.ZScored = false;
        end
        % Matrix multiplication
        function z = mtimes(x, y)
            sigVars = ToInputVars(x, y);
            if issignal(x) || issignal(y)
                z = Signal(ToData(x) * ToData(y), sigVars{:});
            else
                IncompatibleError(x, y, funStr);
            end
            z.ZScored = false;
        end
        % Test for inequality
        function z = ne(x, y)
            z = ~eq(x, y);
        end
        % Addition
        function z = plus(x, y)
            funStr = 'Addition';
            CheckLengthEquality(x, y, true, funStr);
            sigVars = ToInputVars(x);
            if issignal(x) || issignal(y)
                z = Signal(ToData(x) + ToData(y), sigVars{:});
            else
                IncompatibleError(x, y, funStr);
            end
            z.ZScored = false;
        end
        % Element-wise power
        function z = power(x, y)
            funStr = 'Element-wisse power';
            CheckLengthEquality(x, y, true, funStr);
            sigVars = ToInputVars(x, y);
            if issignal(x) || issignal(y)
                z = Signal(ToData(x) .^ ToData(y), sigVars{:});
            else
                IncompatibleError(x, y, funStr);
            end
            z.zScored = false;
        end
        % Element-wise multiplication
        function z = times(x, y)
            funStr = 'Element-wise multiplication';
            CheckLengthEquality(x, y, true, funStr);
            sigVars = ToInputVars(x, y);
            if issignal(x) || issignal(y)
                z = Signal(ToData(x) .* ToData(y), sigVars{:});
            else
                IncompatibleError(x, y, funStr);
            end
            z.ZScored = false;
        end
    end
    
    
    
    %% Signal Indexing
    methods
        % Subscripted assignment
        function x = subsasgn(x, s, y)
            x.Data(s.subs{:}) = y;
        end
        % Subscripted reference
        function y = subsref(x, s)
            y = x.Data(s.subs{:});
        end
    end
    
    
    
    %% Basic Math & Statistics
    methods
        % Approximate taking the derivative of the data vector
        function Diff(x)
            %DIFF Returns the approximate derivative of a signal with respect to time.
            x.Data = diff(x.Data, 1, x.TimeDim); 
        end
        % Calculate the dot product between signals
        function z = Dot(x, y)
            funStr = 'Dot product';
            CheckLengthEquality(x, y, false, funStr);
            if issignal(x); timeDim = x.TimeDim;
            elseif issignal(y); timeDim = y.TimeDim; 
            else IncompatibleError(x, y, funStr);
            end
            z = dot(ToData(x), ToData(y), timeDim);
        end
        % Determine the maximum amplitude value
        function [z, i] = Max(x, y, dim)
            if nargin == 1
                [z, i] = max(ToData(x), [], x.TimeDim);
            elseif nargin == 2;
                z = max(ToData(x), ToData(y));
                i = nan;
            elseif nargin == 3;
                [z, i] = max(ToData(x), ToData(y), dim);
            end
        end
        % Calculate the average amplitude of a signal
        function y = Mean(x, dim)
            %MEAN Calculates the average signal amplitude over time.
            if nargin == 1; dim = x.TimeDim; end
            y = mean(x.Data, dim);
        end
        % Determine the minimum amplitude value
        function [z, i] = Min(x, y, dim)
            if nargin == 1
                [z, i] = min(ToData(x), [], x.TimeDim);
            elseif nargin == 2;
                z = min(ToData(x), ToData(y));
                i = nan;
            elseif nargin == 3;
                [z, i] = min(ToData(x), ToData(y), dim);
            end
        end
        % Calculates the range of amplitudes present in a signal
        function y = Range(x, dim)
            if nargin == 1; 
                if any(Size(x) == 1); 
                    y = Max(x) - Min(x);
                    return;
                else 
                    dim = x.TimeDim;
                end
            end
            y = Max(x, dim) - Min(x, dim);
        end
        % Calculate the standard deviation of signal amplitude
        function y = Std(x)
            %STD Calculates the standard deviation signal amplitude over time. 
            y = std(x.Data);
        end
        % Calculate the sum of the signal vector
        function y = Sum(x)
            %SUM Calculates the sum of signal amplitudes over time.
            y = sum(x.Data);
        end
    end
    
    
    
    %% Signal Processing Methods
    methods 
        
        % Estimate the conditional Shannon entropy between two signals in bits
        function z = ConditionalEntropy(x, y)
            %CONDITIONALENTROPY Calculates the Shannon entropy of a signal given that another signal is known.
            z = Signal.entropy(x.Data, y.Data, 'conditional');
        end
        % Calculate the cross correlation between two signals
        function z = CrossCorr(x, y)
            %CROSSCORR Calculates the Pearson correlation coefficient between signals as a function of time delay.
            if (nargin == 1); z = xcorr(x.Data, 'coeff');
            else z = xcorr(x.Data, y.Data, 'coeff'); end
        end
        % Discretize a signal
        function Discretize(x, nbins, partition)
            %DISCRETIZE Re-expresses signal amplitude in terms of its membership with discrete partitions.
            if nargin == 1
                nbins = 6;
                partition = 'equidistant';
            elseif nargin == 2;
                partition = 'equidistant';
            end
            x.Data = Signal.discretize(x.Data, nbins, partition);
        end
        % Estimate the marginal Shannon entropy of the signal in bits 
        function y = Entropy(x)
            %ENTROPY Calculates the Shannon entropy of a signal.
            y = Signal.entropy(x.Data);
        end
        
        function Filter(x)
            
            
        end
        % Estimate the joint Shannon entropy between two signals in bits
        function z = JointEntropy(x, y)
            %JOINTENTROPY Calculates the Shannon entropy of a set of signals.
            z = Signal.entropy(x.Data, y.Data, 'joint'); 
        end
        % Estimate the mutual information between two signals in bits
        function z = MutualInformation(x, y)
            %MUTUALINFORMATION Calculates the amount of Shannon information shared between two signals.
            z = Signal.entropy(x.Data) - Signal.entropy(x.Data, y.Data, 'conditional'); 
        end
        % Regress data from a signal
        function Regress(x, y)
            %REGRESS Returns the residuals of a linearly regression between signals.
            if ~isa(x, 'Signal'); 
                error('Regression can only be performed on a signal. Use the static "regress" method to work with native MATLAB arrays.');
            end
            if isa(y, 'Signal')
                x.Data = Signal.regress(x.Data, y.Data);
            else
                x.Data = Signal.regress(x.Data, y);
            end
        end
        % Z-Score the data vector
        function ZScore(x)
            %ZSCORE Re-expresses signal amplitude as a fraction of its standard deviation.
            x.Data = zscore(x.Data);
            x.ZScored = true;
        end
    end
    
    
    
    %% Object Management Methods
    methods
        % Make a histogram of the signal
        function h = Hist(x, nbins)
            %HIST Creates a histogram of signal amplitudes.
            if nargin == 1; nbins = 10; end
            h = hist(x.Data, nbins); 
        end
        % Determine signal length
        function y = Length(x)
            %LENGTH Returns the length of a signal.
            if numel(x) > 1
                error('Signal length can only be calculated on a single signal. Arrays of signals are not supported');
            end
            y = length(x.Data);
        end
        
        function y = Numel(x)
            y = numel(x.Data);
        end
        % Make a plot of the signal over time or samples
        function h = Plot(x)
            %PLOT Creates a plots of signal amplitude over time.
            
            % Determine how to lable the x-axis
            if ~isempty(x.Fs)
                t = length(x.Data) * (1/x.Fs);
                xLabelStr = 'Time (s)';
            else
                t = 1:length(x.Data);
                xLabelStr = 'Samples';
            end
            
            % Determine how to label the y-axis
            if ~isempty(x.Units)
                yLabelStr = x.Units;
            else
                yLabelStr = 'Arbitrary Units';
            end
            
            % Plot the data
            figure; 
            h = plot(t, x.Data);
            xlabel(xLabelStr);
            ylabel(yLabelStr);
        end
        % Determine the size of a signal array
        function y = Size(x, dim)
            if nargin == 1; y = size(x.Data);
            else y = size(x.Data, dim); end
        end
            
    end
    
    
    
    %% Static Methods
    methods (Static)
        % Discretize a signal
        y = discretize(x, nbins, partition);
        % Calculate Shannon entropy
        H = entropy(x, y, kind);
        % Regress one data from another, returning the residuals of the regression
        z = regress(x, y, dim);
    end
    
    
    
    %% Private Methods
    methods (Access = private)
        % Transfer constructor input name/value pairs to the object
        function AssignProperties(x, varargin)
            propNames = properties(x);
            for a = 1:2:length(varargin)
                propCheck = strcmpi(varargin{a}, propNames);
                if any(propCheck)
                    x.(propNames{propCheck}) = varargin{a + 1};
                end
            end            
        end
        % Tests for equal length between a signal and another signal or vector, while allowing or disallowing scalars
        function CheckLengthEquality(x, y, allowScalars, funStr)
           if ~issignal(x); CheckLengthEquality(y, x, allowScalars, funStr); return; end
           if isscalar(y) && allowScalars
               return;
           elseif issignal(y) && (Length(y) == Length(x))
               return;
           elseif isvector(y) && (length(y) == Length(x))
               return;
           else
               error('%s requires data to be of equal length', funStr);
           end
        end
        % Test for equal size between a signal and another signal or matrix, while allowing or disallowing scalars
        function CheckSizeEquality(x, y, allowScalars, funStr)
            if issignal(x) && issignal(y)
                if isequal(Size(x), Size(y))
                    return;
                elseif allowScalars && (Numel(x) == 1 || Numel(y) == 1)
                    return;
                else
                    error('%s requires data to be equally sized', funStr);
                end
            elseif issignal(x)
                if isequal(Size(x), size(y))
                    return;
                elseif allowScalars && (Numel(x) == 1 || numel(y) == 1)
                    return;
                else
                    error('%s requires data to be equally sized', funStr);
                end
            elseif issignal(y)
                if isequal(size(x), Size(y))
                    return;
                elseif  allowScalars && (numel(x) == 1 || Numel(y) == 1)
                    return;
                else
                    error('%s requires data to be equally sized', funStr);
                end
            else
                error('One or more inputs to CheckSizeEquality must be of type Signal');
            end
        end
        % Throw an error when incompatible types are used in a function
        function IncompatibleError(x, y, funStr)
            error('%s between a %s and a %s is not supported', funStr, class(x), class(y));
        end
        % Extract data from any input signals, leaving all other data types alone
        function varargout = ToData(varargin)
            varargout = cell(1, nargout);
            for a = 1:nargout
                if issignal(varargin{a})
                    varargout{a} = varargin{a}.Data;
                else
                    varargout{a} = varargin{a};
                end
            end
        end
        % Convert signal properties to input variables for creating another Signal object
        function vars = ToInputVars(x, y)
            if nargin == 1; y = 0; end
            if issignal(x); vars = struct2var(ToStruct(x), 'Data'); return;
            elseif issignal(y); vars = struct2var(ToStruct(x), 'Data'); return; 
            end
        end
    end
    
    
end