function dsBoldPred = NORMmodel(freeP, fixedP)

% inputs -----------------------------------------------------------

% init(1):  tau1, neural IRF peak time, in second
% init(2):  sigma, semi-saturation constant
% init(3):  response gain of the predicted neural response
% init(4):  gamma1 time to peak, in second
% init(5):  gamma2 time to peak, in second
% init(6):  gamma2 scaler

% outputs ----------------------------------------------------------
% dsBoldPred：   predicted BOLD response, timepoint x condition

%% set up parameters

% free parameters
tau1                = freeP(1);
n                   = 2; % fixed to 2
sigma               = freeP(2);
gain                = freeP(3);
g1                  = freeP(4);
g2                  = freeP(5); 
s2                  = freeP(6); 

% fixed
tau2                = 0;

%% simulate neural responses
normSum             = @(x) x./sum(x(:));

% stimulus time course
samples             = 1000;
dt                  = 1/samples; % in s
numTRs              = numel(fixedP.x_data);
finer_t             = 0:1:4*samples; % model out to 4s (max duration is 1.6s)
t_length            = numTRs * samples;

% set up h1, the impulse response function
h1_t                = fixedP.x_data(1):dt:2;
% h1                 = gampdf(finer_t, 2, tau1) - weight.* gampdf(finer_t, 2, tau1*1.5);
h1                  = gampdf(h1_t, 2, tau1); % assume weight = 0;
h1                  = normSum(h1);

% set up h2, low pass filter for linear response
h2                  = exp(-h1_t/tau2);
h2                  = normSum(h2);

% set up BOLD HIRF
hrf_t               = fixedP.x_data(1):dt:100; 
hirf                = gampdf(hrf_t, g1, 1) - (s2 * gampdf(hrf_t, g2, 1));
hirf                = hirf(1:(numTRs-4)*samples); % make HRF one TR shorter predicted neural response
hirf                = normSum(hirf);

% pre-allocate
dsBoldPred          = NaN(numTRs, fixedP.numConditions);


for cond            = 1:fixedP.numConditions
    
    %-- create contrast time course
    strComp         = strsplit(fixedP.ConditionNames{cond}, '-');
    % one-pulse condition
    if contains(fixedP.ConditionNames(cond), 'ONE')
    
        
        stimDur         = fixedP.stimdur(str2double(strComp{end}));
        adstimDur       = stimDur * samples;
        stimSeq         = finer_t >= 0 & finer_t < adstimDur;

    % two-pulse condition
    elseif contains(fixedP.ConditionNames(cond), 'TWO')
        
        stimDur         = fixedP.stimdur(str2double(strComp{end}));
        adstimDur       = stimDur * samples;
        adtwoPulseDur   = fixedP.twoPulseDur * samples;
    
        stimSeq         = (finer_t >= 0 & finer_t < adtwoPulseDur) | ...
            (finer_t >= (adstimDur + adtwoPulseDur) & ...
            finer_t < (adstimDur + 2 * adtwoPulseDur));
        
    % blank condition
    else
        stimSeq         = zeros(size(finer_t));
    end

    %-- predict neural responses by DN model

    % convolve with irf to create neural predictions
    if all(isnan(h1))
       linResp     = stimSeq;
    else
        linResp     = convCut(stimSeq, h1, length(finer_t));
    end
    
    % normalization numerator
    numResp     = linResp.^n;

    % normalization denominator
    if all(isnan(h2))
        poolResp    = linResp;
    else
        poolResp    = convCut(linResp, h2, length(finer_t));
    end
    demResp     = sigma.^n + poolResp.^n;

    % normalization response
    normResp    = numResp./demResp;

    %-- convolve with a HIRF to create BOLD prediction
    boldPred    = convCut(normResp, hirf, t_length);

    % downsample to match temporal resolution
%     dsBoldPred(:,cond)  = gain.*downsample(boldPred, fixedP.tr/dt);
    dsBoldPred(:,cond) = gain .* mean(reshape(boldPred, samples, numTRs),1);
    
end

 
end

%% utility function part

function output     = convCut(TS, impulse, nTerms)
    output          = conv(squeeze(TS), squeeze(impulse), 'full');
    output          = output(1:nTerms);
end
