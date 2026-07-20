function out = fit_TTC_fMRI(doCross)
% FIT_TTC_FMRI  Direct fit of the fMRI two-temporal-channel (TTC) model to the
% group BOLD time courses. Channel IRFs fixed (Stigliani 2017); HRF fixed to
% the linear (HRF) model's fitted HRF; free params = transient weight + gain.
% Fit by a 1-D search over weight with closed-form least-squares gain (fast).
% Cross-validation (leave-one-condition-out) optional via doCross=true.

if nargin<1 || isempty(doCross), doCross=false; end

projectName = 'tactileTemporalNormalization';
model       = 'TTC'; 
savestr     = 'fmincon'; 
resultsstr  = 'modelOutput_fMRI';
ROIname     = {'localizerROI','S1'};
ROIname     = sprintf('%s-%s', ROIname{:,1}, ROIname{:,2});
subject     = 'group';

here = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(fileparts(here))));   % add repo Code tree (Models, Functions, ...)
[~, dataRootDir] = rootPath(false, projectName);
expPrms  = expDetailsTemporalTactile(projectName);

% fixedP (as in s4)
fixedP.onePulseIndx   = cat(1, find(contains(expPrms.ConditionNames,'BLANK')), ...
                               find(contains(expPrms.ConditionNames,'ONE')));
fixedP.twoPulseIndx   = find(contains(expPrms.ConditionNames,'TWO'));
fixedP.ConditionNames = cat(1, expPrms.ConditionNames(fixedP.onePulseIndx), ...
                               expPrms.ConditionNames(fixedP.twoPulseIndx));
fixedP.numConditions  = numel(fixedP.ConditionNames);
fixedP.stimdur        = expPrms.stimdur;
fixedP.twoPulseDur    = expPrms.twoPulseDur;
fixedP.tr             = expPrms.tr;

% fixed HRF = HRF (linear) model's fitted HRF
allR = loadResultsfMRI(projectName);
fixedP.hrfParams = allR.HRFparams(2:4)';   % [gamma1 gamma2 gamma2_gain]

% group-average data
S = load(fullfile(dataRootDir,'avgTimeSeries', ...
    sprintf('sub-%s_%s_avgTimeSeries.mat',subject,ROIname)));
x_data = S.x_data; fixedP.x_data = x_data;
Data   = mean(S.allBetas,3);
tmp_ydata = Data([fixedP.onePulseIndx; fixedP.twoPulseIndx], :)';   % tp x cond

% precompute fixed channel BOLD responses
[BS, BT] = ttcBOLDchannels(fixedP);

% --- direct fit: 1-D search over weight, closed-form gain ---
[w, g, yhat] = fitWG(BS, BT, tmp_ydata);
R2 = 1 - sum((tmp_ydata(:)-yhat(:)).^2)/sum((tmp_ydata(:)-mean(tmp_ydata(:))).^2);
params = [w; g];
condOrder = fixedP.ConditionNames;

resultsDir = fullfile(dataRootDir, resultsstr, model);
if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
y_est = yhat; y_data = tmp_ydata; currModelName='fitTTCmodel'; doCrossFlag=false; currModel = str2func(currModelName); hrfParams = fixedP.hrfParams;
save(fullfile(resultsDir, sprintf('sub-group_%s_model-TTC_crossval-noCross_optimizer-%s_%s.mat',ROIname,savestr,resultsstr)), ...
    'subject','x_data','y_data','y_est','R2','params','condOrder','model','currModelName','currModel','ROIname','hrfParams','doCrossFlag','savestr');

fprintf('[fit_TTC_fMRI] weight=%.3f gain=%.3f  direct-fit R2=%.3f\n', w, g, R2);

% --- optional cross-validation (leave-one-condition-out) ---
R2cv = NaN;
if doCross
    nC = fixedP.numConditions; yCV = NaN(size(tmp_ydata));
    for xf = 1:nC
        keep = setdiff(1:nC,xf);
        [wk, gk] = fitWG(BS(:,keep), BT(:,keep), tmp_ydata(:,keep));
        yCV(:,xf) = gk*(wk*BT(:,xf)+(1-wk)*BS(:,xf));
    end
    R2cv = 1 - sum((tmp_ydata(:)-yCV(:)).^2)/sum((tmp_ydata(:)-mean(tmp_ydata(:))).^2);
    y_est=yCV; y_data=tmp_ydata; R2=R2cv; doCrossFlag=true;
    save(fullfile(resultsDir, sprintf('sub-group_%s_model-TTC_crossval-withCross_optimizer-%s_%s.mat',ROIname,savestr,resultsstr)), ...
        'subject','x_data','y_data','y_est','R2','params','condOrder','model','currModelName','currModel','ROIname','hrfParams','doCrossFlag','savestr');
    fprintf('[fit_TTC_fMRI] cross-val R2=%.3f\n', R2cv);
end

out.weight=w; out.gain=g; out.R2=R2; out.R2cv=R2cv;
out.y_est=yhat; out.y_data=tmp_ydata; out.condOrder=condOrder;
out.hrfParams=fixedP.hrfParams; out.BS=BS; out.BT=BT;
end

function [w, g, yhat] = fitWG(BS, BT, data)
% 1-D search over transient weight; gain in closed form (LS).
obj = @(w) sse_for_w(w, BS, BT, data);
ws = linspace(0,1,51); vals = arrayfun(obj, ws);
[~,i] = min(vals);
lo = max(0, ws(i)-0.02); hi = min(1, ws(i)+0.02);
w = fminbnd(obj, lo, hi, optimset('Display','off'));
[~, g, yhat] = sse_for_w(w, BS, BT, data);
end

function [sse, g, yhat] = sse_for_w(w, BS, BT, data)
pred = w*BT + (1-w)*BS;
g = (pred(:)'*data(:)) / (pred(:)'*pred(:));
yhat = g*pred;
sse = sum((data(:)-yhat(:)).^2);
end
