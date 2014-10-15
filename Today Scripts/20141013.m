%% 20141013 


%% 1559 - Analyzing the Frequency Response of BOLD & EEG FIR Temporal Filters
% The paper (Davey 2013) describes a procedure that corrects for reductions in degrees of freedom imposed by filtering
% time series that are being correlated with one another. This procedure differs somewhat from the one described in
% papers such as (Pyper 1998), (Worsley 2002), and others. 
%
% (Davey 2013) was published in NeuroImage for fMRI data and is pretty much the most recent relevant publication I could
% find, so I think it should be sufficient for the corrections the reviewers wanted me to make. This section will test
% out the procedure for finding the new effective degrees of freedom.

% Today's parameters
timeStamp = '201410131559';
analysisStamp = '';
dataSaveName = 'C:/Users/jgrooms/Desktop/Today Data/20141013/201410131559 - ';

% Reproduce the FIR filtering parameters used on my real data sets
TR = 2;
WindowLength = 45;
Passband = [0.01 0.08];
WindowName = 'hamming';

% Generate the filter parameters
WindowLength = round(WindowLength / TR);
windowParams = window(eval(['@' lower(WindowName)]), WindowLength+1);
filterParams = fir1(WindowLength, Passband.*2.*TR, windowParams);

% Get the complex frequency response of this particular filter
[h, f] = freqz(filterParams, 1, 512, 0.5);

% Plot the frequency response (just for my own visualization)
figure;
plot(f, abs(h))
set(gca, 'XTick', 0:0.01:0.25);

% Ensure real results by manipulating the complex frequency response (not described in the paper...)
amp = abs(h);
h2 = h .* conj(h);
rh = real(h);

% Calculate the effective degrees of freedom
cdof = (sum(h.^2)^2) ./ sum(h.^4)          % <--- Gives a complex number not described by the paper :\
rdof = (sum(amp.^2)^2) ./ sum(amp.^4)      % <--- Gives a pretty agreeable-looking result (~105.79)
rdof2 = (sum(h2)^2) ./ sum(h2.^2)          % <--- Results identical to rdof
rdof3 = (sum(rh)^2) ./ sum(rh.^2)          


% Results: 
% It is unclear how to generate real corrected degrees of freedom using the formula provided in equation 9 of (Davey
% 2013). The authors do not describe what should be done the complex frequency responses, although they do directly
% mention that the responses are complex. Clearly, though, complex-valued DOFs are nonsense and can't be used as they
% are. Something else must have been done...
%
% Taking only the real component or absolute value of the complex DOF number results in an estimate that is far too low
% to be what was intended. However, taking the real component of individual frequency responses and using those in
% Equation 9 produces results that much more expected:
%
%   105.79  -   For Gaussian window filters
%   102.59  -   For Hamming window filters (as was originally used for my data)
%
% These values are in agreement with what was listed in (Fox 2005) on page 2 under Correlation Statistics (i.e. a
% reduction of about 2.34 in the DOFs after filtering).
%
% However, the results using this method depend almost entirely on the number n chosen for the freqz function, for which
% I can't seem to nail down the appropriate number (MATLAB's documentation basically suggests that it's arbitrary
% depending on how many frequencies you want to analyze). Some example values and corresponding n inputs are as follows:



%% 1816 - Refining the Effective DOF Estimate

