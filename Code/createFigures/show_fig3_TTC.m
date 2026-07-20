function show_fig3_TTC(figDir)
% SHOW_FIG3_TTC  Figure 3 (fMRI sub-additive temporal summation) with the
% two-temporal-channel (TTC) model prediction added (orange). Each panel shows
% the measured response to a single pulse (black), the linear-system
% prediction from a shorter pulse (red), and the TTC model fit (orange).

here = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(here)));   % add repo Code tree (Models, Functions, ...)
if nargin<1 || isempty(figDir)
    [~, dataRootDir] = rootPath(false, 'tactileTemporalNormalization');
    figDir = fullfile(dataRootDir, '..', 'Figures');
end
if ~exist(figDir,'dir'), mkdir(figDir); end

allR = loadResultsfMRI('tactileTemporalNormalization');
tt   = fit_TTC_fMRI(false);
% TTC single-pulse predictions at each display duration
TTCsingle = ttcDisplayPred(tt.weight, tt.gain, tt.hrfParams, allR.stimDur, allR.x_data); % 14 x 11
TTCsingle = TTCsingle(1:numel(allR.stimDur), :);  % one-pulse rows

% linear-system predictions (data-only), no drawing
data = createLinearSystemPredictions(allR);

% reconstruct index bookkeeping (mirror createLinearSystemPredictions)
singlePulseIndx = find(contains(allR.condNames,'ONE'));
singlePulseIndx = singlePulseIndx(allR.stimDur(:) >= 0.05 & allR.stimDur(:) <= 0.8);
numPulses = numel(singlePulseIndx)-1;
cTTC=[0.90 0.42 0.06];

f=figure('Color','w','Position',[30 200 620 560],'Visible','off');
t = tiledlayout(numPulses, numPulses,'TileSpacing','compact','Padding','compact');

for dur = numPulses:-1:1
    currDurIdx  = singlePulseIndx(dur);
    whichPulses = sort(singlePulseIndx(singlePulseIndx > currDurIdx),'descend');
    for nPred = 1:numel(whichPulses)
        toIdx = whichPulses(nPred);
        toDur = allR.stimDur(toIdx);
        ax = nexttile(sub2ind([numPulses,numPulses], dur, numPulses-nPred+1));
        hold(ax,'on');
        hR = plot(ax, allR.x_data, data(dur).responses(nPred,:),'.k-','MarkerSize',12,'LineWidth',1.5);
        hL = plot(ax, allR.x_data, data(dur).predictions(nPred,:),'r','LineWidth',1.5);
        % TTC prediction of the response to the "to" duration
        rowT = find(abs(allR.stimDur - toDur) < 1e-9, 1);
        hT = plot(ax, allR.x_data, TTCsingle(rowT,:),'Color',cTTC,'LineWidth',1.5);
        ylim(ax,[-0.5 5]); set(ax,'TickDir','out','ytick',0:1:5); box(ax,'off');
        if nPred==1, xlabel(ax, sprintf('%.2g s', allR.stimDur(currDurIdx))); end
        if dur==1,   ylabel(ax, sprintf('%.2g s', toDur),'Rotation',0); end
    end
end
xlabel(t,'Prediction from response to:','FontSize',12);
ylabel(t,'Response to:','FontSize',12);
title(t,'fMRI sub-additive temporal summation','FontSize',12);
lgd = legend([hR hL hT], {'Response to single pulse', ...
    'Linear-system prediction (shift & sum)','Two-channel model'}, 'FontSize',7,'Box','off');
lgd.Layout.Tile = sub2ind([numPulses,numPulses], numPulses-1, 1);

print(f, fullfile(figDir,'fig3_fMRI_subadditivity_wTTC.png'),'-dpng','-r150');
print(f, fullfile(figDir,'fig3_fMRI_subadditivity_wTTC.pdf'),'-dpdf','-vector','-bestfit');
close(f);
fprintf('[show_fig3_TTC] saved to %s\n', figDir);
end
