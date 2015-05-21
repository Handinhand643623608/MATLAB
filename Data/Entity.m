classdef (Abstract, HandleCompatible) Entity
% OBJECT - A universal base class template for all of the MATLAB classes I have written.

%% CHANGELOG
%   Written by Josh Grooms on 20150211
    


	%% UNIVERSAL UTILITIES
	methods
		function Save(H, name)
			H.NotYetImplemented();
		end
	end
	
	
    
    %% ERROR HANDLING
    methods (Hidden, Access = protected)
        function AssertSingleObject(H)
        % ASSERTSINGLEOBJECT - Throws a standardized exception if an array of multiple objects is detected.
            if (numel(H) > 1)
                fname = dbstack(1);
                throwAsCaller(Object.MultipleObjectException(inputname(1), fname.name));
            end
        end
        function AssertMultipleObjects(H)
		% ASSERTMULTIPLEOBJECTS - Throws a standardized exception if a single object is illegally detected.
            if (numel(H) < 2)
                fname = dbstack(1);
                throwAsCaller(Object.SingleObjectException(inputname(1), fname.name));
            end
        end
        function NotYetImplemented(~)
        % NOTYETIMPLEMENTED - Throws a standardized exception to indicate that functionality has not yet been implemented.
            fname = dbstack(1);
            throwAsCaller(Object.NotImplementedException(fname.name));
		end
    end
    
    methods (Hidden, Static, Access = protected)
        function E = MultipleObjectException(vname, fname)
        % MULTIPLEOBJECTEXCEPTION - Constructs a standard exception to be thrown when illegal object arrays are detected.
        %
        %   INPUTS:
        %       vname:      STRING
        %                   The name of the offending variable in the function workspace.
        %
        %       fname:      STRING
        %                   The name of the function or file in which the problem was detected.
            E = MException('Object:MultipleObjects', 'The argument %s in %s cannot be an array of objects.', vname, fname);
        end
        function E = NotImplementedException(fname)
        % NOTIMPLEMENTEDEXCEPTION - Constructs a standard exception to be thrown when unimplemented functionality is invoked.
            E = MException('Object:NotImplemented', 'The functionality in %s has not yet been implemented.', fname);
        end
        function E = SingleObjectException(vname, fname)
		% SINGLEOBJECTEXCEPTION - Constructs a standard exception to be thrown when object arrays are required.
            E = MException('Object:SingleObject', 'The argument %s in %s must be an array of objects.', vname, fname);
        end
    end
    
    
    
end