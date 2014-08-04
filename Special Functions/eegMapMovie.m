function eegMapMovie(data)
%EEGMAPMOVIE
%
%   SYNTAX:
%
%   INPUT:
%   data:

%% CHANGELOG
%   Written by Josh Grooms on 20140716



%%

[funFolder, ~, ~] = fileparts(which('eegMapMovie.m'));
imFolder = [pwd '/tempMapImages'];
mkdir(imFolder);

imSaveName = '%s/%03d.%s';

mapData = eegMap(data(:, 1));


for a = 2:size(data, 2)
    
    
end