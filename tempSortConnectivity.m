%% tempSortConnectivity

corrMat = reshape(corrMat, 68, 68, 17);
idsCorrMat = corrMat < 0;

freqAnticorr = sum(idsCorrMat, 3);

for a = 1:68
    freqAnticorr(a:end, a) = freqAnticorr(a, a:end);
end

[~, idsSorted] = sort(freqAnticorr);


%%
ascendCount = zeros(1, 68);
for a = 1:68
    sortedFreqs = freqAnticorr(idsSorted(:, a), idsSorted(:, a));
    checkAscending = sortedFreqs(2:end, 2:end) > sortedFreqs(1:end-1, 1:end-1);
    ascendCount(a) = sum(checkAscending(:));
end

idsSorted = idsSorted(:, ascendCount == max(ascendCount));
sortedFreqs = freqAnticorr(idsSorted, idsSorted);

figure; imagesc(sortedFreqs);
