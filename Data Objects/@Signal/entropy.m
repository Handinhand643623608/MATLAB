function H = entropy(x, y, kind)
%ENTROPY Calculates the Shannon entropy of the inputted data set.
%   This function calculates the information theoretic entropy (Shannon entropy) on a single data set or between two
%   data sets and returns the entropy estimate in units of bits. If a single data set is inputted, the result is the
%   marginal entropy of that set of values. Otherwise, either the joint or conditional entropy is calculated between two
%   equally-sized data sets, depending on user input for KIND.
%
%   The returned value represents the average uncertainty present in the data. More specifically, it is an estimate of
%   how many bits are required to store a single data point that would be a typical result of the experiment that
%   produced the data in the first place.
%
%   This function is capable of calculating three different types of entropy. Marginal entropy H(X) is the entropy
%   belonging to a single data set alone. Joint entropy H(X,Y) is the entropy of a set of variables, which is calculated
%   using the joint probability mass distributions in place of marginal distributions. Finally, conditional entropy
%   H(X|Y) represents the number of bits needed to store a typical outcome of one data set given that the value of a
%   second data set is known.
%   
%   Together, these types of entropies are sufficient for easily calculating a number of other information theoretic
%   quantities, such as:
%           
%       Dual Total Correlation:     D(X,Y) = I(X;Y)/H(X,Y)
%       Mutual Information:         I(X;Y) = H(X) - H(X|Y)
%       Redundancy:                 R(X,Y) = I(X;Y)/(H(X) + H(Y))
%       Symmetric Uncertainty:      S(X,Y) = 2*R(X,Y)
%       Total Correlation:          C(X,Y) = I(X;Y)/min(H(X), H(Y))
%       Uncertainty Coefficient:    U(X,Y) = I(X;Y)/H(Y)
%       Variation of Information:   V(X,Y) = H(X) + H(Y) - 2*I(X;Y)
%
%   IMPORTANT: The inputted data set(s) must be properly discretized before using this function. Attempting to use data
%   that have high resolution (i.e. high precision) will likely generate meaningless entropy estimates. 
%
%   This is a consequence of all information theoretic measures relying on values being repeated within data sets, which
%   becomes increasingly improbable with higher precision number representation. In other words, double-precision
%   recordings of analogue waveforms probably contain many values that are approximately equal, but nearly none that are
%   exactly equal over every bit of digital storage. You must first ensure that "nearly equal" becomes "exactly equal",
%   a process that usually involves some subjectivity and varies a lot between applications. Otherwise, entropy
%   estimates will approach their maximum possible value and will not be informative.
%           
%   SYNTAX:
%   H = entropy(X)
%   H = entropy(X, Y)
%   H = entropy(X, Y, kind)
%
%   OUTPUT:
%   H:          DOUBLE
%               A single double-precision number representing the entropy estimate from the inputted data. This value is
%               expressed in units of bits due to the base-2 logarithm used in all calculations. This number represent
%               the marginal entropy if specified using the KIND variable or if only a single data set is entered.
%               Otherwise, it will represent either the joint or conditional entropy between two sets of data.
%   
%   INPUT:
%   X:          [DOUBLE]
%               An array of double-precision numbers representing a single set of data. If this is the only data that is
%               inputted, then the variable KIND has no effect and the marginal entropy is calculated.
%
%               IMPORTANT: These data must be discretized prior to use.
%
%   OPTIONAL INPUT:
%   Y:          [DOUBLE]
%               An array of double-precision numbers representing a second set of data. This array must be the same size
%               as the array X and is for use in calculating either joint or conditional entropy between the two sets.
%
%               IMPORTANT: These data must be discretized prior to use.
%
%   kind:       'STR'
%               A string indicating what kind of entropy to calculate between two data sets. If only a single data set X
%               is inputted, this variable has no effect and only marginal entropy will be calculated. If however Y is
%               specified and is the same size as X, then this variable may be used to choose between either conditional
%               or joint entropy calculation.
%
%               DEFAULT: 'conditional'
%               OPTIONS:
%                        'conditional'
%                        'joint'

%% CHANGELOG
%   Written by Josh Grooms on 20140610



%% Initialize & Call Appropriate Entropy Function
% Fill in any missing inputs
if nargin == 1
    y = [];
    kind = 'marginal';
elseif nargin == 2
    if all((size(x) == size(y)))
        kind = 'conditional';
    else
        error('Size of the inputted data sets must match');
    end
else
    if any((size(x) ~= size(y)))
        error('Size of the inputted data sets must match');
    end
end

% Print a warning if attempting to calculate anything other than marginal entropy with a single input data set
if (isempty(y) && ~strcmpi(kind, 'marginal'))
    warning('Joint and conditional entropy for a single variable is the same as marginal entropy.');
    kind = 'marginal';
end

% Call the appropriate function to calculate the desired entropy
switch lower(kind)
    case 'conditional'
        H = conditionalentropy(x, y);
    case 'marginal'
        H = marginalentropy(x);
    case 'joint'
        H = jointentropy(x, y);
    otherwise
        error('The requested entropy measure does not exist or isn''t implemented. See documentation for supported measures.');
end


end



%% NESTED FUNCTIONS
% Shannon marginal entropy calculation (in bits)
function H = marginalentropy(x)
    
    % Get the unique values of the input data set
    uniqueValues = unique(x);
    numSamples = numel(x);
    
    % Do a rudimentary check for discretized data (but this will only sometimes catch the error)
    if (length(uniqueValues) == numSamples)
        warning('No values occur more than once in the input data. Was the data set properly discretized?');
    end

    % Initialize the p-value array & entropy estimate
    p = zeros(size(uniqueValues));
    H = 0;

    % Calculate p-values & marginal entropy for the input data set
    for a = 1:length(uniqueValues)
        currentUnique = (x == uniqueValues(a));
        p(a) = sum(currentUnique(:))/numSamples;
        if (p(a) ~= 0)
            H = H - (p(a)*log2(p(a)));
        end
    end
    
end

% Shannon joint entropy calculation (in bits)
function H = jointentropy(x, y)
    
    % Get the unique values from the input data sets
    uniqueX = unique(x);
    uniqueY = unique(y);
    numSamples = numel(x);
    
    % Do a rudimentary check for discretized data (but this will only sometimes catch the error)
    if (length(uniqueX) == numSamples || length(uniqueY) == numSamples)
        warning('No values occur more than once in the input data. Was the data set properly discretized?');
    end
    
    % Initialize the p-value array & entropy estimate
    pXY = zeros(length(uniqueX), length(uniqueY));
    H = 0;
    
    % Calculate p-values & joint entropy for the two input data sets
    for a = 1:length(uniqueX)
        for b = 1:length(uniqueY)
            currentEquality = (x == uniqueX(a)) & (y == uniqueY(b));
            pXY(a, b) = sum(currentEquality(:))/numSamples;
            if (pXY(a, b) ~= 0)
                H = H - (pXY(a, b)*log2(pXY(a, b)));
            end
        end
    end    
end


% Shannon conditional entropy calculation (in bits)
function H = conditionalentropy(x, y)

    % Calculate conditional entropy: H(X|Y) = H(Y, X) - H(Y)
    H = jointentropy(y, x) - marginalentropy(y);
    
end