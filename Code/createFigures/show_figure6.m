function show_figure6(saveFig, figDir, showTTC, figName)
%
% Visualizes figure 6 from paper:
% Summary metric
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

if ~exist('showTTC', 'var') || isempty(showTTC) || false(showTTC)
    showTTC         = false;
    models          = {'NORM', 'HRF'}; %{'NORM', 'HRF', 'TTC'};
else
    showTTC         = true;
    models          = {'NORM', 'HRF', 'TTC'};
end

if ~exist('figName', 'var') || isempty(figName)
    figName        = 'fig6';
end

%-- create folder if it doesn't exists
if ~exist(figDir, 'dir'), mkdir(figDir); end

%-- load data
projectName     = 'tactileTemporalNormalization';
ROInames        = {'localizerROI-S1'};
allResults      = loadResultsfMRI(projectName, models);
expInfo         = visualizationSettings(models);
stimDur         = expInfo.stimDur;

%-- summed BOLD responses with predictions
summaryFig      = figure('Color', [1 1 1], 'Position', [30 300 550 260]);
set(summaryFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[550 260])
if showTTC
    T = tiledlayout(1, 1, 'TileIndexing', 'rowmajor');
else
    T = tiledlayout(1, 3, 'TileIndexing', 'rowmajor');
end

