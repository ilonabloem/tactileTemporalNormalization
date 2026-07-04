function dsBoldPred = HRFmodel(freeP, fixedP)

% inputs -----------------------------------------------------------

% init(1):  gain of the predicted BOLD responses
% init(2):  gamma1 time to peak, in second
% init(3):  gamma2 time to peak, in second
% init(4):  gamma2 gain

% outputs ----------------------------------------------------------
% dsBoldPred：   predicted BOLD response, timepoint x condition

%% set up parameters

% free parameters
gain                = freeP(1);
g1                  = freeP(2);
g2                  = freeP(3);
s2                  = freeP(4); 

%% simulate neural responses
normSum             = @(x) x./sum(x(:));

% stimulus time course
samples             = 1000;
dt                  = 1/samples; % in s
numTRs              = numel(fixedP.x_data);
finer_t             = 0:1:4*samples; % model out to 4s (max duration is 1.6s)
t_length            = numTRs * samples;

% set up BOLD HIRF
hrf_t               = fixedP.x_data(1):dt:100; 
hirf                = gampdf(hrf_t, g1, 1) - (s2 * gampdf(hrf_t, g2, 1));
hirf                = hirf(1:(numTRs-4)*samples); % make HRF one TR shorter predicted neural response
hirf                = normSum(hirf);

% pre-allocate
dsBoldPred          = NaN(numTRs, fixedP.numConditions);

for cond        = 1:fixedP.numConditions

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

    %-- Convolve with HRF to create BOLD prediction
    boldPred        = convCut(stimSeq, hirf, t_length);

    % downsample
%     dsBoldPred(:,cond) = gain.*downsample(boldPred, fixedP.tr/dt);
    dsBoldPred(:,cond) = gain .* mean(reshape(boldPred, 1000, numTRs),1);

end

end
%{
figure, 
plot(sum(dsBoldPred(:,1:6),1)), hold on, plot(sum(dsBoldPred(:,7:end),1))
summedPred = sum(dsBoldPred,1);
summedPred(7) - summedPred(end-1)
%}

%% utility function part

function output    = convCut(TS, impulse, nTerms)
    output         = conv(squeeze(TS), squeeze(impulse), 'full');
    output         = output(1:nTerms);
end