% Refined Results from Above:
% After reading the (Davey 2013) paper several more times (ugh...) and playing with both the formulae and related
% parameters, I think I have arrived a usable and supportable result. 
%
% The authors of this paper were somewhat less than clear about performing the actual calculations for the effective
% degrees of freedom. Specifically, if one were to follow Equation 9 exactly, the resulting DOF estimate tended to be
% complex, which didn't make sense.
%
% The apparent key to correcting this can be found in their Appendix A, where they state that they assume the frequency
% responses of the filter being used are conjugate symmetric, which allowed them to state the following:
%
%       (f*)f = f^2
%
%           f:  The frequency response of a filter at a particular frequency (bound between [0, 1])
%           f*: The complex conjugate of f
%
% For future reference, conjugate symmetry means that:
%       
%       f(-x) = f*(x)
%
% This is presumably where things were going wrong earlier. The imaginary components of my frequency response vectors
% were not summing to zero like the authors assumed. I believe this is because MATLAB automatically crops out the
% negative side of frequency spectra, because othewise the FT of a real signal should be conjugate symmetric.
%
%=======================================================================================================================
% NOTE: I later confirmed this to be true. The function freqz automatically crops out the symmetric side of the
% spectrum. Manually calculating the frequency responses shows that the imaginary components do indeed sum to zero (give
% or take some precision errors), but the resulting DOF estimates are still very clearly wrong. Everything depends on
% the NFFT parameter (called n and discussed later in this section) far too much, and I just can't figure out what its
% value should be.
%=======================================================================================================================
%
% By undoing their assumption and recalculating Equation 9 with conjugate pairs (see the variable h2 in the previous
% section), I have arrived at results that are both agreeable and can be somewhat confirmed using Equation 15 from the
% same paper.
%
% Using the frequency response of the FIR filter applied previously to both my BOLD and EEG data, the effective degrees
% of freedom were found to be ~130.8071. However, this number is extremely dependent on the number of frequencies n used
% in the freqz function (i.e. the number of frequencies at which to estimate the response value). Higher values
% dramatically increase the DOF estimate, while lower values decrease the estimate just as dramatically. 
%
% Despite hours spent trying today, I haven't been able to nail down an appropriate number for this function argument
% (MATLAB's documentation basically suggests that it's arbitrary depending on how many frequencies you want to analyze).
% To demonstrate how important it is, though, here are some example DOF estimates and their corresponding n values:
%
%   33.23   for n = 110     (the number of frequencies present if each frequency step is 1/436 (i.e. [0:(1/436):0.25]))
%   38.62   for n = 128     (the next power of 2 greater than 110)
%   65.56   for n = 218     (the number of time points present in my signals)
%   76.93   for n = 256     (the next power of 2 greater than 218)
%   130.81  for n = 436     (the number of seconds that my signals span)
%   153.56  for n = 512     (the next power of 2 greater than 436, & the default n for freqz)
%
% Unless the authors implicitly assumed that signals were being filtered in the frequency domain using a filter defined
% by this number, it's not clear what the appropriate value for this parameter should be. I've decided to use the number
% of time points in my signal for now, which is the closest I can get to the DOF estimate discussed next while still
% maintaining a semblence of a rationale for its choice.
%
% Using Equation 15 from the (Davey 2013) paper is much more straightforward, but relies on the assumption that an FIR
% filter approximates an ideal filter. This assumption sounds shakey as hell to me, but whatever because I have a thesis
% to write and I can legitimately cite them as having spouted such nonsense. This approach uses the following formula,
% which is derived in their appendices from Equation 9:
%
%       N* = 2 * Ts * T * (fh - fl)
%
%           N*: The effective degrees of freedom
%           Ts: The sampling interval
%           T:  The total signal length
%           fh: The lowpass cutoff frequency of the FIR filter
%           fl: The highpass cutoff frequency of the FIR filter
%   
% Plugging in numbers from my data:
%
%       N* = 2 * (2 s) * (436 s) * (0.08 cycles/s - 0.01 cycles/s) 
%
%          = 122.08 DOFs
%
% Or, using normalized units instead of time:
%   
%       N* = 2 * (1 timepoint) * (218 timepoints) * (0.32 cycles/timepoint - 0.04 cycles/timepoint) 
%          
%          = 122.08 DOFs
%
% The stoichiometry here seems a little iffy, especially because the final values are identical even though they have
% units of samples or seconds. I'm pretty sure this shouldn't be the case, and the more I think about it the less
% satisfied I am with the argument I'm making...



%% 2202 - Further Refining Effective DOF Estimates

% Further Refined Results:
% After working through Equation 15 (shown above) and becoming concerned over the lack of stoichiometric harmony, I
% did some more thinking about how that equation should really work. I decided to try to reverse engineer the (Fox 2005)
% result I talked a little about earlier using that formula, assuming that there would be at least an approximate
% agreement. I think I may finally have found an answer, but it's not good news for my work.
%
% First, here are some parameters from the (Fox 2005) paper that are important for this part:
%
%   TR = 3.013 s                 (The fMRI repetition time)
%   T  = 318                     (Number of time points in their signals)
%   PB = [0.009 Hz, 0.08 Hz]     (Temporal filter passband)
%   N* = 135.9                   (Their effective DOF estimate, presumably from the Chelton method or something similar)
%   CF = 2.34                    (Their correction factor, equal to T/N*)
%
% Working some of their parameters into Equation 15, and adjusting earlier definitions so the stoichiometry makes sense:
%
%   N* = 2 * (3.013 s/sample) * (318 samples) * (0.08 cycles/s - 0.009 cycles/s)
%
%      = 136.0550 DOFs (because cycles are actually pure numbers, not units)
%
% Applying the same logic to my data:
%   
%   N* = 2 * (2 s/sample) * (218 samples) * (0.08 cycles/s - 0.01 cycles/s)
%
%      = 61.04 DOFs
%
% This works out to a correction factor of (218/61.04) = 3.57, which is considerably higher than the one Fox et al
% found, despite having a nearly identical passband. Their additional 100 time points along with the 1 s increase in the
% TR seems to have made all the difference. For my data, having only ~61 DOFs just isn't what I wanted to see after
% having to axe 2 other subjects just recently. 
%
% I suppose this means about 2/3 of all of my data are just artificially autocorrelated junk. I just can't seem to catch
% a break on this project. I suppose tomorrow I should start thresholding all of my data using these results.
