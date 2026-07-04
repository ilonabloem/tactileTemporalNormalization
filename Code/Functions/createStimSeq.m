
function out = createStimSeq(expInfo, figHandle)

if ~exist('expInfo', 'var') || isempty(expInfo)
    expInfo     = visualizationSettings();
end

if ~exist('figHandle', 'var') || isempty(figHandle)
    showFigure  = false;
else
    showFigure  = true;
end

samples         = 1000;
finer_t         = (0:1:2*samples)-1; 
stimSeq         = NaN(expInfo.numCond, numel(finer_t));
axIndx          = cat(2, 1:2:numel(expInfo.stimDur)*2, 2:2:numel(expInfo.stimDur)*2);

for cond        = 1:numel(expInfo.condNames)
    
    %-- create contrast time course

    % one-pulse condition
    if contains(expInfo.condNames(cond), 'ONE')
    
        strComp         = strsplit(expInfo.condNames{cond}, '-');
        stimDur         = expInfo.stimDur(str2double(strComp{end})+1);
        adstimDur       = stimDur * samples;
        stimSeq(cond,:) = finer_t >= 0 & finer_t < adstimDur;

    % two-pulse condition
    elseif contains(expInfo.condNames(cond), 'TWO')
        
        strComp         = strsplit(expInfo.condNames{cond}, '-');
        stimDur         = expInfo.stimDur(str2double(strComp{end})+1);
        adstimDur       = stimDur * samples;
        adtwoPulseDur   = expInfo.twoPulseDur * samples;
    
        stimSeq(cond,:) = (finer_t >= 0 & finer_t < adtwoPulseDur) | ...
            (finer_t >= (adstimDur + adtwoPulseDur) & ...
            finer_t < (adstimDur + 2 * adtwoPulseDur));
    end

    %-- visualize
    if showFigure
        figure(figHandle)
        subplot(numel(expInfo.stimDur),2, axIndx(cond))
        plot(finer_t, stimSeq(cond,:), 'k', 'LineWidth', 1.5)
        box off
        ylim([0 1]); set(gca, 'YTick', [], 'XTick', [])
        title(expInfo.condNames{cond}, 'Interpreter','tex')
    end
end

% output 
out     = stimSeq;