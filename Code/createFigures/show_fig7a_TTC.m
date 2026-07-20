function show_fig7a_TTC(figDir)
% SHOW_FIG7A_TTC  Figure 7A (iEEG broadband time courses, data-only layout)
% with the two-temporal-channel (TTC) model prediction overlaid (orange).

here = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(here)));   % add repo Code tree (Models, Functions, ...)
[~,dr]=rootPath(false,'tactileTemporalNormalization');
if nargin<1 || isempty(figDir), figDir = fullfile(dr,'..','Figures'); end
if ~exist(figDir,'dir'), mkdir(figDir); end

fit_TTC_iEEG(true);
DN=load(fullfile(dr,'modelOutput_iEEG','DN','sub-group_model-DN_crossval-noCross_optimizer-bads_modelOutput_iEEG.mat'),'y_data','t','stim_ts');
TT=load(fullfile(dr,'modelOutput_iEEG','TTC','sub-group_model-TTC_crossval-noCross_optimizer-fmincon_modelOutput_iEEG.mat'),'y_est');
TTc=load(fullfile(dr,'modelOutput_iEEG','TTC','sub-group_model-TTC_crossval-withCross_optimizer-fmincon_modelOutput_iEEG.mat'),'R2');

t=DN.t; ti = t>=-0.2 & t<=2; ybounds=[-1 4];
oo=[0.90 0.42 0.06]; durs=[0.05 0.1 0.2 0.4 0.8 1.2];

f=figure('Color','w','Position',[30 300 720 320],'Visible','off');
T=tiledlayout(2,6,'TileIndexing','columnmajor','TileSpacing','tight','Padding','compact');
for col=1:12
    ii=col;
    ax=nexttile; hold(ax,'on');
    plot(ax,t(ti), DN.stim_ts(ti,ii)*ybounds(end),'Color',[.6 .6 .6],'HandleVisibility','off','LineWidth',1.2);
    plot(ax,[-0.2 2],[0 0],'k','HandleVisibility','off');
    hD=plot(ax,t(ti), DN.y_data(ti,ii),'k-','LineWidth',1.3);
    hT=plot(ax,t(ti), TT.y_est(ti,ii),'Color',oo,'LineWidth',1.4);
    ylim(ax,ybounds); xlim(ax,[-0.2 2]); set(ax,'TickDir','out','FontSize',8,'TickLength',[0.04 0.04]); box(ax,'off');
    if ii<=6, title(ax,sprintf('Dur %.2gs',durs(ii)),'FontSize',8);
    else, title(ax,sprintf('ISI %.2gs',durs(ii-6)),'FontSize',8); end
end
lgd=legend([hD hT],{'Data','Two-channel'},'FontSize',8,'Box','off','Orientation','horizontal');
lgd.Location='none'; lgd.Units='normalized'; lgd.Position=[0.5-0.11 0.01 0.22 0.035];
title(T, sprintf('iEEG broadband time courses with two-channel model  (cross-validated R^2 = %.2f)', TTc.R2),'FontSize',11);
% (x-axis shows time in s, 0-2; global label omitted to avoid legend overlap)
print(f, fullfile(figDir,'fig7a_iEEG_timeCourses_wTTC.png'),'-dpng','-r150');
print(f, fullfile(figDir,'fig7a_iEEG_timeCourses_wTTC.pdf'),'-dpdf','-vector','-bestfit');
close(f);
fprintf('[show_fig7a_TTC] saved to %s\n', figDir);
end
