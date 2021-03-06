function comparison = pval_arbitrary(tested_values,null_distribution,direction)
% PVAL_ARBITRARY
% Gives a p value for an arbitrary distribution if a null distribution is
% given as well.  Tests each element in the arbitrary distribution against
% the null distribution.
%
% pval                      Output probability (p) values
%   = pval_arbitrary(
%       tested_values,      The arbitrary distribution
%       null_distribution,  The equivalent null distribution
%       direction           Which probability to test
%                           'h'     Probability of higher than distribution
%                           'l'     Probability of lower than distribution
%                           (More of these can be added to this function as needed)
%       )
%
% See also: fishersmethod.m for combining a list of p values into one p
% value
% 
% Editted by Josh Grooms on 8/14/2012 to rewrite comparison section (memory errors) & implement parallel computing (increase speed)
%   Updated on 1/19/2013 to include progressbars

if ~exist('direction','var') || isempty(direction)
    direction = 'h';
end

parallelSwitch = matlabpool('size');

% Flatten
null_distribution = reshape(null_distribution,[numel(null_distribution),1]);
tested_values = reshape(tested_values,[1,numel(tested_values)]);

% Sort null distribution
null_distribution = sort(null_distribution,'ascend');

% % Get the percentile of each element in the tested values
% % Repmat to same size (causes memory errors)
% null_distribution = repmat(null_distribution,[1 size(tested_values,2)]);
% tested_values = repmat(tested_values,[size(null_distribution,1) 1]);
% 
% % Calculate
% switch direction
%     case 'h'
%         comparison = tested_values <= null_distribution;
%     case 'l'
%         comparison = tested_values >= null_distribution;
%     otherwise
%         error('Must specify whether to test against high or low distribution.');
% end
% % Take the sum along the null distribution dimension
% comparison = sum(comparison,1);

comparison = zeros(1, length(tested_values));
if parallelSwitch == 0
    progressbar('Arbitrary P-Values Calculated')
    try
        for i = 1:length(tested_values)
            currentCompVec = zeros(length(null_distribution), 1);
            switch direction
                case 'h'
                    currentCompVec = null_distribution >= tested_values(i);
                case 'l'
                    currentCompVec = null_distribution <= tested_values(i);
            end
            currentCompVec = sum(currentCompVec);
            comparison(i) = currentCompVec;

            progressbar(i/length(tested_values));
        end
    catch err
        saveStr = 'partPVals.mat';
        save([pwd '\' saveStr], 'comparison', 'i', 'tested_values', 'null_distribution', 'direction', 'parallelSwitch', '-v7.3');
        rethrow(err)
    end
else
    try
        progressbar('Arbitrary P-Values Calculated')
        lengthLoop = length(tested_values);
        parfor i = 1:length(tested_values)
            currentCompVec = zeros(length(null_distribution), 1);
            switch direction
                case 'h'
                    currentCompVec = null_distribution >= tested_values(i);
                case 'l'
                    currentCompVec = null_distribution <= tested_values(i);
            end
            currentCompVec = sum(currentCompVec);
            comparison(i) = currentCompVec;
            progressbar(i/lengthLoop)
        end
    catch err
        saveStr = 'partPVals.mat';
        save([pwd '\' saveStr], 'comparison', 'i', 'tested_values', 'null_distribution', 'direction', 'parallelSwitch', '-v7.3');
        rethrow(err)
    end
end

% Divide by the number in the null distribution
comparison = comparison ./ size(null_distribution,1);
% % Fisher's method
% if length(comparison) > 1
%     [~, pval] = fishersmethod(comparison);
% else
%     pval = comparison;
% end