
function show_figure2(saveFig, figDir)
%
% Visualizes figure 2 from paper:
% Temporal stimuli and measured BOLD response time courses 
%
% saveFig:      true or false
% figDir:       directory where figures are saved
%
% - Ilona Bloem

if ~exist('saveFig', 'var') || isempty(saveFig)
    saveFig     = false;
end

if ~exist('figDir', 'var') || isempty(figDir)
    [~, dataRootDir] = rootPath(false);
    figDir      = fullfile(dataRootDir, '..', 'Figures');
end

%-- create folder if it doesn't exists
if ~exist(figDir, 'dir'), mkdir(figDir); end


%-- load data
projectName     = 'tactileTemporalNormalization';
allResults      = loadResultsfMRI(projectName);
expInfo         = visualizationSettings;

%-- stimulus time courses

stimuliFig      = figure('Color', [1 1 1], 'Position', [30 300 550 300]);
set(stimuliFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[550 300])

figure(stimuliFig)
createStimSeq(expInfo, stimuliFig);
if saveFig > 0
    print(stimuliFig, fullfile(figDir, sprintf('fig2_fMRI_stimuliSeq')), '-dpdf')
end

%-- tactile response time courses
tcourseFig      = figure('Color', [1 1 1], 'Position', [30 300 700 390]);
set(tcourseFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[700 390])

%-- Loop across all pulse conditions
ybounds         = [-0.4 1.4];
for ii = 1:expInfo.numCond

    figure(tcourseFig)
    subplot(2,numel(allResults.onePulseIndx),ii)
    hold on,
    plot([0 allResults.x_data(end)], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    hCI = fill([allResults.x_data, fliplr(allResults.x_data)], [squeeze(allResults.cResp95(ii,:,1)), fliplr(squeeze(allResults.cResp95(ii,:,2)))], 'k', 'HandleVisibility', 'off');
    hCI.FaceAlpha = 0.2; hCI.EdgeColor = [1 1 1];
    plot(allResults.x_data, allResults.resp(ii,:)', '.k-', 'LineWidth', 2, 'MarkerSize', 15, 'HandleVisibility', 'off')
    if ii <= numel(allResults.onePulseIndx)
        title(sprintf('Dur %.2fs', allResults.stimDur(ii)), 'FontSize', 10)
    else
        title(sprintf('ISI %.2fs', allResults.stimDur(ii-numel(allResults.onePulseIndx))), 'FontSize', 10)
    end
    set(gca,'TickDir', 'out', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1)
    ylim(ybounds)
    set(gca, 'ytick', ybounds(1):0.4:ybounds(2), 'tickdir', 'out')
    box off

end

if saveFig > 0
    print(tcourseFig, fullfile(figDir, sprintf('fig2_%s_timeCourses', 'fMRI')), '-dpdf')
end
