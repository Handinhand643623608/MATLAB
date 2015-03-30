classdef Cell
	
	
	methods (Static)
		
		
		function y = Reduce(x)
			
			
		end
		
		
		function s = ToStruct(c)
			
			assert(isnvp(c), 'Converting a cell to a structure requires a fieldname/value paired list.');
			s = struct(c{:});
		end
		
		
		
	end
	
	
	
end