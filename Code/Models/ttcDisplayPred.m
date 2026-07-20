function pred = ttcDisplayPred(weight, gain, hrfParams, stimdur, x_data)
% TTCDISPLAYPRED  fMRI TTC prediction for display conditions.
%   pred = ttcDisplayPred(weight, gain, hrfParams, stimdur, x_data)
%   stimdur : vector of durations/ISIs (e.g. [0 .05 .1 .2 .4 .8 1.2]); the
%             single- and paired-pulse conditions are built from it.
%   Returns pred: (2*numel(stimdur)) x numel(x_data), rows = single then paired.
n = numel(stimdur);
fp.stimdur     = stimdur;
fp.twoPulseDur = 0.2;
fp.x_data      = x_data;
fp.hrfParams   = hrfParams;
onN = cellstr(strcat('ONE-PULSE-', string(1:n)'));
twN = cellstr(strcat('TWO-PULSE-', string(1:n)'));
fp.ConditionNames = [onN; twN];
fp.numConditions  = 2*n;
pred = TTCmodel([weight gain], fp)';   % conditions x timepoints
end
