function [boldMatrix, idsNaN] = ToMatrix(boldData, removeNaNs)
%TOMATRIX - Extracts BOLD functional data and flattens it to a two dimensional matrix.
%
%   SYNTAX:
%   boldMatrix = ToMatrix(boldData)
%   boldMatrix = ToMatrix(boldData, removeNaNs);
%   [boldMatrix, idsNaN] = ToMatrix(...);
%
%   OUTPUT:
%   boldMatrix:     2D ARRAY
%                   The functional image data stored inside the BOLD data object flattened into a two-dimensional array.
%                   This array is formatted as [VOXELS x TIME]. Each row represents a single voxel. Each column
%                   represents a single time point. To restore the original functional data array, use RESHAPE with the
%                   original data dimensions as the size input.
%
%                   EXAMPLE:
%                       % Create a 2D array out of the functional data
%                       funData = ToMatrix(boldData);
%                       % Restore the original array
%                       funData = reshape(funData, [91, 109, 91, 218]);
%
%   OPTIONAL OUTPUT:
%   idsNaN:         [BOOLEANS]
%                   The indices of NaN voxels. This parameter is a vector of Booleans of length equal to the number of
%                   rows of the flattened functional data matrix (before NaN time series removal). Elements of this
%                   vector are true when corresponding elements in the first column of the BOLD matrix are NaN. If this
%                   output is requested without providing a value for the 'removeNaNs' argument, then that argument
%                   defaults to true and NaNs are automatically removed from the data.
%
%                   The primary use of this variable is to restore the original size of the flattened data matrix, which
%                   is a necessary step prior to reshaping it into a volume array (see the example above).
%
%   INPUT:
%   boldData:       BOLDOBJ
%                   A single BOLD data object. Arrays of BOLD objects are not supported.
%
%   OPTIONAL INPUT:
%   removeNaNs:     BOOLEAN
%                   Remove any voxels with time series composed entirely of NaNs. These frequently represent non-brain
%                   space in volume (such as the volume surrounding the brain or the ventricles). Removing these filler
%                   values significantly reduces the size of the data array. If this parameter is not supplied as an
%                   input argument, then it defaults to true only if the 'idsNaN' output is requested by the caller.
%                   Otherwise, if only one output is requested ('boldMatrix'), this defaults to false and NaNs are not
%                   removed from the data matrix. Manually specifying this argument overrides these default behaviors.
%                   DEFAULT: 
%                       true    - If two outputs are requested (i.e. including idsNaN)
%                       false   - If only one output is requested

%% CHANGELOG
%   Written by Josh Grooms on 20140618
%       20140701:   Implemented the ability to automatically remove NaNs from the flattened matrix and to return the
%                   indices of them. Removing NaNs is set to be performed by default. Updated documentation.
%       20140729:   Changed this function so that the removal of NaNs from the data is performed automatically if two
%                   outputs are requested but only one input is provided. Updated documentation.



%% Extract & Flatten the Functional Data
% Fill in missing inputs
if nargin == 1
    if (nargout == 1); removeNaNs = false;
    else removeNaNs = true;
    end
end

% Ensure that only one object is converted at a time
boldData.AssertSingleObject;

% Pull functional data from the object & flatten it to two dimensions
boldMatrix = boldData.Data.Functional;
boldMatrix = reshape(boldMatrix, [], size(boldMatrix, 4));

% Remove NaNs from the data matrix, if called for
idsNaN = isnan(boldMatrix(:, 1));
if istrue(removeNaNs); boldMatrix(idsNaN, :) = []; end