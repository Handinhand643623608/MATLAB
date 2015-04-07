% PROFILE - Profiles the performance of calculating sliding window correlations between large data sets.
%
%   After writing the simple correlation function MEXCORRELATE in C earlier today, I decided it wouldn't require much more
%   effort to just write the whole sliding window algorithm in C for even greater efficiency. Naturally, I was mistaken. But
%   after several hours of tweaking and debugging the code, I finally have functions that compile, execute without crashing
%   MATLAB, and produce valid results. Now it's time to benchmark them.
%
%   APPROACHES:
%       1. Native   - Approximately the approach I've been using in the past, written in MATLAB code.
%       2. C        - The full sliding window correlation algorithm newly written in C.
%       3. P        - The parallelized version of 2 (just with some added cilk_for loops)
%
%       Notice that the Native approach uses the CORR function (see the subroutine in this file), which isn't how I've been
%       doing it. In the past, I've been calling XCORRARR or CCORR to perform the actual correlations and then just using the
%       0th lag. It took a while (too long, probably), but I realized today that this is terribly inefficient. Using CORR in
%       place of one of those cross-correlation functions is cheating a little bit because it's actually faster than the
%       others here (yes, even faster than the C cross-correlation code by a little bit). That being said, I don't feel like
%       rewriting it to accurately model my past SWC analyses, so it stays.
%
%       These functions will be tested with arrays that approximate my research data:
%           
%           x           - A [300 x 1e5:3e5] array approximating a series of BOLD images.
%           y           - A [300 x 10] array approximating 10 EEG electrode signals.
%           window      - 25 samples, which is a 50 second window for my research data.
%           noverlap    - 24 samples, which is the maximum possible overlap between successive windows.
%
%   RESULTS:
%
%         100000 Signal Array
%             Native:  1.145046e+02 s
%             C:       6.701512e+00 s
%             P:       1.261363e+00 s
%
%         200000 Signal Array
%             Native:  2.457668e+02 s
%             C:       1.367388e+01 s
%             P:       2.553716e+00 s
%
%         300000 Signal Array
%             Native:  3.487326e+02 s
%             C:       2.068099e+01 s
%             P:       3.956400e+00 s
%
%       The results above speak for themselves. The parallelized C code is ~100x faster than the MATLAB-native approach,
%       which is just incredible. I could have saved myself a bunch of time by writing this function eariler...

%% CHANGELOG
%   Written by Josh Grooms on 20150203



function t = Profile()

    nsignals = 100000 : 100000 : 300000;
    nsamples = 300;
    window = 25;
    noverlap = 24;    
    
    init = zeros(1, length(nsignals));
    t = struct(...
        'C',        init,...
        'P',        init,...
        'Native',   init);
    
    writeline = @(msg, varargin) fprintf(1, [msg '\n'], varargin{:});
    writeline('\n');
    
    for a = 1:length(nsignals)
        
        writeline('\nProfiling SWC Execution times for %d Signal Array\n', nsignals(a));
        
        x = randn(nsamples, nsignals(a));
        y = randn(nsamples, 10);
        
        fn = @() Native(x, y, window, noverlap);
        fc = @() swcorrc(x, y, window, noverlap);
        fp = @() swcorrcp(x, y, window, noverlap);
        
        t.Native(a) = timeit(fn, 1);
        t.C(a) = timeit(fc, 1);
        t.P(a) = timeit(fp, 1);
        
        writeline('\tNative:  %d s', t.Native(a));
        writeline('\tC:       %d s', t.C(a));
        writeline('\tP:       %d s', t.P(a));
        
    end

end


function swc = Native(x, y, window, noverlap)

    szx = size(x);
    szy = size(y);

    nswc = (szx(1) - window) / (window - noverlap);
    swc = zeros(nswc, szx(2), szy(2));
    
    
    for a = 1:szy(2)
        d = 1;
        for b = 1:(window - noverlap):(szx(1) - window)
            idsSamples = b : (b + window - 1);
            swc(d, :, a) = corr(x(idsSamples, :), y(idsSamples, a));
            d = d + 1;
        end
    end

end