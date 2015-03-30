function pairings = nullPairings(scans)
%NULLPAIRINGS Output the null distribution pairing sequence.
%   This function generates deranged pairings of data for use deriving null data distributions. It
%   creates every possible inappropriate data pairing by subject and scan and then outputs the
%   pairings to a cell array.
%
%   SYNTAX:
%   pairings = nullPairings(scans)
%
%   OUTPUT:
%   pairings:       An Nx2 cell array of inappropriate data pairings. Each individual cell contains
%                   two numbers listed as [Subject Scan]. Each row represents a single pairing.
%                   Thus, the first cell of a row in the array is to be paired with the cell from
%                   the adjacent column. 
%   
%   INPUT:
%   scans:          A cell array of scans that are to be used in determining the null pairings.
%                   EXAMPLE:
%                       {[1 2] [1 2] [1 2 3]...} - Represents scans 1 & 2 from subject 1, scans 1 &
%                                                  2 from subject 2, and scans 1-3 from subject 3,
%                                                  etc.
%
%   Written by Josh Grooms on 20130626


%% Determine the Null Pairing Sequence
totalScans = length(cat(2, scans{:}));
indTranslate = cell(totalScans, 1);
m = 1;
for a = 1:length(scans)
    for b = scans{a}
        indTranslate{m} = [a, b];
        m = m + 1;
    end
end
pairings = num2cell(nchoosek(1:totalScans, 2));
pairings = cellfun(@(x) indTranslate(x), pairings);
