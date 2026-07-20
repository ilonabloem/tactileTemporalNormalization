function show_fig6_TTC(figDir)
% SHOW_FIG6_TTC  Figure 6 (summed BOLD responses vs duration / ISI) with the
% two-temporal-channel (TTC) prediction added (orange). Direct fits.

here = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(here)));   % add repo Code tree (Models, Functions, ...)
if nargin<1 || isempty(figDir)
    [~, dataRootDir] = rootPath(false, 'tactileTemporalNormalization');
    figDir = fullfile(dataRootDir, '..', 'Figures');
end
if ~exist(figDir,'dir'), mkdir(figDir); end

allR = loadResultsfMRI('tactileTemporalNormalization');
tt   = fit_TTC_fMRI(false);
stimDur = allR.stimDur; nOne = numel(stimDur);

% data summed + bootstrapped CIs
sumData = allR.sumResp;                    % 14 x 1
bts     = allR.btstrSumResp;               % 14 x nboot
ci68 = prctile(bts, [16 84], 2);
ci95 = prctile(bts, [2.5 97.5], 2);

% fine-grid model summed predictions
fine = linspace(0, 1.2, 61);
optN.numConditions = 2*numel(fine); optN.stimdur = fine;
oNORM = createSmoothPrediction(allR.NORMparams,'NORM',false,optN);
oHRF  = createSmoothPrediction(allR.HRFparams ,'HRF' ,false,optN);
sN = sum(oNORM.pred,2); sH = sum(oHRF.pred,2);
predTTC = ttcDisplayPred(tt.weight, tt.gain, tt.hrfParams, fine, 0:10);
sT = sum(predTTC,2);
mOne = 1:numel(fine); mTwo = numel(fine)+1:2*numel(fine);

cNORM=[0.15 0.59 0.92]; cLIN=[0.50 0.80 0.35]; cTTC=[0.90 0.42 0.06];

f=figure('Color','w','Position',[30 300 760 340],'Visible','off');
titles={'Single pulse conditions','Paired pulse conditions'};
xlab={'Stimulus duration (s)','Interstimulus interval (s)'};
for pp=1:2
    if pp==1, di=1:nOne; mi=mOne; else, di=(1:nOne)+nOne; mi=mTwo; end
    subplot(1,2,pp); hold on;
    plot([-0.05 1.3],[0 0],'k','HandleVisibility','off');
    % data error bars (95 gray, 68 black) + dots
    for k=1:nOne
        plot(stimDur(k)*[1 1], ci95(di(k),:),'Color',[0.8 0.8 0.8],'LineWidth',2,'HandleVisibility','off');
        plot(stimDur(k)*[1 1], ci68(di(k),:),'Color',[0 0 0],'LineWidth',2,'HandleVisibility','off');
    end
    hD=plot(stimDur, sumData(di),'.k','MarkerSize',20);
    hN=plot(fine, sN(mi),'Color',cNORM,'LineWidth',2);
    hL=plot(fine, sH(mi),'Color',cLIN,'LineWidth',2);
    hT=plot(fine, sT(mi),'Color',cTTC,'LineWidth',2);
    xlim([-0.08 1.3]); ylim([-1 5]);
    set(gca,'TickDir','out','XTick',0:0.4:1.2,'FontSize',9,'LineWidth',1); box off;
    title(titles{pp},'FontSize',10); xlabel(xlab{pp});
    if pp==1, ylabel({'Summed BOLD time series','(%SC)'});
        legend([hD hN hL hT],{'Data','Normalization','Linear','Two-channel'},'FontSize',7,'Box','off','Location','northwest'); end
end
sgtitle('Summed BOLD responses (fMRI)','FontSize',11);

print(f, fullfile(figDir,'fig6_fMRI_summed_wTTC.png'),'-dpng','-r150');
print(f, fullfile(figDir,'fig6_fMRI_summed_wTTC.pdf'),'-dpdf','-vector','-bestfit');
close(f);
fprintf('[show_fig6_TTC] saved to %s\n', figDir);
end
