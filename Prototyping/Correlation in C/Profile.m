% Profile - Profiles the performance of calculating the correlation between two large arrays over a single dimension.
%
%   Lately I've been running a lot of sliding window correlations on my data. A while ago I noticed that it's probably pretty
%   wasteful to be running cross-correlations between data sets when I'm only using one specific shift from the output, but
%   I've been lazy about improving the process. Today, however, I finally wrote a function in C that just calculates Pearson
%   product-moment correlations between pairs of signals. This function compares the performance of the new C code against
%   other equivalent approaches.
%   
%   APPROACHES:
%       1. Native   - The function CORR, which calculates pairwise correlations just like my new function does.
%       2. C:       - The newly compiled MEX function.
%       3. CX:      - Calculating cross-correlations using CCORR, but only taking the 0th lag.
%
%       Each of these functions could be used to calculate sliding window correlation, which is just evaluating the
%       correlation between segments of signals that progressively shift to later time points.
%   
%       I'll be testing them out using arrays of size x = [300, 100,000 : 300,000], y = [300, 1] to approximate calculating
%       this metric with my BOLD and EEG data (actually, these arrays are a little larger).
%   
%   RESULTS:
%       Array-Vector Correlation (home PC):
%             100000 Signal Array
% 
%                 Native:  2.406520e-01 s
%                 C:       5.774644e-03 s
%                 CX:      3.358267e-01 s
% 
%             200000 Signal Array
% 
%                 Native:  4.542117e-01 s
%                 C:       9.838568e-03 s
%                 CX:      6.676484e-01 s
% 
%             300000 Signal Array
% 
%                 Native:  6.822878e-01 s
%                 C:       1.483613e-02 s
%                 CX:      1.012521e+00 s
%
%       Array-Array Correlation (home PC, x: [300, 1e5 : 3e5], y: [300, 10])
%             100000 Signal Array
% 
%                 Native:  2.413033e-01 s
%                 C:       2.940647e-02 s
% 
%             200000 Signal Array
% 
%                 Native:  4.533986e-01 s
%                 C:       5.957693e-02 s
% 
%             300000 Signal Array
% 
%                 Native:  6.560970e-01 s
%                 C:       8.763154e-02 s
% 
%       The new MEX function clearly outperforms the other approaches by a large amount. It regularly beats the native
%       approach by about an order of magnitude or more. However, even the MATLAB-native code performs better than the MEX
%       cross-correlation function by an appreciable amount when used like this. Looks like I shouldn't have been using that
%       for the sliding window analyses. Oops.

%% CHANGELOG
%   Written by Josh Grooms on 20150203



function t = Profile()


    nsignals = 100000 : 100000 : 300000;
    nsamples = 300;
    
    init = zeros(1, length(nsignals));
    t = struct(...
        'C',        init,...
        'CX',       init,...
        'Native',   init);
    
    writeline = @(msg, varargin) fprintf(1, [msg '\n'], varargin{:});
    writeline('\n');
    
    for a = 1:length(nsignals)
        
        writeline('\nProfiling Correlation Execution times for %d Signal Array\n', nsignals(a));
        
        x = randn(nsamples, nsignals(a));
        y = randn(nsamples, 10);
        
        fn = @() corr(x, y);
        fc = @() corrc(x, y);
%         fcx = @() ccorr(x, y, 0);
        
        t.Native(a) = timeit(fn, 1);
        t.C(a) = timeit(fc, 1);
%         t.CX(a) = timeit(fcx, 1);
        
        writeline('\tNative:  %d s', t.Native(a));
        writeline('\tC:       %d s', t.C(a));
%         writeline('\tCX:      %d s', t.CX(a));
        
    end

end
    

function r = Native(x, y)

    r = zeros(size(x, 2), size(y, 2));
    
    for a = 1:size(y, 2)
        for b = 1:size(x, 2)
            temp = corrcoef(x(:, b), y(:, a));
            r(b, a) = temp(2, 1);
        end
    end
end


    
    
    