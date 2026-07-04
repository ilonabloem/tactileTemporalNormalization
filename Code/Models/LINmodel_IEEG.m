function pred_neural = LINmodel_IEEG(freeP, fixedP)

% inputs -----------------------------------------------------------

% init(1):  tau1, neural IRF peak time, in second
% init(2):  weight, ratio of negative to positive IRFs (set to 0
%               for uniphasic irf)
% init(3):  tau2, time window of adaptation, in second
% init(4):  n, exponent
% init(5):  sigma, semi-saturation constant
% init(6):  shift, time between stimulus onset and when the signal reaches
%               the cortex (millisecond)
% init(7):  scale -- response gain

% outputs ----------------------------------------------------------
% pred_neural：   predicted neural response, timepoint x condition

%% set up parameters

% free parameters
if numel(freeP) < 4
    tau1                = freeP(1);
    w                   = 0;
    shift               = freeP(2);
    scale               = freeP(3);
else
    tau1                = freeP(1);
    w                   = freeP(2);
    shift               = freeP(3);
    scale               = freeP(4);
end

%% simulate neural responses
normSum             = @(x) x./sum(x(:));

% stimulus time course
samples             = fixedP.srate; % Hz
dt                  = 1/samples; % s
finer_t             = fixedP.t(1):dt:4; % model out to 4s (max duration is 1.6s)
numTimepts          = length(fixedP.t);

% set up h1, the impulse response function
h1_t                = 0:dt:2;
g1                  = gampdf(h1_t, 2, tau1);
g1Max               = max(g1(:));
g1                  = g1 ./ g1Max;
g2                  = gampdf(h1_t, 2, tau1*1.5) ./ g1Max;

h1                  = normSum(g1 - w.* g2);
% h1                  = gampdf(h1_t, 2, tau1) - w.* gampdf(h1_t, 2, tau1*1.5);
% h1                  = normSum(h1);

% pre-allocate
pred_neural     = NaN(numTimepts, fixedP.numConditions);

for cond            = 1:fixedP.numConditions
    
    if isfield(fixedP,'x_data') && size(fixedP.x_data,2) == numel(fixedP.numConditions)
        
        % get stimulus sequence
        stimSeq     = fixedP.x_data(:,cond);

        % add shift to the stimulus
        stimSeq     = interp1(fixedP.t, stimSeq, fixedP.t - shift*1e-3, [], 0);

    else % create contrast time course

        % one-pulse condition
        if contains(fixedP.ConditionNames(cond), 'ONE')

            idx             = str2double(regexp(fixedP.ConditionNames{cond}, '\d+$', 'match', 'once'));
            stimDur         = fixedP.stimdur(idx);
            stimSeq         = double(finer_t >= 0 & finer_t < stimDur);

            % two-pulse condition
        elseif contains(fixedP.ConditionNames(cond), 'TWO')

            idx             = str2double(regexp(fixedP.ConditionNames{cond}, '\d+$', 'match', 'once'));
            stimDur         = fixedP.stimdur(idx);
            twoPulseDur     = fixedP.twoPulseDur;
            stimSeq = double( ...
                (finer_t >= 0 & finer_t < twoPulseDur) | ...
                (finer_t >= (stimDur + twoPulseDur) & finer_t < (stimDur + 2*twoPulseDur)) );

            % blank condition
        else
            stimSeq         = zeros(size(finer_t));
        end

        % add shift (in ms) to the stimulus
        stimSeq = interp1(finer_t, stimSeq, finer_t - shift*1e-3, [], 0);

    end
    
    % convolve with irf to create neural predictions
    linResp     = convCut(stimSeq, h1, numTimepts);

    % scale the linear response
    pred_neural(:,cond)    = scale.*linResp;
    
end

 
end

%% utility function part

function output     = convCut(TS, impulse, nTerms)
    output          = conv(squeeze(TS), squeeze(impulse), 'full');
    output          = output(1:nTerms);
end
