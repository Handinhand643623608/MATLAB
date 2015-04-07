% NEWPROFILE - A newer profiling of p-value generation algorithms.
%
%   This is the newest run of my p-value generation execution timings using both MATLAB-native code and C methods. It is also
%   a benchmark run on my new home PC, which was built earlier in January after my last PC tragically died.
%
%   APPROACHES:
%       Here is a breakdown of the approaches being benchmarked:
%       
%           1. Native               - The typical p-value generation algorithm written here in MATLAB code.
%           2. Old MEX Function     - The MEX function compiled back on 20141124.
%           3. New MEX Function     - A new compile of the MEX function with the highest compiler optimizations enabled.
%
%       Nothing significant has been changed in the logic behind any of the functions being tested. However, some time after
%       the benchmarking I ran in November, I discovered some additional compiler optimization options that could be enabled.
%       I am now running these benchmarks again with the maximum compiler optimization settings.
%
%   RESULTS:
%       The new, more optimized MEX function outperforms all of my previous efforts by increasing amounts as the sample size
%       climbs. This is great, because I now have a faster function in exchange for essentially zero effort. Additionally, it
%       seems my new computer outperforms my old one by quite a lot (compare saved images), but that was pretty much a given
%       considering how old my last PC was.

%% CHANGELOG:
%   Written by Josh Grooms on 20150131

function t = NewProfile()

    nsamples = 0:10000:50000;
    
    emptydata = zeros(1, length(nsamples));
    t = struct(...
        'LastCompile',  emptydata,...
        'Native',       emptydata,...
        'NewCompile',   emptydata,...
        'NumSamples',   nsamples);
    
    writeline = @(msg, varargin) fprintf(1, [msg '\n'], varargin{:});
    writeline('\n');
    
    for a = 1:length(nsamples)
        
        writeline('\nProfiling Execution Times for %d Sample Data Distributions.', nsamples(a));
        
        r = randn(nsamples(a), 1);
        n = randn(5 * nsamples(a), 1);
        
        fn = @() Native(r, n);
        fnc = @() NewMexEmpiricalCDF(r, n);
        foc = @() MexEmpiricalCDF(r, n);
        
        t.Native(a) = timeit(fn, 1);
        t.LastCompile(a) = timeit(foc, 1);
        t.NewCompile(a) = timeit(fnc, 1);
        
        writeline('Native Function:     %d s', t.Native(a));
        writeline('Old MEX Function:    %d s', t.LastCompile(a));
        writeline('New MEX Function:    %d s', t.NewCompile(a));
        
        writeline('\n');
        
    end
end



function p = Native(r, n)

    nr = length(r);
    nn = length(n);
    
    p = zeros(nr, 1);
    for a = 1:nr
        p(a) = sum(n <= r(a));
    end
    
    invn = 1 / nn;
    p = p .* invn;
    
    p = 2 * min(p, 1 - p);
    
end