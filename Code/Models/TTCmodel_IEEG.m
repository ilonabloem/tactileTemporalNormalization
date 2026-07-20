function pred_neural = TTCmodel_IEEG(freeP, fixedP)
% TTCMODEL_IEEG  iEEG two-temporal-channel model (Stigliani 2017).
% Mirrors LINmodel_IEEG.m (same stimulus construction, shift handling,
% srate/time base) but predicts the broadband time course as a weighted sum
% of a linear sustained channel and a squared transient channel. IRF forms
% and constants are taken from Groen 2022 TTCSTIG17.m.
%
% freeP(1): weight -- relative weight on transient channel ([0 1])
% freeP(2): shift  -- onset delay (ms)
% freeP(3): scale  -- response gain
%
% output: pred_neural, timepoint x condition

weight = freeP(1);
shift  = freeP(2);
scale  = freeP(3);

%% set-up (identical to LINmodel_IEEG)
samples    = fixedP.srate;             % Hz
dt         = 1/samples;                % s
finer_t    = fixedP.t(1):dt:4;         % model out to 4 s
numTimepts = length(fixedP.t);

%% two-channel neural IRFs (Stigliani 2017, from TTCSTIG17.m); time in ms
h        = @(tau, n, tt) (tau*factorial(n-1))^-1 * (tt/tau).^(n-1) .* exp(-tt/tau);
t_irf    = 1000 * (1/samples : 1/samples : 0.150)';
tau      = 4.94;  n1 = 9;
irf_sustained = h(tau, n1, t_irf);
kappa    = 1.33;  tau2 = kappa*tau;  n2 = 10;  xi = 1.44;
irf_transient = xi * (irf_sustained - h(tau2, n2, t_irf));

%% predict
pred_neural = NaN(numTimepts, fixedP.numConditions);

for cond = 1:fixedP.numConditions

    if isfield(fixedP,'x_data') && size(fixedP.x_data,2) == fixedP.numConditions
        stimSeq = fixedP.x_data(:,cond);
        stimSeq = interp1(fixedP.t, stimSeq, fixedP.t - shift*1e-3, [], 0);
    else
        if contains(fixedP.ConditionNames(cond), 'ONE')
            idx     = str2double(regexp(fixedP.ConditionNames{cond}, '\d+$', 'match', 'once'));
            stimDur = fixedP.stimdur(idx);
            stimSeq = double(finer_t >= 0 & finer_t < stimDur);
        elseif contains(fixedP.ConditionNames(cond), 'TWO')
            idx         = str2double(regexp(fixedP.ConditionNames{cond}, '\d+$', 'match', 'once'));
            stimDur     = fixedP.stimdur(idx);
            twoPulseDur = fixedP.twoPulseDur;
            stimSeq = double( ...
                (finer_t >= 0 & finer_t < twoPulseDur) | ...
                (finer_t >= (stimDur + twoPulseDur) & finer_t < (stimDur + 2*twoPulseDur)) );
        else
            stimSeq = zeros(size(finer_t));
        end
        stimSeq = interp1(finer_t, stimSeq, finer_t - shift*1e-3, [], 0);
    end

    rspTransient = convCut(stimSeq, irf_transient, numTimepts);
    rspTransient = abs(rspTransient).^2;            % transient nonlinearity
    rspSustained = convCut(stimSeq, irf_sustained, numTimepts);

    pred_neural(:,cond) = scale .* (weight*rspTransient + (1-weight)*rspSustained);
end

end

%% utility
function output = convCut(TS, impulse, nTerms)
output = conv(squeeze(TS), squeeze(impulse), 'full');
output = output(1:nTerms);
end
