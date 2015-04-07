% PROFILE - Profiles the performance of calculating cross-correlations between arrays over a single dimension.
%
%	Unlike the other cross-correlation prototyping attempt, this one estimates the cross-correlation between two arrays
%	over a single dimension (the other calculated it between vectors only). Essentially, they are one and the same;
%	cross-correlation is occurring between two collections of vectors (i.e. signals) instead of just two lone vectors.
%
%	However, one important distinction arises when approaching this process with larger arrays: the ability to
%	invoke Fourier Transforms dramatically increases the efficiency of the algorithm. This was seen originally when I 
%	wrote the "xcorrArr" function. The speed increase resulting from that approach was impressive.
%
%	Now, after having learned a great deal more about programming in other languages and having seen benefits elsewhere,
%	I am trying to achieve an even greater increase in calculation speed by porting these algorithms over to the C
%	language.
%	
%	C MEX functions used here were compiled using the Intel C++ optimizing compiler (from the Composer XE 2015 suite).
%
%	ABBREVIATIONS USED:
%		n:		Uses xcorrArr, which calculates cross-correlation in native MATLAB code using Fourier Transforms.
%		Ci:		C code that iteratively calculates cross-correlations between all signals in an array using VSL.
%		Cft:	C code that calculates cross-correlation using Fourier transforms of data using MKL.
%
%	OBSERVATIONS & CONCLUSIONS:
%		C-based code once again dramatically outperforms MATLAB native code, consistent with what has been found
%		elsewhere. However, the surprising result here is that iteratively calculating cross-correlation between the
%		columns of matrices is quite a bit faster than the FFT approach. This is in direct conflict with the
%		improvements seen when I wrote the "xcorrArr" function. These results hold even at larger sample sizes.
%
%		Importantly, when executing MEX functions, each data set is run through a MATLAB-native wrapper that does some
%		data transformations prior to invoking the C code. This is done to afford some flexibility in the function that
%		is not easily achieved in C and additionally it models the same/similar transforms that occur in "xcorrArr",
%		which keeps comparisons here fair.
%
%		At 20,000 individual signals and 2000 time points per signal, cross-correlation estimation requires on average
%		about 9 seconds for MATLAB-native code, 5 seconds for C code implementing the FFT approach, and 3.5 seconds for
%		C code that iterates through each model signal. 
%
%		I also tested execution times on my BOLD and EEG data sets. The iterative approach again wins out, requiring
%		~4.2 seconds on average to cross-correlate all BOLD voxel series with a single EEG channel. Using the FFT
%		approach, ~6.1 seconds were required on average. For the record, the BOLD array is of size [226394 x 218], the
%		EEG signal is sized [1 x 218], and correlation was estimated across the second (column) dimension.
%
%		I can think of one reason why these surprising results were achieved: the FFT library being used. MATLAB's FFT
%		functions use a library called FFTW (Fastest Fourier Transform in the West, I think), and evidently it is indeed
%		pretty fast. It's good/popular enough at least that Intel's MKL references it directly in its documentation and
%		provides some tools to interface with it instead of using the MKL-native method. 
%
%		If this alternative library is markedly faster than the MKL version, then that could be why that approach loses
%		here. Otherwise, the difference would have to stem from compiler optimizations or from the possibility that the
%		FFT approach just isn't faster.
%
%		Heap memory allocation is part of the problem with performance discrepancies here.

%% CHANGELOG
%	Written by Josh Grooms on 20150106




function t = Profile()


	nsignals = 10000 : 10000 : 20000;
	ntimes = 1000 : 1000 : 2000;
	writeline = @(msg, varargin) fprintf(1, [msg '\n'], varargin{:});
	
	init = zeros(length(nsignals), length(ntimes));
	t = struct...
	(...
		'Cft',              init,...            % Fourier transform xcorr approach in C using MKL
        'Ci',				init,...            % Iterative xcorr approach in C using VSL
		'Native',			init,...            % MATLAB-based Fourier transform xcorr approach (xcorrArr)
		'NumSignals',		nsignals,...
		'NumTimePoints',	ntimes...
	);

	for a = 1:length(nsignals)
		for b = 1:length(ntimes)
			
			writeline('\nProfiling Execution Times for %d Signals with %d Time Points Each:\n', nsignals(a), ntimes(b));

			s1 = randn(nsignals(a), ntimes(b));
			s2 = randn(nsignals(a), ntimes(b));

			fn = @() xcorrArr(s1, s2, 'Dim', 2, 'Scale', 'coeff');
			fci = @() ccorrProfile(s1, s2, 2, 'coeff', 1);
            fcft = @() ccorrProfile(s1, s2, 2, 'coeff', 2);

			t.Native(a, b) = timeit(fn, 1);
            t.Cft(a, b) = timeit(fcft, 1);
			t.Ci(a, b) = timeit(fci, 1);

			writeline('Native Execution Time:					%d s', t.Native(a, b));
			writeline('Iterative C Execution Time:				%d s', t.Ci(a, b));
            writeline('FFT C Execution Time:                    %d s', t.Cft(a, b));
			
			writeline('\n');
			
		end
	end	
end