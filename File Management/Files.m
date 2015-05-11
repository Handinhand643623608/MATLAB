classdef Files < hgsetget
% FILES - A personalized class for storing and managing frequently used files.

%% CHANGELOG
%   Written by Josh Grooms on 20141016
%       20141110:   Changed the ColinBrain static property to refer instead to a permanently adjusted Colin Brain data
%                   set, since this is what is most frequently used. The raw Colin Brain data set will now have to be
%                   used manually.
%		20150511:	Updated for compatibility with changes to file management objects.



    %% Static Properties
    
    methods (Static)
        function F = BOLD
        % Gets a File array referencing all current infraslow BOLD data objects.
            F = Paths.BOLD.FileSearch('boldObject.*\.mat');
        end
        function F = ColinBrain
        % Gets the File object referencing the Colin Brain data set.
            F = [Paths.Common '/ColinBrainAdjusted.mat'];
        end
        function F = EEG
        % Gets a File array referencing all current infraslow EEG data objects.
            F = Paths.EEG.FileSearch('eegObject.*\.mat');
        end
    end
    
    
    
end