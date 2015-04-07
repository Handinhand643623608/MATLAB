% PROFILE - Profiles the time it takes to write a large data array to various locations on my computers.
%
%	This function tests write speeds on my various PCs by writing a large data set (modeling a single BOLD fMRI scan) to
%	various locations.
%
%	APPROACHES:
%		C:	The C:/ drive of my computers. This is a mechanical hard drive on my lab PC and a solid state otherwise.
%		D:	This is a solid state drive on my lab PC. On other PCs, this test is not run.
%		X:  This is my USB 3.0 work flash drive with a solid state controller. This is typically where I save data.
%
%	RESULTS:
%		
%		LAB PC:
%			C: 77.7925 s
% 			D: 77.6381 s
% 			X: 80.8015 s
%
%			The D:/ solid state drive appears to be the fastest, but only by a small margin. The differences here aren't as
%			dramatic as I expected. Based on these results, I'd guess that the hard drives in my lab computer are all
%			connected via SATA 3 Gb interfaces, which is especially tragic for the SSD.
%
%		HOME PC:

%% CHANGELOG
%	Written by Josh Grooms on 20150210



%% FUNCTION DEFINITION
function t = Profile()

	fcname = [Paths.Desktop.ToString() '/' Today.Date ' - HDD Test.mat'];
	fxname = [Paths.FlashDrive.ToString() '/' Today.Date ' - HDD Test.mat'];
	
    arr = randn(91, 109, 91, 300);

    t = emptystruct('C', 'X');
    
    fc = @() SaveFunction(fcname, arr);
    fx = @() SaveFunction(fxname, arr);

    t.C = timeit(fc);
    t.X = timeit(fx);
	
	if islabpc
		fdname = ['D:/' Today.Date ' - HDD Test.mat'];
		fd = @() SaveFunction(fdname, arr);
		t.D = timeit(fd);
	end
end



%% SUBROUTINES
function SaveFunction(filename, data)
% SAVEFUNCTION - Performs the actual save operation.
    save(filename, 'data');
end