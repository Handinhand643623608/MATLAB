function fusedImage = fuseImages(boldImage, anatomicalImage, clim)
%FUSEIMAGES Fuse anatomical and thresholded functional images.
%   This function combines thresholded functional images with anatomical images so that insignificant functional data
%   appear as a structural underlay.
%
%   SYNTAX:
%   fusedImage = fuseImages(boldImage, anatomicalImage, clim)
%
%   OUTPUT:
%   fusedImage:             3D ARRAY
%                           An RGB array (colors in the third dimension) of the combined anatomical and functional data.
%                           Display this array using the IMAGE function (do not use scaling).
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
%
%   clim:                   [DOUBLE, DOUBLE]
%                           Color limits to be imposed on the conversion to RGB values. Typically, this is the [MIN MAX]
%                           of the entire data set so that color values are consistent everywhere.

%% CHANGELOG
%   Written by Josh Grooms on 20130703
%       20140625:   Updated the documentation of this function. Removed the option to input 3D arrays as it was
%                   confusing, never used, and difficult to implement well.



%% Fuse the Images
% Input image size error checking
if ~isequal(size(boldImage), size(anatomicalImage)) || ~ismatrix(boldImage)
    error('BOLD & Anatomical images must be of equivalent size');
end

% Convert BOLD & anatomical images to RGB values
boldImage(boldImage == 0) = NaN;
rgbBOLD = scale2rgb(boldImage, 'CLim', clim);
anatomicalImage(anatomicalImage == 0) = NaN;
anatomicalImage = scale2rgb(double(anatomicalImage), 'Colormap', gray(256));

% Fuse the images where BOLD data is thresholded
fusedImage = reshape(anatomicalImage, [], 3);
rgbBOLD = reshape(rgbBOLD, [], 3);
fusedImage(~isnan(boldImage(:)), :) = rgbBOLD(~isnan(boldImage(:)), :);
fusedImage = reshape(fusedImage, size(anatomicalImage));

