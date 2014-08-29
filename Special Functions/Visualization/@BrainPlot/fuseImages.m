function fusedImage = FuseImages(boldImage, anatomicalImage, clim)
%FUSEIMAGES - Fuse anatomical and thresholded functional images to create the appearance of an anatomical underlay.
%   This function combines thresholded functional images with anatomical images so that insignificant functional data
%   appear as a structural scan.
%
%   SYNTAX:
%   fusedImage = BrainPlot.FuseImages(boldImage, anatomicalImage, clim)
%
%   OUTPUT:
%   fusedImage:             3D ARRAY
%                           An RGB array (colors in the third dimension) of the combined anatomical and functional data.
%                           Display this array using the IMAGE function (do not use scaling, which is done automatically 
%                           in IMAGESC).
%
%   INPUTS:
%   boldImage:              2D ARRAY
%                           A two dimensional array of functional data. Each element of the array represents the
%                           intensity value of a BOLD voxel. Typically, this will be a single slice of fMRI data at a
%                           single time point, inputted as a two-dimensional array. Any voxels in this array that will
%                           be invisible (i.e. the anatomical image will be shown instead) should have their instensity
%                           values set to NaN.
%
%   anatomicalImage:        2D ARRAY
%                           A two dimensional array of anatomical data. This must be exactly the same size as the
%                           functional data or an error will occur. Typically, this will be a single slice of MRI data.
%                           This array may also be empty, in which case only the outputted array is the BOLD image
%                           converted to RGB values. 
%
%   clim:                   [DOUBLE, DOUBLE]
%                           Color limits to be imposed on the conversion to RGB values. Typically, this is the [MIN MAX]
%                           of the entire data set so that color values are consistent everywhere.

%% CHANGELOG
%   Written by Josh Grooms on 20130703
%       20140625:   Updated the documentation of this function. Removed the option to input 3D arrays as it was
%                   confusing, never used, and difficult to implement well.
%       20140828:   Updated to allow for empty anatomical images (in which case only BOLD data is converted). Optimized
%                   this function somewhat and improved error checking. Updated documentation.



%% Fuse the Images
% Ensure that only 2D arrays are being inputted
if ~ismatrix(boldImage) || ~ismatrix(anatomicalImage)
    error('Only two-dimensional images may be fused together using the FuseImages function');
end

% Check for errors in the sizes of input images
if ~isempty(anatomicalImage) && ~isequal(size(boldImage), size(anatomicalImage))
    error('BOLD & Anatomical images must be of equivalent size');
end

% Convert the BOLD image to RGB values
boldImage(boldImage == 0) = NaN;
fusedImage = scale2rgb(boldImage, 'CLim', clim);

% If no anatomical image is provided, just return the converted BOLD image
if isempty(anatomicalImage); return; end
   
% Convert the anatomical image to RGB values
anatomicalImage(anatomicalImage == 0) = NaN;
anatomicalImage = scale2rgb(double(anatomicalImage), 'Colormap', gray(256));

% Fuse the images where BOLD data is thresholded
idsNaN = isnan(boldImage(:));
anatomicalImage = reshape(anatomicalImage, [], 3);
fusedImage = reshape(fusedImage, [], 3);
fusedImage(idsNaN, :) = anatomicalImage(idsNaN, :);
fusedImage = reshape(fusedImage, size(boldImage));

