function ProfilePValueGeneration
% PROFILEPVALUEGENERATION - Profiles the execution time of various p-value generation algorithms.
%	
%   This function tests how much time is required on average to execute various approaches to p-value generation for
%	arbitrary data distributions. The purpose of this test is to optimize the process for use with my research data,
%	for which it requires a substantial amount of time.
%
%	APPROACHES:
%		The approaches to generating p-values that are tested using this function are as follows:
%		
%			1. Native               - Generation using ordinary MATLAB-native functions.
%			2. Parallel             - Generation using method 1 but parallelized (i.e. Native + parfor)
%			3. Block                - Generation using vectorization on memory-conscious blocks of data.
%			4. C                    - Generation using a mex function written in the C language with ordinary functions.
%           5. CIntel               - Generation using a mex function written in C and compiled using the Intel C Compiler
%           6. CIntelAutoParallel   - Generation using the Intel compiler auto-parallelization feature.
%           7. Cilk                 - Generation using a Cilk multithreaded mex function.
%           8. GPU                  - Generation using my home computer's GPU (EVGA GTX 780) and native MATLAB code.
%
%	20141114 CONCLUSIONS:
%		Block processing (method 3) is definitely not the way to go. Not only is it consistently the slowest, its the
%		slowest by FAR. See the results images for details, but it was painful letting this method run to completion. I
%		actually expected this approach to be the best because it should take advantage of MATLAB's vectorization, which
%		should be pretty optimized. This seems not to be the case, though.
%
%		The native, single-threaded, ordinary iterative approach (method 1) is the next slowest up until about 25000
%		samples are involved. At this point, something interesting happens and its performance becomes noticeable better
%		than the C mex function. Some kind of optimization or multithreading must kick in around this sample count, but
%		I'll probably never know since all of it is closed source and basically inaccessible.
%
%		The parallel approach (method 2) is the quickest of the CPU-based methods tested so far. It is consistently the
%		leader in execution time, at least up to 50000 samples. Method 1 begins running parallel to it after its
%		behavior changes at ~25000 samples, but it still lags behind by a few seconds.
%
%		The C mex function approach (method 4) performs quite well up until whatever optimization kicks in for method 1.
%		After that, it becomes the slowest. Getting multithreading working would likely help this approach out a lot.
%
%   20141122 CONCLUSIONS:
%       These are new conclusions based on usage of the Intel C/C++ optimizing compiler (v15.0). Use of this compiler
%       has also enabled me to test multithreaded C approaches to p-value generation.
%
%       Compiling the MEX function using the Intel v15.0 C compiler has resulted in impressive speed gains for empirical
%       cdf generation. Even the single-threaded function (method 5) vastly outperforms the MATLAB-native parallel
%       implementation (method 2). Enabling the automatic parallelizing compiler option seems to make no difference,
%       however. This is either because the original function (method 5) is already automatically parallelized or
%       because the new function (method 6) isn't being properly automatically parallelized.
%
%       Explicit multithreading in the MEX function was tested using Cilk, which is packaged with the Intel C/C++
%       compiler. Use of this package also allows for explicitly setting the number of worker threads to be employed.
%       Performance was tested over a range of thread counts using lenReal = lenNull = 100,000 to generate Gaussian
%       randomly distributed data sets. The results are listed below:
%
%           Average Execution Times for 100,000 Sample Count:
%               Method 5 - Reference:   5.5637s
%               Method 6 - 1 Thread:    39.2246s
%               Method 6 - 2 Threads:   27.1614s
%               Method 6 - 4 Threads:   19.7343s
%               Method 6 - 8 Threads:   14.3737s
%
%       Clearly, increasing the thread counts improves function performance. However, the addition of Cilk in general
%       seems to dramatically slow things down, at least with data sample counts in this range. It's not clear yet how
%       these functions would perform up around the 4e6 sample counts of my actual data.
%
%       I have also tested out the GPU performance (method 8) earlier this week, but only up to 50,000 samples. It's
%       performance is predictably poor, but it does manage to outperform method 4 up at 50,000 samples. The slope of
%       the curve also appears fairly low up in this region, so it's possible it will outperform other methods as the
%       sample count increases. However, I'm not sure I'll be doing benchmarks for such high counts because the time
%       required is so high, so for now that's just speculation. Getting a working CUDA program would also probably
%       help.

%% CHANGELOG
%	Written by Josh Grooms on 20141114



%% Perform the Profiling
lengthsToUse = 0:10000:50000;		% The number of samples that will be in the real data distribution

% Initialize a structure containing which approaches to run
approaches = struct(...
    'Native',               false,...
    'Parallel',             false,...
    'Block',                false,...
    'C',                    false,...
    'CIntel',               true,...
    'CIntelAutoParallel',   false,...
    'Cilk',                 true,...
    'GPU',                  false);
    
