function out = fit_TTC_iEEG(doCross)
% FIT_TTC_IEEG  Direct fit of the iEEG two-temporal-channel (TTC) model to the
% group broadband time courses. Channel IRFs fixed (Stigliani 2017); free
% params = transient weight, onset shift (ms), gain. Cross-validation
% (leave-one-condition-out) optional via doCross=true.

if nargin<1 || isempty(doCross), doCross=false; end

projectName='tactileTemporalNormalization'; model='TTC'; savestr='fmincon';
resultsstr='modelOutput_iEEG';
here = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(fileparts(here))));   % add repo Code tree (Models, Functions, ...)
[~, dataRootDir] = rootPath(false, projectName);
expPrms = expDetailsTemporalTactile(projectName);

% load group iEEG data
L = load(fullfile(dataRootDir,'iEEG','sub-group','sub-group_selectData.mat'), ...
    'avgELEC','stim_info','stim_ts','t','srate');
stim_info=L.stim_info; stim_ts=L.stim_ts; t=L.t; srate=L.srate;

onePulseIndx = find(contains(stim_info.name,'ONE'));
twoPulseIndx = find(contains(stim_info.name,'TWO'));
ord = [onePulseIndx; twoPulseIndx];

fixedP.ConditionNames = stim_info.name(ord);
fixedP.numConditions  = numel(ord);
fixedP.stimdur        = expPrms.stimdur;
fixedP.twoPulseDur    = expPrms.twoPulseDur;
fixedP.srate          = srate;
fixedP.t              = t;
fixedP.x_data         = stim_ts(:, ord);           % 1331 x 12

x_data   = fixedP.x_data;
tmp_ydata = L.avgELEC(:, ord);                     % tp x cond

currModel = @fitTTCmodel_IEEG;
vals = currModel([], {'initialize'});

% --- direct fit ---
fp = {'optimize', x_data, tmp_ydata, fixedP};
[p,~] = fmincon(@(x) currModel(x, fp), vals.init, [],[],[],[], vals.lb, vals.ub, [], vals.opts);
res = currModel(p, {'prediction', x_data, tmp_ydata, fixedP});
params=res.param(:); y_est=res.y_est; y_data=res.y_data; R2=res.R2;
condOrder=fixedP.ConditionNames; currModelName='fitTTCmodel_IEEG'; doCrossFlag=false;

resultsDir=fullfile(dataRootDir,resultsstr,model);
if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
save(fullfile(resultsDir, sprintf('sub-group_model-TTC_crossval-noCross_optimizer-%s_%s.mat',savestr,resultsstr)), ...
    'x_data','y_data','y_est','R2','params','condOrder','model','currModelName','currModel','doCrossFlag','stim_info','stim_ts','t');
fprintf('[fit_TTC_iEEG] weight=%.3f shift=%.3f scale=%.3f  direct-fit R2=%.3f\n', params(1),params(2),params(3),R2);

% --- optional cross-validation ---
R2cv=NaN;
if doCross
    nC=fixedP.numConditions; yCV=NaN(size(tmp_ydata));
    trainP=fixedP; trainP.numConditions=nC-1;
    testP=fixedP; testP.numConditions=1;
    for xf=1:nC
        keep=setdiff(1:nC,xf);
        trainP.ConditionNames=fixedP.ConditionNames(keep);
        trainP.x_data=fixedP.x_data(:,keep);
        tp=fmincon(@(x) currModel(x,{'optimize',x_data,tmp_ydata(:,keep),trainP}),vals.init,[],[],[],[],vals.lb,vals.ub,[],vals.opts);
        testP.ConditionNames=fixedP.ConditionNames(xf);
        testP.x_data=fixedP.x_data(:,xf);
        r=currModel(tp,{'prediction',x_data,tmp_ydata(:,xf),testP});
        yCV(:,xf)=r.y_est;
    end
    R2cv=1-sum((tmp_ydata(:)-yCV(:)).^2)/sum((tmp_ydata(:)-mean(tmp_ydata(:))).^2);
    y_est=yCV; y_data=tmp_ydata; R2=R2cv; doCrossFlag=true;
    save(fullfile(resultsDir, sprintf('sub-group_model-TTC_crossval-withCross_optimizer-%s_%s.mat',savestr,resultsstr)), ...
        'x_data','y_data','y_est','R2','params','condOrder','model','currModelName','currModel','doCrossFlag','stim_info','stim_ts','t');
    fprintf('[fit_TTC_iEEG] cross-val R2=%.3f\n', R2cv);
end

out.params=params; out.R2=R2; out.R2cv=R2cv; out.y_est=res.y_est; out.y_data=tmp_ydata;
out.condOrder=condOrder; out.t=t; out.stim_ts=stim_ts; out.stim_info=stim_info;
end
