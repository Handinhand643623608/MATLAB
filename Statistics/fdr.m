% FDR - Calculates a FWER-corrected p-value cutoff using Benjamini-Hochberg control of false discovery rate.
%
%   SYNTAX:
%       cutoff = fdr(p, alpha)
%
%   OUTPUT:
%       cutoff:     DOUBLE
%                   The scalar cutoff below which p-values are considered statistically significant. If no significance
%                   is found in the inputted data, this function returns "NaN" as the cutoff value.
%
%   INPUTS:
%       p:			[ DOUBLES ]
%                   An array of p-values for which the significance cutoff is needed.
%   
%       alpha:      DOUBLE
%                   The desired significance cutoff after correcting for multiple comparisons. This is the same alpha
%                   from classical statistics that determines confidence interval width and is very commonly given the
%                   value 0.05 (i.e. to generate a 95% confidence interval).

%% CHANGELOG
%   Written by Josh Grooms on 20141106



%% FUNCTION DEFINITION
function cutoff = fdr(p, alpha)
	
	% Sort the p-values into ascending order
	p = sort(p(:));

	% Create a weighting vector for each of the p-values
	weights = alpha * ( (1:length(p)) / length(p) );

	% Find where p-values are less than their corresponding weighting elements (these are significant)
	idsSig = p <= weights;

	% The maximum significant p-value is then the cutoff
	if (~any(idsSig)); cutoff = NaN; return; end
	cutoff = p(idsSig);
	cutoff = cutoff(end);
	
end