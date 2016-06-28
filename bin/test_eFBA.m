% Build a test ensemble 
%
% Written by Matt Biggs, 2016

% Load universal reaction database
if ~exist('seed_rxns_mat','var')
    load seed_rxns
end

seed_rxns_mat.X = -1*speye(length(seed_rxns_mat.mets));
seed_rxns_mat.Ex_names = strcat('Ex_',seed_rxns_mat.mets);

%## Define biomass function:
% Substrates:
% ATP                       cpd00002	7933 (index)
% Glycine                   cpd00033	2573
% Histidine                 cpd00119	978
% Lysine                    cpd00039    2567
% Aspartate                 cpd00041    7223
% Glutamate                 cpd00023    7584
% Serine                    cpd00054    2202
% Threonine                 cpd00161    5266
% Asparagine                cpd00132    1349
% Glutamine                 cpd00053    3130
% Cysteine                  cpd00084    6520
% Proline                   cpd00129    6008
% Valine                    cpd00156    230
% Isoleucine                cpd00322    4296
% Leucine                   cpd00107    5622
% Methionine                cpd00060    6861
% Phenylalanine             cpd00066    6863
% Tyrosine                  cpd00069    6867
% Tryptophan                cpd00065    6864
% Cardiolipin               cpd12801    6246
% CoA                       cpd00010    2939
% CTP                       cpd00052    2204
% dATP                      cpd00115    982
% dCTP                      cpd00356    635
% dGTP                      cpd00241    7842
% dTTP                      cpd00357    634
% FAD                       cpd00015    2944
% Glycogen                  cpd00155    231
% GTP                       cpd00038    2566
% H2O                       cpd00001    7930
% NAD                       cpd00003    7932
% NADH                      cpd00004    7927
% NADP                      cpd00006    7929
% NADPH                     cpd00005    7926
% Phosphatidylethanolamine  cpd11456    6907
% peptidoglycan subunit     cpd16008    3356
% Phosphatidylglycerol      cpd11652    7958
% phosphatidylserine        cpd15657    6603
% Putrescine                cpd00118    979
% Spermidine                cpd00264    6545
% Succinyl-CoA              cpd00078    1865
% UDP-glucose               cpd00026    7581
% UTP                       cpd00062    6859
% 
% Products:
% ADP           cpd00008    7935
% H+            cpd00067    6862
% Pi            cpd00009    7934
% PPi           cpd00012    2937
biomassRxn = zeros(length(seed_rxns_mat.mets),1);
biomassRxn([7933,2573,978,2567,7223,7584,2202,5266,1349,3130, ...
            6520,6008,230,4296,5622,6861,6863,6867,6864,6246, ...
            2939,2204,982,635,7842,634,2944,231,2566,7930, ...
            7932,7927,7929,7926,6907,3356,7958,6603,979,6545, ...
            1865,7581,6859],1) = -1;
biomassRxn([7935,6862,7934,2937],1) = 1;

%## Define minimal growth conditions
% Cobalt        cpd00149    4926 (Index)
% Copper        cpd00058    2213
% Fe3           cpd10516    3321
% H+            cpd00067    6862
% H2O           cpd00001    7930
% Mg2           cpd00254    6753
% N2            cpd00528    6714
% NH4           cpd00013    2938
% O2            cpd00007    7928
% Pi            cpd00009    7934
% SO4           cpd00048    7222

lb_minimal_base = zeros(length(seed_rxns_mat.mets),1);
lb_minimal_base([4926,2213,3321,6862,7930,6753,6714,2938,7928,7934,7222],1) = -1000;

% Growth Carbon sources:
% 4-Hydroxybenzoate     cpd00136    1346
% Acetate               cpd00029    7578
% Citrate               cpd00137    1345
% Glycerol-3-phosphate  cpd00080    6524
% D-Alanine             cpd00117    980

growth_carbon_sources = [1346,7578,1345,6524,980];
               
n = length(growth_carbon_sources);
growthConditions = repmat(lb_minimal_base,[1,n]);
for i = 1:n
    growthConditions(growth_carbon_sources(i),i) = -10;
end

% Define non-growth conditions
% non-Growth Carbon sources:
% 2,3-Butanediol        cpd01949    8832
% ACTN                  cpd00361    462
% CELB                  cpd00158    234
% fructose-6-phosphate  cpd00072    1859
% D-Galacturonate       cpd00280    8289

nongrowth_carbon_sources = [8832,462,234,1859,8289];

nonGrowthConditions = repmat(lb_minimal_base,[1,length(nongrowth_carbon_sources)]);
for i = 1:length(nongrowth_carbon_sources)
    nonGrowthConditions(nongrowth_carbon_sources(i),i) = -10;
end

%------------------------------------------------------------------------
% Simplify the universal rxn database so that there are no blocked rxns
%------------------------------------------------------------------------
[newBiomassFn] = removeBlockedBiomassComponents(seed_rxns_mat,growthConditions,biomassRxn);
save('newBiomassFn.mat','newBiomassFn')
load consistentUnivRxnSet.mat

trimmed_growthConditions = growthConditions(keepXRxns,:);
trimmed_nonGrowthConditions = nonGrowthConditions(keepXRxns,:);

%------------------------------------------------------------------------
% Import reactions from P. aeruginosa PA1 genome
%------------------------------------------------------------------------
% Schema: ID	Name	Equation	Definition	Genes
% fig|1279007.3.peg.2761
% rxn02201_c0
fid = fopen('PA14_reference_genome.rxntbl','r');
rxns = textscan(fid, '%s%s%s%s%s','Delimiter','\t');
fclose(fid);

trimmed_rxnList = char(rxns{1});
trimmed_rxnList = trimmed_rxnList(:,1:8);
gprs = strfind(rxns{5},'fig');
rxns_with_genomic_evidence = ~cellfun(@isempty,gprs);
trimmed_rxnList = cellstr(trimmed_rxnList(rxns_with_genomic_evidence,:));
trimmed_gprs = rxns{5};
trimmed_gprs = cellfun(@(orig,old,new) strrep(orig,old,new), trimmed_gprs, repmat({'fig|208963.12.'},[length(trimmed_gprs),1]), repmat({''},[length(trimmed_gprs),1]),'UniformOutput',false);
trimmed_gprs = trimmed_gprs(rxns_with_genomic_evidence);

Urxns2set = [find(ismember(consistentUnivRxnSet.rxns,trimmed_rxnList)); find(ismember(consistentUnivRxnSet.rxns,'rxn05064'))]; % include spontaneous rxn05064
Uset2 = ones(size(Urxns2set));

% Include exchange reactions for all non-growth conditions, just so that
% it's the network itself--not the lack of exchange reactions--that prevents growth
Xrxns2set = find(sum( abs(consistentUnivRxnSet.X([growth_carbon_sources nongrowth_carbon_sources],:)) ,1) > 0);
Xset2 = ones(size(Xrxns2set));