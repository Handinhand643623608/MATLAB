function regressedData = u_regress_signal(dataInput, sigToRegress)

% Normalize the signal being regressed (zero mean & unit variance)
sigToRegress = sigToRegress - mean(sigToRegress);
sigToRegress = sigToRegress/norm(sigToRegress);

szData = size(dataInput);
sigToRegress = repmat(sigToRegress, [szData(1:(end - 1)), 1]);

% Create a regression matrix for the input data
regMat = repmat(sum(sigToRegress.*dataInput, 2), [1, size(dataInput, 2)]).*sigToRegress;

% Perform the regression
regressedData = dataInput - regMat;