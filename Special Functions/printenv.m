% PRINTENV - Prints a list of environment variable names and their current values.

%% CHANGELOG
%	Written by Josh Grooms on 20150723



%% FUNCTION DEFINITION
function v = printenv

	if ispc
		[~, v] = dos('SET');
	else
		[~, v] = unix('printenv');
	end
	v = strsplit(v, '\n')';
	
% 	v = cellfun(@(x) strsplit(x, '='), v, 'UniformOutput', false);
% 	v = [v{:}];
	v(end) = [];
	
% 	v = struct(v{:});
	

end