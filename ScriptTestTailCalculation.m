%% SCRIPTTESTTAILCALCULATION - Tests arbitrary p-value calculation times using different methods.

%% CHANGELOG
%   Written by Josh Grooms on 20140903



%% Perform the Test
lenReal = 50000;

realData = randn(1, lenReal); 
nullData = randn(1, 5*lenReal);

f = @() testTailCalculation(realData, nullData);
% fc = @() testTailCalculationC(realData, nullData);
fgpu = @() testTailCalculationGPU(realData, nullData);

writeLine = @(msg, varargin) fprintf(1, [msg '\n'], varargin{:});
writeLine('\n');

% Confirm equality of results
% isequal(f(), fc(), fgpu())

if isequal(f(), fgpu()); writeLine('Results are Equivalent'); end
writeLine('');

t = timeit(f, 1);
% tc = timeit(fc, 1);
% tgpu = timeit(fgpu, 1);
tgpu = gputimeit(fgpu, 1);

writeLine('MATLAB Execution Time:   %d s', t);
% writeLine('C Execution Time:        %d s', tc);
writeLine('GPU Execution Time:      %d s', tgpu);

writeLine('\n');



%% Results
% Serial single-CPU using MATLAB code
%   - lenReal = 10000       --> 2.5245s, 2.4275s, 2.4329s, 2.3892s
%   - lenReal = 20000       --> 8.3858s
%   - lenReal = 50000       --> 20.0884s
%
% Serial single-CPU using C code (MEX function)
%   - lenReal = 10000       --> 1.4219s, 1.4220s, 1.4023s
%   - lenReal = 20000       --> 5.6442s
%   - lenreal = 50000       --> 35.3052s
%
% Parallel GPU calculation using MATLAB code (i.e. gpuArray)
%   - lenReal = 10000       --> 6.0777s, 6.0817s, 5.9822s
%   - lenReal = 20000       --> 12.3992s
%   - lenReal = 50000       --> 31.6724s
%
% Parallel GPU calculation using MATLAB code (i.e. gpuArray) & single precision data
%   - lenReal = 50000       --> 32.0432s, 32.0253s