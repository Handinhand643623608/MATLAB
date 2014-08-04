function plot(relationData, varargin)
%PLOT Displays the relation data with various options.
%
%   SYNTAX:
%   plot(relationData, 'PropertyName', PropertyValue,...)
%
%   PROPERTY NAMES:
%
%   Written by Josh Grooms on 20130429
%       20130613:   Added plot default settings to use a black background & white text. Updated
%                   coherence plots to include larger text (labels & titles). Coherence plots are
%                   now saved to both .png & .fig files for easy future editing. Began adding
%                   sections for correlation plots. 


%% Initialize
% Initialize a defaults & settings structure
inStruct = struct(...
    'AxesColor', 'w',...
    'Color', 'k',...
    'CutoffColor', 'r',...
    'ErrorColor', 'g',...
    'LineColor', 'b',...
    'XTickLabels', [],...
    'YTickLabels', []);
assignInputs(inStruct, varargin);
    
    

switch lower(relationData(1, 1).Relation)
    
    case 'coherence'
        %% Plot the Coherence Data
        switch lower(relationData(1, 1).Parameters.MaskMethod)
            case 'correlation'
                channels = relationData(1, 1).Parameters.Channels;
                maskStrs = {'corr', 'acorr'};
                properMaskStrs = {'Correlation', 'Anticorrelation'};
                
                for a = 1:size(relationData, 1)
                    for b = 1:size(relationData, 2)
                        for c = 1:length(maskStrs)
                            for d = 1:length(channels)
                                
                                dataStr = [maskStrs{c} channels{d}];
                                currentData = relationData(a, b).Data.Coherence.(dataStr);
                                currentSEM = relationData(a, b).Data.SEM.(dataStr);                                
                                freqs = relationData(a, b).Data.Frequencies;
                                
                                if isfield(relationData(a, b).Parameters, 'Cutoffs')
                                    currentCutoff = relationData(a, b).Parameters.Cutoffs.(dataStr);
                                end
                                
                                figure;
                                plot(freqs, currentData, LineColor, 'LineWidth', 2)
                                hold on
                                plot(freqs, currentData + currentSEM, ErrorColor)
                                plot(freqs, currentData - currentSEM, ErrorColor)
                                if exist('currentCutoff', 'var')
                                    plot(freqs, currentCutoff*ones(1, length(currentData)), ['--' CutoffColor], 'LineWidth', 2);
                                end
                                xlabel('Frequency (Hz)', 'FontSize', 14)
                                ylabel('MS Coherence', 'FontSize', 14)
                                titleStr = sprintf('Average %s-BOLD', channels{d});
                                saveStr = sprintf('Average %s-BOLD (Top 12.5%% of %s Values)',...
                                    channels{d}, properMaskStrs{c});
                                title(titleStr, 'Color', AxesColor, 'FontSize', 16)
                                
                                set(gcf,...
                                    'Color', Color,...
                                    'InvertHardcopy', 'off');
                                
                                set(gca,...
                                    'Color', Color,...
                                    'FontSize', 12,...
                                    'XColor', AxesColor,...
                                    'YColor', AxesColor);
                                    
                                
                                saveas(gcf, [saveStr '.png'], 'png')
                                saveas(gcf, [saveStr '.fig'], 'fig')
                                close
                            end
                        end
                    end
                end
        end
        
    case 'correlation'
%         
%         for a = 1:size(relationData, 1)
%             for b = 1:size(relationData, 2)
%                 if ~isempty(relationData(a, b).Data)
%                     
%                     if isstruct(relationData(a, b).Data.Correlation)
%                         dataFields = fieldnames(relationData(a, b).Data.Correlation);
%                         
%                         for c = 1:length(dataFields)
%                             currentData = relationData(a, b).Data.Correlation.(dataFields{c});                           
%                                                         
%                             switch relationData(a, b).Modalities
%                                 case 'EEG-BOLD'
%                                     
%                                     currentData = permute(currentData, [2 1 3 4]);
%                                     
%                                     % X = Slices, Y = Time Shifts
%                                     shiftsToPlot = ismember(YTickLabels, relationData(a, b).Parameters.TimeShifts);
%                                     currentData = currentData(:, :, XTickLabels, YTickLabels);
%                                     corrPlot = brainPlot(...                
%                                         'ColorbarLabel', 'Pearson r',...
%                                         'Data', currentData,...
%                                         'Modality', 'fMRI',...
%                                         'Title', [dataFields{c} '-BOLD Correlation'],...
%                                         'XDim', 3,...
%                                         'XLabel', 'Slice',...
%                                         'XTickLabels', XTickLabels,...
%                                         'YDim', 4,...
%                                         'YLabel', 'Time Shift',...
%                                         'YTickLabels', YTickLabels);
%                                     
%                                 case {'EEG-IC', 'EEG-Global'}
%                                     
%                                     % X = Time Shifts, Y = RSNs
%                                     corrPlot = brainPlot(...                
%                                         'ColorbarLabel', 'Pearson r',...
%                                         'Data', currentData,...
%                                         'Modality', 'fMRI',...
%                                         'Title',
%                                         'XDim', 
%                                         'XLabel', 'Slice',...
%                                         'XTickLabels', 
%                                         'YDim', 
%                                         'YLabel', 'Time Shift',...
%                                         'YTickLabels', 
%                             end
%                         end
%                         
%                     else
%                         
%                         switch relationData(1, 1).Modalities
%                             case {'EEG-BOLD', 'Global-BOLD'}
% 
% 
%                                 currentData = relationData(a, b).Data
% 
%                                 imageAspectRatio = 
% 
% 
%                                 corrPlot = brainPlot(...                
%                                     'ColorbarLabel', 'Pearson r',...
%                                     'Data', relationData,...
%                                     'Modality', 'fMRI',...
%                                     'XDim', 3,...
%                                     'XLabel', 'Slice',...
%                                     'XTickLabels', 
%                                     'YDim', 4,...
%                                     'YLabel', 'Time Shift',...
%                                     'YTickLabels', 
% 
% 
%                             case {'EEG-IC', 'EEG-Global'}
% 
%                                 imageAspectRatio = [1 1];
% 
% 
%                                 corrPlot = brainPlot(...                
%                                     'ColorbarLabel', 'Pearson r',...
%                                     'Data', relationData,...
%                                     'Modality', 'fMRI',...
%                                     'XDim', 
%                                     'XLabel', 'Slice',...
%                                     'XTickLabels', 
%                                     'YDim', 
%                                     'YLabel', 'Time Shift',...
%                                     'YTickLabels', 
% 
%                         end
%                     end
%         
end
                        
                
                