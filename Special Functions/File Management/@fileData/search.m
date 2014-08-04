function fileObj = search(fileObj, varargin)
%SEARCH Searches through various fileData properties and returns objects that match the input query.
%   Results are returned in same order as they're found within the original object. 
%
%   Written by Josh Grooms on 20130324


%% Initialize
% Initialize a default & settings structure
inStruct = struct(...
    'propName', [],...    
    'searchStr', []);
assignInputs(inStruct, varargin,...
    'compatibility', {'propName', 'property', 'field';
                      'searchStr', 'query', 'search'},...
    {'searchStr'}, 'regexprep(varPlaceholder, ''\.'', ''\\'')');



                  
