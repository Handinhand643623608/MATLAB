function a_CA_xcorr_BLP_IC(fileStruct, paramStruct)

% Cross-correlate the BLP-IC time courses
f_CA_run_xcorr_realBI(fileStruct, paramStruct);

% Generate a null distribution for significance testing
f_CA_run_xcorr_nullBI(fileStruct, paramStruct);

% Average together cross-correlation & null data to reduce data size
f_CA_run_average_xcorrDataBI(fileStruct, paramStruct);

% Bootstrap the data for significance
f_CA_run_bootstrap_BI(fileStruct, paramStruct);

% Image the data
f_CA_image_xcorrBI(fileStruct, paramStruct);