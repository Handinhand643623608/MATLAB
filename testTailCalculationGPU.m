function pvals = testTailCalculationGPU(realData, nullData)



lenReal = length(realData);
lenNull = length(nullData);

gpuReal = gpuArray(single(realData));
gpuNull = gpuArray(single(nullData));
gpuPVals = gpuArray(single(zeros(2, lenReal)));

for a = 1:lenReal
    gpuPVals(1, a) = sum(gpuNull <= gpuReal(a)) / lenNull;
end

pvals = gather(gpuPVals);
garbage = gather(gpuReal);
garbage = gather(gpuNull);

clear garbage;



%% Results
% NullData [1 5*length(RealData)]

% RealData [1 1000]     --> 
% RealData [1 10000]    --> 6.0777s, 6.0817s