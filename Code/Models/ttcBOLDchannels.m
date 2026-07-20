function [BS, BT] = ttcBOLDchannels(fixedP)
% TTCBOLDCHANNELS  Precompute the fixed BOLD channel responses for the fMRI
% two-temporal-channel model. Because the Stigliani channel IRFs and the HRF
% are all fixed, the sustained and (squared) transient BOLD responses do not
% depend on the free parameters (weight, gain) and can be computed once.
%
%   [BS, BT] = ttcBOLDchannels(fixedP)
%   fixedP must contain: x_data, numConditions, ConditionNames, stimdur,
%   twoPulseDur, and hrfParams = [gamma1 gamma2 gamma2_gain].
%   Returns BS, BT : numTR x numConditions (sustained, squared-transient),
%   already HRF-convolved and downsampled to 1-s volumes.

normSum  = @(x) x./sum(x(:));
samples  = 1000;
dt       = 1/samples;
numTRs   = numel(fixedP.x_data);
finer_t  = 0:1:4*samples;
t_length = numTRs * samples;

% two-channel neural IRFs (Stigliani 2017, from TTCSTIG17.m)
h        = @(tau, n, tt) (tau*factorial(n-1))^-1 * (tt/tau).^(n-1) .* exp(-tt/tau);
t_irf    = (1 : round(0.150*samples))';
tau = 4.94; n1 = 9;
irf_sustained = h(tau, n1, t_irf);
kappa = 1.33; tau2 = kappa*tau; n2 = 10; xi = 1.44;
irf_transient = xi * (irf_sustained - h(tau2, n2, t_irf));

% fixed HRF (shared with the linear/normalization models)
g1 = fixedP.hrfParams(1); g2 = fixedP.hrfParams(2); s2 = fixedP.hrfParams(3);
hrf_t = fixedP.x_data(1):dt:100;
hirf  = gampdf(hrf_t, g1, 1) - (s2 * gampdf(hrf_t, g2, 1));
hirf  = hirf(1:(numTRs-4)*samples);
hirf  = normSum(hirf);

BS = NaN(numTRs, fixedP.numConditions);
BT = NaN(numTRs, fixedP.numConditions);

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

    rspT = convCut(stimSeq, irf_transient, length(finer_t));
    rspT = abs(rspT).^2;
    rspS = convCut(stimSeq, irf_sustained, length(finer_t));

    bT = convCut(rspT, hirf, t_length);
    bS = convCut(rspS, hirf, t_length);
    BT(:,cond) = mean(reshape(bT, samples, numTRs), 1);
    BS(:,cond) = mean(reshape(bS, samples, numTRs), 1);
end
end

function output = convCut(TS, impulse, nTerms)
output = conv(squeeze(TS), squeeze(impulse), 'full');
output = output(1:nTerms);
end
