function show_fig5_TTC(figDir)
% SHOW_FIG5_TTC  Figure 5A (fMRI BOLD time courses + model fits) with the
% two-temporal-channel (TTC) prediction added (orange) alongside the
% normalization (blue) and linear (green) fits. Direct (non-cross-validated)
% fits. Companion to show_figure5.m.

here = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(here)));   % add repo Code tree (Models, Functions, ...)
if nargin<1 || isempty(figDir)
    [~, dataRootDir] = rootPath(false, 'tactileTemporalNormalization');
    figDir = fullfile(dataRootDir, '..', 'Figures');
end
if ~exist(figDir,'dir'), mkdir(figDir); end

allR = loadResultsfMRI('tactileTemporalNormalization');
tt   = fit_TTC_fMRI(true);                      % weight, gain, hrfParams, R2cv
TTCpred = ttcDisplayPred(tt.weight, tt.gain, tt.hrfParams, allR.stimDur, allR.x_data);

cNORM=[0.15 0.59 0.92]; cLIN=[0.50 0.80 0.35]; cTTC=[0.90 0.42 0.06];
nOne = numel(allR.onePulseIndx); ybounds=[-0.4 1.4];

f=figure('Color','w','Position',[30 300 720 400],'Visible','off');
for ii=1:14
    subplot(2,nOne,ii); hold on;
    plot([0 allR.x_data(end)],[0 0],'k','LineWidth',1,'HandleVisibility','off');
    hCI=fill([allR.x_data, fliplr(allR.x_data)], ...
        [squeeze(allR.cResp95(ii,:,1)), fliplr(squeeze(allR.cResp95(ii,:,2)))],'k','HandleVisibility','off');
    hCI.FaceAlpha=0.2; hCI.EdgeColor='none';
    plot(allR.x_data, allR.resp(ii,:),'.k-','LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off');
    hN=plot(allR.x_data, allR.NORMpred(ii,:),'Color',cNORM,'LineWidth',2);
    hL=plot(allR.x_data, allR.HRFpred(ii,:),'Color',cLIN,'LineWidth',2);
    hT=plot(allR.x_data, TTCpred(ii,:),'Color',cTTC,'LineWidth',2);
    if ii<=nOne, title(sprintf('Dur %.2fs',allR.stimDur(ii)),'FontSize',9);
    else, title(sprintf('ISI %.2fs',allR.stimDur(ii-nOne)),'FontSize',9); end
    set(gca,'TickDir','out','FontSize',8,'XColor','k','YColor','k','LineWidth',1);
    ylim(ybounds); set(gca,'ytick',ybounds(1):0.4:ybounds(2)); box off;
end
lgd=legend([hN hL hT],{'Normalization','Linear','Two-channel'},'FontSize',8,'Box','off','Orientation','horizontal');
lgd.Location='none'; lgd.Units='normalized'; lgd.Position=[0.5-0.17 0.01 0.34 0.035];
sgtitle(sprintf('fMRI BOLD time courses  (cross-validated R^2:  Normalization %.2f   Linear %.2f   Two-channel %.2f)', ...
    allR.NORMcrossR2, allR.HRFcrossR2, tt.R2cv),'FontSize',11);

print(f, fullfile(figDir,'fig5a_fMRI_timeCourses_wTTC.png'),'-dpng','-r150');
print(f, fullfile(figDir,'fig5a_fMRI_timeCourses_wTTC.pdf'),'-dpdf','-vector','-bestfit');
close(f);
fprintf('[show_fig5_TTC] saved to %s\n', figDir);
end

function r2 = r2fit(data, pred)
% data, pred: 14 x 11 (display conditions). R2 over all points.
d=data(:); p=pred(:);
r2 = 1 - sum((d-p).^2)/sum((d-mean(d)).^2);
end
