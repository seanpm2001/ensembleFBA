% Computational Experiment
% Evaluate ensemble method against individual models
%
% Written by Matt Biggs, 2016

ensembleList = {'CE4_ensemble_2gcs', ...
                'CE4_ensemble_5gcs', ...
                'CE4_ensemble_10gcs', ...
                'CE4_ensemble_15gcs', ...
                'CE4_ensemble_20gcs', ...
                'CE4_ensemble_25gcs', ...
                'CE4_ensemble_30gcs'};

n_gcs_list = [2,5,10,15,20,25,30];            
            
% Load ensembles
for i = 1:length(ensembleList)
    if ~exist(ensembleList{i},'var')
        eval(['load ' ensembleList{i}]);
    end
end

% Evaluate the networks individually and as ensembles
N = 21;
networkPrecision = zeros(N*7,2);
ensemblePrecision = zeros(7,4);
networkRecall = zeros(N*7,2);
ensembleRecall = zeros(7,4);
networkAccuracy = zeros(N*7,2);
ensembleAccuracy = zeros(7,4);
for i = 1:length(n_gcs_list)
    curEnsemble = eval(ensembleList{i});
    gcs = n_gcs_list(i);
    
    % Evaluate individual networks
    for j = 1:N
        testGCs = curEnsemble{j}.gc_bm_vals(31:end);
        testNGCs = curEnsemble{j}.ngc_bm_vals(1:17);
        TP = sum( testGCs > 1e-10 );
        TN = sum( testNGCs < 1e-10 );
        FP = sum( testNGCs > 1e-10 );
        FN = sum( testGCs < 1e-10 );
        networkPrecision((i-1)*N+j,1) = TP / (TP + FP);
        networkPrecision((i-1)*N+j,2) = gcs;
        networkRecall((i-1)*N+j,1) = TP / (TP + FN);
        networkRecall((i-1)*N+j,2) = gcs;
        networkAccuracy((i-1)*N+j,1) = (TP + TN) / (TP + TN + FP + FN);
        networkAccuracy((i-1)*N+j,2) = gcs;
    end
    
    % Evaluate ensembles
    testGCs = zeros(length(testGCs),N);
    testNGCs = zeros(length(testNGCs),N);
    for j = 1:N
        testGCs(:,j) = curEnsemble{j}.gc_bm_vals(31:end);
        testNGCs(:,j) = curEnsemble{j}.ngc_bm_vals(1:17);
    end
    
    thresholds = [1,11,21];
    for t = 1:3
        thresh = thresholds(t);
        testGCs2 = sum(testGCs > 1e-10,2) >= thresh;
        testNGCs2 = sum(testNGCs > 1e-10,2) >= thresh;
        TP = sum( testGCs2 );
        TN = sum( testNGCs2 == 0 );
        FP = sum( testNGCs2 );
        FN = sum( testGCs2 == 0 );
        ensemblePrecision(i,t) = TP / (TP + FP);
        ensembleRecall(i,t) = TP / (TP + FN);
        ensembleAccuracy(i,t) = (TP + TN) / (TP + TN + FP + FN);
    end
    ensemblePrecision(i,4) = gcs;
    ensembleRecall(i,4) = gcs;
    ensembleAccuracy(i,4) = gcs;
end

% Write to file
dlmwrite('CE4_networkPrecision.tsv',networkPrecision,'\t');
dlmwrite('CE4_ensemblePrecision.tsv',ensemblePrecision,'\t');
dlmwrite('CE4_networkRecall.tsv',networkRecall,'\t');
dlmwrite('CE4_ensembleRecall.tsv',ensembleRecall,'\t');
dlmwrite('CE4_networkAccuracy.tsv',networkAccuracy,'\t');
dlmwrite('CE4_ensembleAccuracy.tsv',ensembleAccuracy,'\t');