names = fieldnames(approaches);
toRun = struct2array(approaches);
namesToRun = names(toRun);

t = zeros(length(lengthsToUse), length(namesToRun));

writeLine = @(msg, varargin) fprintf(1, [msg '\n'], varargin{:});
writeLine('\n');

for a = 1:length(lengthsToUse)
	
	lenReal = lengthsToUse(a);
	realData = randn(lenReal, 1); 
	nullData = randn(5*lenReal, 1);
	
    for b = 1:length(namesToRun)
		f = getfunhandle(namesToRun{b}, realData, nullData);
		t(a, b) = timeit(f, 1);
        writeLine('%s profiling complete', namesToRun{b});
    end
	writeLine('\n%d sample test complete\n', lenReal);

% 	writeLine('Native Execution Time:   %d s', t);
% 	writeLine('Block Execution Time:	%d s', tb);
% 	writeLine('C Execution Time:        %d s', tc);
%   writeLine('GPU Execution Time:      %d s', tgpu);

% 	writeLine('\n');
end

writeLine('\n');

figure;
plot(lengthsToUse, t);
legend(namesToRun{:});
ylabel('Time (s)');
xlabel('Number of Dist. Samples');

end


%% Helper Functions
function f = getfunhandle(fun, r, n)
% GETFUNCTION - Gets the function handle associated with an approach name string.
%
%	SYNTAX:
%		f = GetFunction(fun, r, n)
%
%	OUTPUT:		
%		f:		FUNCTION HANDLE
%				The function handle referencing the logic behind the approach being tested.
%
%	INPUTS:
%		fun:	STRING
%				The name of the approach being tested.
%
%		r:		[ DOUBLES ]
%				The real data distribution.
%
%		n:		[ DOUBLES ]
%				The null data distribution.
	switch fun
		case 'Native'
			f = @() NativeGeneration(r, n);
			return;
		case 'Parallel'
			f = @() NativeParallelGeneration(r, n);
			return;
		case 'Block'
			f = @() NativeBlockGeneration(r, n);
			return;
		case 'C'
			f = @() CGeneration(r, n);
        case 'CIntel'
            f = @() CIntel(r, n);
        case 'CIntelAutoParallel'
            f = @() CIntelAutoParallel(r, n);
        case 'Cilk'
            f = @() CilkGeneration(r, n);
		case 'GPU'
			f = @() NativeGPUGeneration(r, n);
		otherwise
			error('Not a recognized approach name.');
	end

end




%% Approaches to be Evaluated
function pvals = NativeGeneration(realData, nullData)
% NATIVEGENERATION - Generates the lower p-value tail using native MATLAB methods.

	lenReal = length(realData);
	lenNull = length(nullData);

	pvals = zeros(1, lenReal);

	for a = 1:lenReal
		pvals(1, a) = sum(nullData <= realData(a)) / lenNull;
	end

end

function pvals = NativeParallelGeneration(realData, nullData)
% NATIVEPARALLELGENERATION - Generates the lower p-value tail using native MATLAB parallel CPU methods.

	lenReal = length(realData);
	lenNull = length(nullData);
	
	pvals = zeros(1, lenReal);
	
	parfor (a = 1:lenReal)
		pvals(a) = sum(nullData <= realData(a)) / lenNull;
	end

end

function pvals = NativeBlockGeneration(realData, nullData)
% NATIVEBLOCKGENERATION - Generates the lower p-value tail using maximally sized blocks of data (vectorization).
	
	lenReal = length(realData);
	lenNull = length(nullData);
	
	numReps = floor(Memory.MaxNumDoubles / (2 * lenNull));
	numReps = min(numReps, lenReal);
	nrep = repmat(nullData', numReps, 1);
	
	pvals = zeros(1, lenReal);

	for a = 1:numReps:lenReal
		xrep = repmat(realData(a:a + numReps - 1), 1, lenNull);
		xrep = xrep >= nrep;

		pvals(a:a + numReps - 1) = sum(xrep, 2) ./ lenNull;
	end

end

function pvals = NativeGPUGeneration(realData, nullData)
% NATIVEGPUGENERATION - Generates the lower p-value tail using native MATLAB GPU methods.

	lenReal = length(realData);
	lenNull = length(nullData);

	gpuReal = gpuArray(realData);
	gpuNull = gpuArray(nullData);
	gpuPVals = gpuArray(zeros(1, lenReal));

	for a = 1:lenReal
		gpuPVals(a) = sum(gpuNull <= gpuReal(a)) / lenNull;
	end

	pvals = gather(gpuPVals);
	garbage = gather(gpuReal);
	garbage = gather(gpuNull);

	clear garbage;

end