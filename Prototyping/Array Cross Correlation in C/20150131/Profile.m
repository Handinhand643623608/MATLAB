% PROFILE - Profiles the performance of calculating cross-correlations between arrays over a single dimension.
%   
%   This is a new run of my array cross-correlation execution timings using both MATLAB-nativve code and C methods. It is
%   also a benchmark run on my new home PC, which was built earlier in January after my last PC tragically died.
%
%   APPROACHES:
%       Here is a breakdown of the approaches being benchmarked:
%
%           1. Native               - The typical xcorrArr function written in MATLAB code.
%           2. Old MEX Function     - The MEX function compiled back on 20150126.
%           3. New MEX Function     - A new compile of the MEX function with Cilk parallelization.
%
%       Here is a breakdown of the input types being used:
%           
%           1. Matrix-Matrix        - Two equally sized matrices being cross-correlated.
%           2. Matrix-Vector        - Each column of a matrix being cross-correlated with a vector.
%
%       Nothing significant has been changed in the logic behind any of the functions being tested. However, I noticed in the
%       C code of the MexCrossCorrelate function an opportunity to insert a "cilk_for" command that might speed things up.
%       Also, I implemented support for Y being a vector when X is a matrix in the MEX function because this represents my
%       most frequent use scenario for this function (e.g. BOLD being cross-correlated with an EEG signal). I am running
%       these benchmarks again to see what kinds of performance gains can be had through simple parallelization and what kind
%       of overhead I'll be eliminating by not forcing the replication of Y to match the size of X.
%
%   RESULTS:
%       Matrix-Matrix Cross-Correlation (run on my new home PC):
%           100 Samples x 250,000 Signals:
%                 Native Function:     3.155034e+00 s
%                 Old MEX Function:    1.029868e+00 s
%                 New MEX Function:    4.199822e-01 s
%
%           200 Samples x 250,000 Signals:
%                 Native Function:     7.482541e+00 s
%                 Old MEX Function:    2.961005e+00 s
%                 New MEX Function:    8.346678e-01 s
%       
%           300 Samples x 250,000 Signals:
%                 Native Function:     2.058208e+01 s
%                 Old MEX Function:    3.531646e+00 s
%                 New MEX Function:    1.426966e+00 s
%
%       Matrix-Vector Cross-Correlation (run on my new home PC):
%           (100 Samples x 250,000 Signals) - (100 Samples x 1 Signal)
%                 Native Function:     3.106849e+00 s
%                 New MEX Function:    3.906945e-01 s
%
%           (200 Samples x 250,000 Signals) - (200 Samples x 1 Signal)
%                 Native Function:     7.137549e+00 s
%                 New MEX Function:    7.801676e-01 s
%   
%           (300 Samples x 250,000 Signals) - (300 Samples x 1 Signal)
%                 Native Function:     2.039451e+01 s
%                 New MEX Function:    1.326599e+00 s
%
%       The new parallelized MEX function outperforms all of the previous functions by a very large amount. In fact, this 
%       parallel function cuts execution time approximately in half compared to the serial MEX function. Additionally, the
%       elimination of overhead incurred by vector replication substantially reduces the execution time. Using signals
%       containing 300 samples, the newest compiled MEX routine is ~15x faster than the MATLAB-native method and ~2.5x faster
%       than the old serial MEX function.

%% CHANGELOG
%	Written by Josh Grooms on 20150131



function t = Profile()

    nsignals = 250000;          % Flattened BOLD arrays have ~226,000 signals with ~200 time points each
    nsamples = 100:100:300;
    
	init = zeros(length(nsignals), length(nsamples));
	t = struct(...
        'Native',       struct('MatrixMatrix', init, 'MatrixVector', init),...
        'OldCompile',   init,...
        'NewCompile',   struct('MatrixMatrix', init, 'MatrixVector', init));

    writeline = @(msg, varargin) fprintf(1, [msg '\n'], varargin{:});
	writeline('\n');
    
	for a = 1:length(nsamples)
        
        writeline('\nProfiling Execution Times for Matrix-Matrix Cross-Correlation with %d Time Points:\n', nsamples(a));
        
        s1 = randn(nsamples(a), nsignals);
        s2 = randn(nsamples(a), nsignals);
        
        fn = @() xcorrArr(s1, s2, 'Dim', 1, 'Scale', 'coeff');
        foc = @() ccorrp(s1, s2, nsamples(a) - 1, 1);
        fnc = @() ccorrp(s1, s2, nsamples(a) - 1, 2);
        
        t.Native.MatrixMatrix(a) = timeit(fn, 1);
        t.OldCompile(a) = timeit(foc, 1);
        t.NewCompile.MatrixMatrix(a) = timeit(fnc, 1);
        
        writeline('Native Function:     %d s', t.Native.MatrixMatrix(a));
        writeline('Old MEX Function:    %d s', t.OldCompile(a));
        writeline('New MEX Function:    %d s', t.NewCompile.MatrixMatrix(a));
        
        writeline('\n');
        
    end	
    
    for a = 1:length(nsamples)
        
        writeline('\nProfiling Execuiton Times for Matrix-Vector Cross-Correlation with %d Time Points:\n', nsamples(a));
        
        s1 = randn(nsamples(a), nsignals);
        s2 = randn(nsamples(a), 1);
        
        fn = @() xcorrArr(s1, s2, 'Dim', 1, 'Scale', 'coeff');
        fnc = @() ccorrp(s1, s2, nsamples(a) - 1, 2);
        
        t.Native.MatrixVector(a) = timeit(fn, 1);
        t.NewCompile.MatrixVector(a) = timeit(fnc, 1);
        
        writeline('Native Function:     %d s', t.Native.MatrixVector(a));
        writeline('New MEX Function:    %d s', t.NewCompile.MatrixVector(a));
    end
end