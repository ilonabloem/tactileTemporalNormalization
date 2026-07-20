function dsBoldPred = TTCmodel(freeP, fixedP)
% TTCMODEL  fMRI two-temporal-channel model (Stigliani 2017) for tactile data.
%
% Mirrors HRFmodel.m / NORMmodel.m (same stimulus construction, HIRF form,
% 1-s downsampling). The neural stage is a sustained (linear) + transient
% (squared) two-channel model with FIXED channel IRFs, as in Zhou 2018 /
% Groen 2022 (TTCSTIG17.m). The HRF is also fixed (shared with the linear /
% normalization models); only the transient weight and a gain are free.
%
% freeP(1): weight -- relative weight on the transient channel ([0 1])
% freeP(2): gain   -- overall response gain
% fixedP.hrfParams = [gamma1 gamma2 gamma2_gain]  (fixed HRF shape)
%
% output: dsBoldPred, timepoint x condition

weight = freeP(1);
gain   = freeP(2);

normSum  = @(x) x./sum(x(:));
samples  = 1000;
dt       = 1/samples;
numTRs   = numel(fixedP.x_data);
finer_t  = 0:1:4*samples;
t_length = numTRs * samples;

% two-channel neural IRFs (Stigliani 2017 constants)
h        = @(tau, n, tt) (tau*factorial(n-1))^-1 * (tt/tau).^(n-1) .* exp(-tt/tau);
t_irf    = (1 : round(0.150*samples))';
tau = 4.94; n1 = 9;
irf_sustained = h(tau, n1, t_irf);
kappa = 1.33; tau2 = kappa*tau; n2 = 10; xi = 1.44;
irf_transient = xi * (irf_sustained - h(tau2, n2, t_irf));

% fixed BOLD HIRF (shared with linear/normalization models)
g1 = fixedP.hrfParams(1); g2 = fixedP.hrfParams(2); s2 = fixedP.hrfParams(3);
hrf_t = fixedP.x_data(1):dt:100;
hirf  = gampdf(hrf_t, g1, 1) - (s2 * gampdf(hrf_t, g2, 1));
hirf  = hirf(1:(numTRs-4)*samples);
hirf  = normSum(hirf);

dsBoldPred = NaN(numTRs, fixedP.numConditions);
for cond = 1:fixedP.numConditions
    strComp = strsplit(fixedP.ConditionNames{cond}, '-');
    if contains(fixedP.ConditionNames(cond), 'ONE')
        stimDur   = fixedP.stimdur(str2double(strComp{end}));
        adstimDur = stimDur * samples;
        stimSeq   = finer_t >= 0 & finer_t < adstimDur;
    elseif contains(fixedP.ConditionNames(cond), 'TWO')
        stimDur       = fixedP.stimdur(str2double(strComp{end}));
        adstimDur     = stimDur * samples;
        adtwoPulseDur = fixedP.twoPulseDur * samples;
        stimSeq = (finer_t >= 0 & finer_t < adtwoPulseDur) | ...
            (finer_t >= (adstimDur + adtwoPulseDur) & ...
             finer_t <  (adstimDur + 2 * adtwoPulseDur));
    else
        stimSeq = zeros(size(finer_t));
    end
    stimSeq = double(stimSeq);

    rspTransient = convCut(stimSeq, irf_transient, length(finer_t));
    rspTransient = abs(rspTransient).^2;
    rspSustained = convCut(stimSeq, irf_sustained, length(finer_t));
    neural       = weight*rspTransient + (1-weight)*rspSustained;

    boldPred = convCut(neural, hirf, t_length);
    dsBoldPred(:,cond) = gain .* mean(reshape(boldPred, samples, numTRs), 1);
end
end

function output = convCut(TS, impulse, nTerms)
output = conv(squeeze(TS), squeeze(impulse), 'full');
output = output(1:nTerms);
end
