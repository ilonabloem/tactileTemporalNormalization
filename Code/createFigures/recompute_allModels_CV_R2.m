function T = recompute_allModels_CV_R2()
% RECOMPUTE_ALLMODELS_CV_R2  Single-pipeline recomputation of the
% leave-one-condition-out cross-validated R^2 for all three temporal models
% (linear, [delayed] normalization, and two-temporal-channel) for both the
% fMRI and iEEG datasets.
%
% Rather than trusting each model's separately-stored R^2, this loads the
% held-out cross-validated predictions (y_est) and data (y_data) for every
% model and recomputes R^2 with ONE shared definition. It also asserts that
% all models were cross-validated on identical held-out data (same folds /
% conditions), so the resulting R^2 values are directly comparable.
%
% Prints a summary table and writes Figures/SupplementaryTable_CVR2.txt.
%
% Note on optimizers: the linear and normalization / delayed-normalization
% models were fit with BADS (as in the paper); the two-temporal-channel model
% was fit with fmincon. The CV folds, held-out data, and R^2 metric are
% identical across all models — only the within-fold optimizer differs, which
% is immaterial for these smooth, low-dimensional fits.

here = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(here)));   % add repo Code tree (Models, Functions, ...)
[~, d] = rootPath(false, 'tactileTemporalNormalization');
r2   = @(y,f) 1 - sum((y(:)-f(:)).^2) ./ sum((y(:)-mean(y(:))).^2);

% ---------------- fMRI ----------------
fp = @(m,f) fullfile(d,'modelOutput_fMRI',m,f);
LN = load(fp('HRF' ,'sub-group_localizerROI-S1_model-HRF_crossval-withCross_optimizer-bads_modelOutput_fMRI.mat'));
NM = load(fp('NORM','sub-group_localizerROI-S1_model-NORM_crossval-withCross_optimizer-bads_modelOutput_fMRI.mat'));
TF = load(fp('TTC' ,'sub-group_localizerROI-S1_model-TTC_crossval-withCross_optimizer-fmincon_modelOutput_fMRI.mat'));
assert(isequaln(LN.y_data,NM.y_data) && isequaln(LN.y_data,TF.y_data), ...
    'fMRI: models were not cross-validated on identical held-out data');
fmri = [r2(LN.y_data,LN.y_est), r2(NM.y_data,NM.y_est), r2(TF.y_data,TF.y_est)];

% ---------------- iEEG ----------------
ip = @(m,f) fullfile(d,'modelOutput_iEEG',m,f);
LI = load(ip('LIN','sub-group_model-LIN_crossval-withCross_optimizer-bads_modelOutput_iEEG.mat'));
DN = load(ip('DN' ,'sub-group_model-DN_crossval-withCross_optimizer-bads_modelOutput_iEEG.mat'));
TI = load(ip('TTC','sub-group_model-TTC_crossval-withCross_optimizer-fmincon_modelOutput_iEEG.mat'));
assert(isequaln(LI.y_data,DN.y_data) && isequaln(LI.y_data,TI.y_data), ...
    'iEEG: models were not cross-validated on identical held-out data');
ieeg = [r2(LI.y_data,LI.y_est), r2(DN.y_data,DN.y_est), r2(TI.y_data,TI.y_est)];

% ---------------- report ----------------
T = table([fmri(1);ieeg(1)], [fmri(2);ieeg(2)], [fmri(3);ieeg(3)], ...
    'VariableNames', {'Linear','Normalization','TwoChannel'}, ...
    'RowNames', {'fMRI_BOLD','iEEG_broadband'});

lines = {};
lines{end+1} = 'Leave-one-condition-out cross-validated R^2 (single shared pipeline)';
lines{end+1} = 'All models evaluated on identical held-out data (verified).';
lines{end+1} = '';
lines{end+1} = sprintf('%-16s %8s %14s %12s','Dataset','Linear','Normalization','TwoChannel');
lines{end+1} = sprintf('%-16s %8.3f %14.3f %12.3f','fMRI BOLD',      fmri(1),fmri(2),fmri(3));
lines{end+1} = sprintf('%-16s %8.3f %14.3f %12.3f','iEEG broadband', ieeg(1),ieeg(2),ieeg(3));
txt = strjoin(lines, newline);
disp(txt);

outdir = fullfile(d,'..','Figures');
if ~exist(outdir,'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir,'SupplementaryTable_CVR2.txt'),'w');
fprintf(fid,'%s\n',txt); fclose(fid);
fprintf('\n[recompute_allModels_CV_R2] wrote %s\n', fullfile(outdir,'SupplementaryTable_CVR2.txt'));
end
