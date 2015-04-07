%% Investigating Cilk Parallelized Empirical CDF Function
%	The new MexEmpiricalCDF function performs admirably. It even vastly outperforms the MATLAB-native serial and
%	parallel algorithm implementations. However, this function runs calculations serially using only a single CPU core.
%	I would guess that getting a multithreaded implementation working could provide even more speed benefits.
%
%	Earlier attempts on my home PC to get the Cilk multithreading feature working on the Intel C/C++ Compiler either
%	failed or distinctly slowed down the algorithm. Today, I want to profile the performance on my lab computer (6 cores
%	vs. the 4 in my home computer) and to further investigate using Cilk to see if any speedups can be realized. In
%	particular, it is possible to set the "grain size" of the loop parallelization through the compiler, which is what I
%	suspect is the cause of the slowdown.
%
%	RESULTS 20141124:
%		I now suspect that speed of the empirical CDF algorithm cannot be improved beyond the serial implementation.
%		Rough benchmarks provided below show pretty conclusively that, no matter what settings are applied, the running
%		times are always significantly slower than the serial function.
%
%		As the number of works increases (to a limit of the number of cores present), execution times get better but are
%		nowhere near as low as they are for the serial program, even at high sample counts. Changing the grain size
%		almost always has an adverse effect on the execution times; in the best case the times are right around those
%		produced using default grain sizing.
%
%		I have also read online that small loop bodies with insignificant iteration times (i.e. on the order of
%		microseconds) likely won't benefit from parallelization because the parallelization overhead exceeds the loop
%		iteration times (or at least becomes significant compared to it). The link to this source is provided below:
%
%		https://software.intel.com/en-us/articles/why-is-cilk-plus-not-speeding-up-my-program-part-1#PitfallFineGrained
%
%		I'm not completely convinced either way, but I do wonder if it would still be possible to speed the application
%		up by explicitly spawning a number of processes (equal to the core count) that evenly distribute the work. These
%		processes would have their own copies of inputs and an output (that would later have to be merged) so as to
%		eliminate data sharing overheads. Admittedly, I don't understand all of this nearly as well as is probably
%		required, so this is more speculation than educated-hypothesis, but it would be an interesting theory to test at
%		some point. For now, though, I think the serial mex function is the way to go.

%% CHANGELOG
%	Written by Josh Grooms on 20141124



%% Serial Intel Compiled Code (MexEmpiricalCDF.mexw64)

samples = [10000, 50000, 100000, 500000];
times = [0.0628, 1.4175, 5.5759, 138.6423];

est = @(n) 5.6e-10 * n^2;



%% Parallel Intel Compiled Code (2 Threads Active)

samples = [10000, 50000, 100000];
times = [0.2797, 6.6402, 26.1483];

est = @(n) 0.26e-8 * n^2;



%% Parallel Intel Compiled Code (6 Threads Active)

samples = [10000, 50000, 100000, 500000];
times = [0.1727, 4.1788, 16.3787, 398.7406];

est = @(n) 0.16e-8 * n^2;



%% Parallel Intel Compiled Code (12 Threads Active)

samples = [10000, 50000, 100000];
times = [0.5965, 13.4702, 53.6926];

est = @(n) 0.53e-8 * n^2;



%% Parallel Intel Compiled Code (2 Threads, Grain Ratio = 1/2)

samples = [10000, 50000, 100000];
times = [0.2826, 6.6010, 26.0859];



%% Parallel Intel Compiled Code (6 Threads, Grain Ratio = 1/6)

samples = [10000, 50000, 100000, 500000];
times = [0.2123, 4.7617, 18.7125, 471.4902];


%% 

samples = [10000, 50000, 100000];
times = [0.1786, 4.1930, 16.5283];