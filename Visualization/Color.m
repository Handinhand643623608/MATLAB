classdef Color
%COLOR - A standardized primitive color class. 

%% CHANGELOG
%   Written by Josh Grooms on 20140717
    
    
    

    %% Color Properties
    
    properties
        R           % Red channel value.
        G           % Green channel value.
        B           % Blue channel value.
    end
    
    
    
    %% Common Color Enumerators
    enumeration
        
        Black       (0, 0, 0)
        Blue        (0, 0, 1)
        Cyan        (0, 1, 1)
        Gray        (0.5, 0.5, 0.5)
        Green       (0, 1, 0)
        Magenta     (1, 0, 1)
        Red         (1, 0, 0)
        White       (1, 1, 1)
        Yellow      (1, 1, 0)
        
    end
    
    
    
    %% Constructor Method
    methods
        function color = Color(r, g, b)
            %COLOR - Constructs a standardized color primitive type.
            if nargin ~= 0
                if nargin == 1 && ischar(r)
                    [r, g, b] = Colors.str2rgb(r);
                elseif nargin ~= 3
                    error('Colors must be specified using a predefined color string or an RGB vector');
                end
                   
                color.R = r; 
                color.G = g; 
                color.B = b;
            end 
        end
    end
        
    
    
    
    %% Object Conversion Methods
    methods
        function rgb = double(color)
            %DOUBLE - Implicitly converts RGB objects into double-precision RBG vectors.
            rgb = color.ToArray;
        end
        function array = ToArray(color, dim)
            %TOARRAY - Converts a color object into an RGB vector along a specified dimension.
            if nargin == 1; dim = 2; end
            array = [color.R, color.G, color.B];
            shape = ones(1, dim); 
            shape(dim) = 3;
            array = reshape(array, shape);
        end
    end
    
            
    
end