if ~showTTC
    %-- one pulse
    t1 = tiledlayout(T,1,3,'TileIndexing','columnmajor');
    t1.Layout.Tile = 1;
    ax1 = nexttile(t1,[1 1]);
    hold(ax1, 'on')
    plot(ax1, [-0.1 0.1], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    plot(ax1, 0 .* [1; 1], squeeze(sum(allResults.cResp95(1,:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(ax1, 0 .* [1; 1], squeeze(sum(allResults.cResp68(1,:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(ax1, 0,  allResults.sumResp(1, :), '.k', 'MarkerSize', 25,  'HandleVisibility', 'off')
    
    ax2 = nexttile(t1,[1 2]);
    hold(ax2, 'on')
    plot(ax2, [0.04 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    plot(ax2, stimDur(2:end) .* [1; 1], squeeze(sum(allResults.cResp95(2:numel(stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(ax2, stimDur(2:end) .* [1; 1], squeeze(sum(allResults.cResp68(2:numel(stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(ax2, stimDur(2:end),  allResults.sumResp(2:numel(stimDur), :), '.k', 'MarkerSize', 25,  'HandleVisibility', 'off')
    
    %-- paired pulse
    t2 = tiledlayout(T,1,3,'TileIndexing','columnmajor');
    t2.Layout.Tile = 2;
    ax3 = nexttile(t2,[1 1]);
    hold(ax3, 'on')
    plot(ax3, [-0.1 0.1], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    plot(ax3, 0 .* [1; 1], squeeze(sum(allResults.cResp95((1)+numel(stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(ax3, 0 .* [1; 1], squeeze(sum(allResults.cResp68((1)+numel(stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(ax3, 0,  allResults.sumResp(1+numel(stimDur), :), '.k', 'MarkerSize', 25,  'HandleVisibility', 'off')
    
    ax4 = nexttile(t2,[1 2]);
    hold(ax4, 'on')
    plot(ax4, [0.04 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    plot(ax4, stimDur(2:end) .* [1; 1], squeeze(sum(allResults.cResp95((2:numel(stimDur))+numel(stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(ax4, stimDur(2:end) .* [1; 1], squeeze(sum(allResults.cResp68((2:numel(stimDur))+numel(stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(ax4, stimDur(2:end),  allResults.sumResp((2:numel(stimDur))+numel(stimDur), :), '.k', 'MarkerSize', 25,  'HandleVisibility', 'off')

end

%-- linear xaxis
if showTTC
    t3 = tiledlayout(T,1,2,'TileIndexing','columnmajor');
    t3.Layout.Tile = 1;
else
    t3 = tiledlayout(T,2,1,'TileIndexing','columnmajor');
    t3.Layout.Tile = 3;
end
ax5 = nexttile(t3, [1 1]);
hold(ax5, 'on')
plot(ax5, [-0.05 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
plot(ax5, stimDur .* [1; 1], squeeze(sum(allResults.cResp95(1:numel(stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
plot(ax5, stimDur .* [1; 1], squeeze(sum(allResults.cResp68(1:numel(stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
plot(ax5, stimDur,  allResults.sumResp(1:numel(stimDur), :), '.k', 'MarkerSize', 10,  'HandleVisibility', 'off')

ax6 = nexttile(t3,[1 1]);
hold(ax6, 'on')
plot(ax6, [-0.05 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
plot(ax6, stimDur .* [1; 1], squeeze(sum(allResults.cResp95((1:numel(stimDur))+numel(stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
plot(ax6, stimDur .* [1; 1], squeeze(sum(allResults.cResp68((1:numel(stimDur))+numel(stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
plot(ax6, stimDur,  allResults.sumResp((1:numel(stimDur))+numel(stimDur), :), '.k', 'MarkerSize', 10,  'HandleVisibility', 'off')

%-- show model preditions
for wModel = 1:numel(models)
    model           = models{wModel};
    modelSett       = visualizationSettings(models, model);
    
    % create finer sampling for model prediction
    opt             = [];
    opt.numConditions = 482;
    opt.stimdur       = linspace(0, 1.2, opt.numConditions/2);
    if showTTC > 0
        opt.hrfParams = allResults.HRFparams(2:end);
    end

    out             = createSmoothPrediction(allResults.(sprintf('%sparams', model)), model, [], opt);
    modelPrediction = out.pred; 
    onePulsePred    = modelPrediction(1:numel(out.stimdur), :);
    twoPulsePred    = modelPrediction(numel(out.stimdur)+1:end, :);
    
    if ~showTTC
        plot(ax1, out.stimdur(out.stimdur < 0.01), sum(onePulsePred((out.stimdur < 0.01), :),2), 'Color', modelSett.color, 'LineWidth', 2)
        plot(ax2, out.stimdur(out.stimdur >= out.stimdur(2)-0.01), sum(onePulsePred((out.stimdur >= out.stimdur(2)-0.01), :),2), 'Color', modelSett.color, 'LineWidth', 2)
        plot(ax3, out.stimdur(out.stimdur < 0.01), sum(twoPulsePred((out.stimdur < 0.01), :),2), 'Color', modelSett.color, 'LineWidth', 2)
        plot(ax4, out.stimdur(out.stimdur >= out.stimdur(2)-0.01), sum(twoPulsePred((out.stimdur >= out.stimdur(2)-0.01), :),2), 'Color', modelSett.color, 'LineWidth', 2)
    end
    
    plot(ax5, out.stimdur, sum(onePulsePred,2), 'Color', modelSett.color, 'LineWidth', 1)
    plot(ax6, out.stimdur, sum(twoPulsePred,2), 'Color', modelSett.color, 'LineWidth', 1)

end

% change some figure settings
ybounds = get(ax5, 'YLim');
legend(ax5, models)

if ~showTTC
    set(ax1, 'TickDir', 'out', 'XTick', 0, 'XTickLabel', 0, ...
        'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
        'YTick', ybounds(1):1:ybounds(2), 'YLim', ybounds, 'XLim', [-0.005 0.01]);
    ax2.Box = 'off';
    t1.Title.String = 'Single pulse conditions';
    t1.XLabel.String = 'Stimulus duration (s)';
    t1.YLabel.String = {'Summed BOLD time series';'(%SC)'};
    
    
    set(ax2, 'TickDir', 'out', 'XTick', [0.1 1], 'XTickLabel', [0.1 1], ...
        'Xscale', 'log', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
        'YTick', ybounds(1):1:ybounds(2), 'YLim', ybounds, 'XLim', [0.04 1.3]);
    ax2.Box = 'off';
    ax2.YAxis.Visible = 'off';
    
    set(ax3, 'TickDir', 'out', 'XTick', 0, 'XTickLabel', 0, ...
        'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
        'YTick', ybounds(1):1:ybounds(2), 'YLim', ybounds, 'XLim', [-0.005 0.01]);
    ax3.Box = 'off';
    t2.Title.String = 'Paired pulse conditions';
    t2.XLabel.String = 'Interstimulus interval (s)';
    t2.YLabel.String = {'Summed BOLD time series';'(%SC)'};
    
    set(ax4, 'TickDir', 'out', 'XTick', [0.1 1], 'XTickLabel', [0.1 1], ...
        'Xscale', 'log', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
        'YTick', ybounds(1):1:ybounds(2), 'YLim', ybounds, 'XLim', [0.04 1.3]);
    ax4.Box = 'off';
    ax4.YAxis.Visible = 'off';

end

set(ax5, 'TickDir', 'out', 'XTick', 0:0.4:1.2, 'XTickLabel', 0:0.4:1.2, ...
    'FontSize', 8, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
    'YTick', ybounds(1):1:ybounds(2), 'YLim', ybounds, 'XLim', [-0.1 1.3]);
ax5.Box = 'off';
ax5.Title.String = 'Single pulse conditions';
ax5.XLabel.String = 'Duration (s)';
ax5.DataAspectRatio = [1 4 1];
t3.YLabel.String = {'Summed BOLD time series';'(%SC)'};

set(ax6, 'TickDir', 'out', 'XTick', 0:0.4:1.2, 'XTickLabel', 0:0.4:1.2, ...
    'FontSize', 8, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
    'YTick', ybounds(1):1:ybounds(2), 'YLim', ybounds, 'XLim', [-0.1 1.3]);
ax6.Box = 'off';
ax6.Title.String = 'Paired pulse conditions';
ax6.DataAspectRatio = [1 4 1];
ax6.XLabel.String = 'ISI (s)';

title(T, sprintf('Summed response: %s %s', 'group', ROInames{1}), 'Fontsize', 12)

if saveFig > 0
    print(summaryFig, fullfile(figDir, sprintf('%s_fMRI_summedResponses',figName)), '-dpdf')
end



