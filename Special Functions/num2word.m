function outWord = num2word(inNum, varargin)
%NUM2WORD Translates an array of positive integer values up to 19 into a cell array of word 
%   equivalents. For example, inputting [1 2 3] into this function results in an output of {'one'
%   'two' 'three'}. It is also possible to capitalize the first character of each word through this
%   function's options. The output array is of the same dimensions as the input. 
% 
%   WARNING: This function can currently only handle integers with values between 0 and 19.
% 
%   Syntax:
%   outWord = num2word(inNum, 'propertyName', propertyValue,...)
% 
%   OUTPUTS:
%   outWord:            A string or cell array of words representing this function's numerical 
%                       inputs. Dimensions are the same as the input array.
% 
%   PROPERTY NAMES:
%   inNum:              A positive integer or array of positive integers to be translated into 
%                       their English word equivalents. 
%                       WARNING: Numbers are rounded before conversion
%   
%   ('capitalize'):     Option to capitalize the first letter of each word in the translation. Set 
%                       to true or 1 to enable.
%                       DEFAULT: false
% 
%   Written by Josh Grooms on 20130116
%       20130120:   Updated help section


%% Initialize
% Initialize the defaults structure
inStruct = struct(...
    'capitalize', false);
assignInputs(inStruct, varargin)

% Round the number array to prevent mismatches
inNum = round(inNum);

% Convert the input into a string array
inNum = num2cell(inNum);

% Initialize a library of values
wordLibrary = {'zero', 'one', 'two', 'three', 'four', 'five', 'six',...
    'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen',...
    'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'}';


%% Convert the Numerical Array into Word Equivalents
outWord = inNum;
for i = 1:numel(inNum)
    currentInNum = inNum{i};
    currentWord = wordLibrary{currentInNum + 1};
    
    % Deal with capitalization of letters, if applicable
    if capitalize
        currentWord = regexprep(currentWord, '(\<\w)', '${upper($1)}');
    end
    
    % Store the word in the output
    if numel(inNum) == 1
        outWord = currentWord;
    else
        outWord{i} = currentWord;
    end
end
