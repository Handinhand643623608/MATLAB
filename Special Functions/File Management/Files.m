classdef Files < hgsetget
% FILES - A personalized class for storing and managing frequently used files.

%% CHANGELOG
%   Written by Josh Grooms on 20141016



    %% Static Properties
    
    methods (Static)
        function F = BOLD
            % Gets a File array referencing all current infraslow BOLD data objects.
            F = Paths.BOLD.FileSearch('boldObject.*.mat');
        end
        function F = EEG
            % Gets a File array referencing all current infraslow EEG data objects.
            F = Paths.EEG.FileSearch('eegObject.*.mat');
        end
    end
    
    
    
end