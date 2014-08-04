function outNum = word2num(inWord, varargin)
%WORD2NUM Translates a cell array of English words for positive integer numbers into their numerical
%   equivalents. This is the reverse of what num2word does. For example, inputting {'one' 'two'
%   'three'} into this function results in an output of [1 2 3]. The case of the input strings does
%   not matter. The output numerical array is of the same dimensions as the input. No options for
%   conversion are supported at this time.
% 
%   WARNING: This function can currently only handle integer values between 'zero' and 'nineteen'.
% 
%   Syntax:
%   outNum = word2num(inWord)
% 
%   OUTPUTS:
%   outNum:             A numerical array of integer equivalents to this
%                       function's input. Dimensions are the same as the
%                       input array. Output integers are of type 'double'.
% 
%   PROPERTY NAMES:
%   inNum:              A string or cell array of strings to be translated
%                       into their numerical integer equivalents. Case of
%                       the input strings (upper-/lowercase) does not
%                       matter.
% 
%   Written by Josh Grooms on 20130116
%       20130120:   Updated the help section


%% Initialize
% Initialize a library of word translations
wordLibrary = {'zero';
               'one';
               'two';
               'three';
               'four';
               'five';
               'six';
               'seven';
               'eight';
               'nine';
               'ten';
               'eleven';
               'twelve';
               'thirteen';
               'fourteen';
               'fifteen';
               'sixteen';
               'seventeen';
               'eighteen';
               'nineteen'};

outNum = inWord;
for i = 1:numel(inWord)
    % Get the current word to be translated
    currentWord = inWord{i};
    
    % For now, use "strcmpi" to find where the word is in the library
    currentNum = find(strcmpi(currentWord, wordLibrary'));
    
    % Adjust for including "zero" in the word library & store number in output
    outNum{i} = currentNum - 1;
end

outNum = cell2mat(outNum);
    
    
    
    