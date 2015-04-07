function t = Profile()
% PROFILE - Profiles the performance of calculating cross-correlations between vectors using C MEX functions.
%
%	C MEX functions used here were compiled using the Intel C++ optimizing compiler (from the Composer XE 2015 suite).
%
%	ABBREVIATIONS USED:
%		n:		MATLAB-native
%		C:		Simple C code compiled with default settings
%		O3:		C code compiled with the optimization flag O3 set
%		O3P:	C code compiled with the optimization flag O3 set & auto-parallelization enabled
%		M:		C code compiled with optimization and parallelization flags at their maximum settings
%
%	OBSERVATIONS & CONCLUSIONS:
%		C-based code appears to always be faster than the MATLAB native code, although neither approach requires much
%		time to complete execution (tested at signal lengths up to 1,000,000). Setting optimization and parallelization
%		flags for the compiler has virtually no effect as differences in run times could just be noise (differences are
%		always < 0.01 s).

%% CHANGELOG
%	Written by Josh Grooms on 20141230



	%% Profiling Function

	nsamples = 100000:100000:1000000;
	writeline = @(msg, varargin) fprintf(1, [msg '\n'], varargin{:});
	
	t = struct...
	(...
		'C', zeros(1, length(nsamples)),...
		'CO3', zeros(1, length(nsamples)),...
		'CO3P', zeros(1, length(nsamples)),...
		'CM', zeros(1, length(nsamples)),...
		'Native', zeros(1, length(nsamples)),...
		'SampleSizes', nsamples...
	);
	
	for a = 1:length(nsamples)
		
		writeline('\n');
		writeline('\nProfiling Execution Times for %d Sample Signals:\n', nsamples(a));

		s1 = randn(nsamples(a), 1);
		s2 = randn(nsamples(a), 1);

		fn = @() xcorr(s1, s2);
		fc = @() xcorrc(s1, s2);
		fcO3 = @() xcorrcO3(s1, s2);
		fcO3P = @() xcorrcO3P(s1, s2);
		fcm = @() xcorrcm(s1, s2);

		t.Native(a) = timeit(fn, 1);
		t.C(a) = timeit(fc, 1);
		t.CO3(a) = timeit(fcO3, 1);
		t.CO3P(a) = timeit(fcO3P, 1);
		t.CM(a) = timeit(fcm, 1);

		writeline('Native Execution Time:					%d s', t.Native(a));
		writeline('C Execution Time:						%d s', t.C(a));
		writeline('Highly Optimized C Execution Time:		%d s', t.CO3(a));
		writeline('Parallel Optimized C Execution Time:		%d s', t.CO3P(a));
		writeline('Maximally Optimized C Execution TIme:	%d s', t.CM(a));
		writeline('\n');
	end
	
	
	figure;
	plot(nsamples, [t.Native', t.C' t.CO3', t.CO3P', t.CM']);
	legend('Native', 'C', 'Optimized C', 'Parallel C', 'Maximally Optimized C', 'Location', 'NorthEastOutside');
	xlabel('Number of Signal Samples');
	ylabel('Time (s)');
	
end