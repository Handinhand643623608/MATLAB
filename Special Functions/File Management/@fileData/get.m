function fileProps = get(fileObj, propName, varargin)
%GET Overloads the native "get" method to provide better and more flexible property retrieval from the file object.
%
%   SYNTAX:
%   fileProps = get(fileObj, propName)
%   fileProps = get(fileObj, propName, 'PropertyName', PropertyValue...)
%
%   OUTPUT:
%   fileProps:          UNKNOWN
%                       An array or cell array of file object property values listed in the desired
%                       order.
%
%   INPUTS:
%   fileObj:            FILEOBJ
%                       The file object containing data about files within a directory.
%
%   propName:           STRING
%                       The name of the property that is desired from the file object.
%                       OPTIONS:
%                           'Name'
%                           'DateModified'
%                           'Path'
%                           'Size'
%   
%   OPTIONAL INPUTS:
%   'Search':           STRING
%                       A string or value that is to be searched for within the desired property name. If specified,
%                       this function only outputs property values that match or contain the specified search string.
%
%   'Ext':              STRING
%
%   'Sort':             STRING
%
%   'Direction':        STRING



%% CHANGELOG
%   Written by Josh Grooms on 20130221
%       20130320:   Implemented ability to search through files aggregated.
%       20130611:   Expanded the help & reference section.



%% Initialize
% Set up a defauls structure & settings
inStruct = struct(...
    'searchStr', [],...
    'ext', [],...
    'sortMethod', [],...
    'sortOrder', 'ascend');
assignInputs(inStruct, varargin,...
    'compatibility', {'searchStr', 'search', 'string', 'name', 'lookfor', 'searchfor';...
                      'ext', 'extension', [], [], [], [];...
                      'sortMethod', 'sortby', 'list', 'method', 'sort', [];...
                      'sortOrder', 'order', 'dataorder', 'listorder', 'direction', 'sortdirection'});
                  
                  
                  
%% Retrieve the Property Values
% Get a comma-separated list of property values
switch propName
    case {'Size', 'DateModified'}
        fileProps = [fileObj.(propName)]';
        
    otherwise
        fileProps = {fileObj.(propName)}';
end

% Search through the data, if called for
if ~isempty(searchStr)
    notFlag = false;
    if strcmp(searchStr(1), '~')
        notFlag = true;
        searchStr(1) = [];
    end
    searchedProps = regexpi(fileProps, ['.*' searchStr '.*'], 'match');
    
    if notFlag
        fileProps(~cellfun(@(x) isempty(x), searchedProps)) = [];
    else
        fileProps(cellfun(@(x) isempty(x), searchedProps)) = [];
    end
end    
    
% Sort the data, if called for
if ~isempty(sortMethod)
    switch sortMethod
        case 'alphabetical'
            [~, idsSorted] = sort(upper(fileProps));
            if strcmpi(sortOrder, 'descend')
                idsSorted = flipdim(idsSorted, 1);
            end

        case {'dateModified', 'size'}
            sortMethod(1) = upper(sortMethod(1));
            [~, idsSorted] = sort([fileObj.(sortMethod)]', sortOrder);
    end
    
    fileProps = fileProps(idsSorted);
end
            
            