function varargout = ToArray(boldData, dataStr)
%TOARRAY Pull numeric arrays from a BOLD data object.
%   This function converts a BOLD data object to a numeric array by returning specific data sets that it pulls out of
%   the object. It is intended for use as a shortcut alternative to constantly dot-indexing the numerous fields that the
%   object contains by providing quick access to data that is frequently needed. Such data includes functional,
%   anatomical, and segmentation images, among others.
%
%   This function is also capable of aggregating two specific types of data that are often used: BOLD nuisance signals
%   and independent component signals. In these cases, the outputted data array is a concatenation of all available
%   signals from one or the other data stores; each individual row represents a separate signal. A legend that
%   identifies each of these rows can also be optionally outputted so that the data don't end up confused.
%   
%   SYNTAX:
%   boldArray = ToArray(boldData)
%   boldArray = ToArray(boldData, dataStr)
%   [boldArray, legend] = ToArray(boldData, dataStr)
%
%   OUTPUT:
%   boldArray:      2D, 3D, or 4D ARRAY
%                   The desired data array pulled from the data object. The size of this array depends completely on the
%                   type of data that is being extracted. Functional data will include all four-dimensions. Anatomical,
%                   segmentation and mean images will be three-dimensional. All others will take the form of a matrix,
%                   with rows representing signals and columns representing time points (i.e. [SIGNALS x TIME]. 
%
%   OPTIONAL OUTPUT:
%   legend:         CELL ARRAY OF STRINGS
%                   A cell array containing strings that indicate what data belong to each row of the outputted array.
%                   This parameter is only filled in when gathering nuisance or ICA data from the BOLD object because
%                   these data arrays are a concatenation of critically different signals. Thus, this parameter has the
%                   same number of rows as the outputted data array, with a direct correspondance between the string and
%                   the data source row.
%
%   INPUT:
%   boldData:       BOLDOBJ
%                   A single BOLD data object.
%
%   OPTIONAL INPUT:
%   dataStr:        STRING
%                   A string shortcut representing what kind of data to pull from the object.
%                   DEFAULT: 'Functional'
%                   OPTIONS:
%                           'Anatomical'
%                           'CSF'
%                           'Functional'
%                           'GrayMatter'
%                           'ICs'
%                           'Mean'
%                           'Nuisance'
%                           'WhiteMatter'

%% CHANGELOG
%   Written by Josh Grooms on 20140618
%       20140707:   Updated for compatibility with new MATFILE data storage.



%% Gather Data from the BOLD Data Object
% Fill in missing inputs
if nargin == 1
    dataStr = 'Functional';
end

% Ensure that only one data object has been inputted
boldData.AssertSingleObject;

% Gather the correct data set
legend = {};
switch lower(dataStr)
    case 'anatomical'
        boldArray = boldData.Data.Anatomical;
    case 'csf'
        csfData = boldData.Data.Segments;
        boldArray = csfData.CSF;
    case 'functional'
        boldArray = boldData.Data.Functional;
    case 'graymatter'
        gmData = boldData.Data.Segments;
        boldArray = gmData.GM;
    case 'ics'
        icData = boldData.Data.ICA;
        legend = fieldnames(icData);
        boldArray = zeros(length(legend), length(icData.(legend{1})));
        for a = 1:length(legend); boldArray(a, :) = icData.(legend{a}); end
    case 'mean'
        boldArray = boldData.Data.Mean;
    case 'nuisance'
        legend = {'Motion', 'Motion', 'Motion', 'Motion', 'Motion', 'Motion', 'Global', 'WM', 'CSF'}';
        nuisanceData = boldData.Data.Nuisance;
        boldArray = [...
                        nuisanceData.Motion;
                        nuisanceData.Global;
                        nuisanceData.WM;
                        nuisanceData.CSF
                    ];                
    case 'whitematter'
        wmData = boldData.Data.Segments;
        boldArray = wmData.WM;
    otherwise
        error('%s is not a recognized data string. Consult the documentation for this function for acceptable options.');
end

% Output the requested data
assignOutputs(nargout, boldArray, legend);