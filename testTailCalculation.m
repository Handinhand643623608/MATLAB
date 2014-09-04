function pvals = testTailCalculation(realData, nullData)



lenReal = length(realData);
lenNull = length(nullData);

pvals = zeros(2, lenReal);

for a = 1:lenReal
    pvals(1, a) = sum(nullData <= realData(a))/lenNull;
end



%% Results
% NullData [1 5*length(RealData)]

% RealData [1 1000]     --> 0.0248s
% RealData [1 10000]    --> 2.5245s, 2.4275s, 2.4329s, 
