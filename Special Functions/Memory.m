classdef Memory
% MEMORY - A static class that monitors memory usage

%% CHANGELOG
%   Written by Josh Grooms on 20141111
    
    
    methods (Static)
        
        function m = Available
        % AVAILABLE - Gets the total amount of free memory.
        %   This is the total amount of memory (physical RAM + swap space) that is currently unoccupied. This memory is
        %   therefore available for data allocation and computation. The value of this property is specified in units
        %   dictated by the UNITS property (bytes, by default).
            m = memory;
            m = Memory.Convert(m.MemAvailableAllArrays);
            
        end
        function m = AvailableRAM
        % AVAILABLERAM - Gets the amount of free physical memory.
        %   This is the amount of physical RAM that is currently unoccupied. This memory is therefore available for data
        %   allocation and computation. The value of this property is specified in units dictated by the UNITS property
        %   (bytes, by default).
            [~, m] = memory;
            m = Memory.Convert(m.PhysicalMemory.Available);
        end
        function m = InUse
        % INUSE - Gets the amount of physical memory being used by MATLAB.
        %   This is the amount of physical RAM that is currently occupied by the open MATLAB instance. This memory is
        %   already allocated and therefore not available for use. The value of this property is specified in units
        %   dictated by the UNITS property (bytes, by default).
            m = memory;
            m = Memory.Convert(m.MemUsedMATLAB);
        end
        function n = MaxNumDoubles
        % MAXNUMDOUBLES - Gets the maximum number of double-precision values that can currently be allocated.
            n = floor(Memory.Available / 8);
        end
        function n = MaxNumSingles
        % MAXNUMSINGLES - Gets the maximum number of single-precision values that can currently be allocated.
            n = floor(Memory.Available / 4);
        end
        function m = TotalRAM
        % TOTALRAM - Gets the total amount of physical memory installed.
        %   This is the total amount of physical RAM that is installed on the computer that the open MATLAB instance is
        %   running on. It gives no indication of how much memory is available or in use. The value of this property is
        %   specified in units dictated by the UNITS property (bytes, by default).
            [~, m] = memory;
            m = Memory.Convert(m.PhysicalMemory.Total);
        end
        function m = Swap
        % SWAP - Gets the amount of swap space allocated.
        %   This is the amount of hard drive space that has been allocated for use in memory paging. Swap space is
        %   typically consumed when the available physical RAM is mostly occupied; data that cannot fit in the available
        %   RAM blocks are allocated instead on the hard drive. Swap space is useful for dramatically and cheaply
        %   increasing the amount of available memory beyond what may be feasible for a computer system. Blocks of swap
        %   space memory can be written to and read from freely just like RAM (but called paging instead), although this
        %   process is far slower than it is on physical memory modules. The value of this property is specified in
        %   units dictated by the UNITS property (bytes, by default).
            m = Memory.Convert(Memory.Available - Memory.TotalRAM);
        end
        
        function varargout = Units(unit)
        % UNITS - Gets or sets the unit of memory measurement to use.
        %
        %   SYNTAX:
        %       u = Memory.Units        - Gets the current unit of memory measurement.
        %       Memory.Units(value)     - Sets a new unit of memory measurement.
        %
        %   OUTPUT:
        %       u:          STRING
        %
        %   INPUT:
        %       value:      STRING
            persistent u;
            if (nargin == 0);
                if (isempty(u)); u = 'Bytes'; end
                varargout{1} = u;
                return
            else
                assert(ischar(unit), 'Memory units must be specified using a valid string.');
                u = unit;
                return;
            end
        end
        
    end
    
    methods (Static, Access = private)

        function m = Convert(m)
        % CONVERT - Converts an input specified in bytes to another unit of memory measurement.
            u = Memory.Units;            
            switch (u)
                case {'Bits', 'b'}
                    m = m*8;
                case {'Bytes', 'B'}
                    m = m;
                case {'Kilobytes', 'kB'}
                    m = m/1024;
                case {'Megabytes', 'MB'}
                    m = m/(1024^2);
                case {'Gigabytes', 'GB'}
                    m = m/(1024^3);
                case {'Terabytes', 'TB'}
                    m = m/(1024^4);
            end
        end
        
    end
    
    
    
    
end