function show_figure5(saveFig, figDir)
%
% Visualizes figure 5 from paper:
% Group BOLD response time courses and model predictions
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
ROInames        = {'localizerROI-S1'};
models          = {'NORM', 'HRF'}; %{'NORM', 'HRF'};
allResults      = loadResultsfMRI(projectName);
expInfo         = visualizationSettings(models);

%-- tactile response time courses w/ model predictions
tcourseFig      = figure('Color', [1 1 1], 'Position', [30 300 700 390]);
set(tcourseFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[700 390])

%-- Loop across all pulse conditions
ybounds         = [-0.4 1.4];
for ii = 1:expInfo.numCond

    figure(tcourseFig)
    subplot(2,numel(allResults.onePulseIndx),ii)
    hold on,
    plot([0 allResults.x_data(end)], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    hCI = fill([allResults.x_data, fliplr(allResults.x_data)], ...
        [squeeze(allResults.cResp95(ii,:,1)), fliplr(squeeze(allResults.cResp95(ii,:,2)))], ...
        'k', 'HandleVisibility', 'off');
    hCI.FaceAlpha = 0.2; hCI.EdgeColor = [1 1 1];
    plot(allResults.x_data, allResults.resp(ii,:)', ...
        '.k-', 'LineWidth', 2, 'MarkerSize', 15, 'HandleVisibility', 'off')

    plot(allResults.x_data, allResults.NORMpred(ii,:), 'Color', expInfo.mColors(1,:), 'LineWidth', 2)
    plot(allResults.x_data, allResults.HRFpred(ii,:), 'Color', expInfo.mColors(2,:), 'LineWidth', 2)

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
% Create figure title
titleStr    = sprintf('%s %s \n %s{%f %f %f} %smodel crossval R2: %.2f \n', 'group', ROInames{1}, '\color[rgb]', expInfo.mColors(1,:), 'NORM', allResults.NORMcrossR2);
titleStr    = cat(2, titleStr, sprintf('%s{%f %f %f} %smodel crossval R2: %.2f \n', '\color[rgb]', expInfo.mColors(2,:), 'HRF', allResults.HRFcrossR2));

subplot(2,numel(allResults.onePulseIndx),expInfo.numCond)
legend(models)

sgtitle(titleStr, 'fontsize', 20)

if saveFig > 0
    print(tcourseFig, fullfile(figDir, sprintf('fig5a_%s_timeCourses_wPred', 'fMRI')), '-dpdf')
end

%-- Model parameters
paramFig        = figure('Color', [1 1 1], 'Position', [30 300 700 250]);
set(paramFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize', [700 250])

for wModel = 1:numel(models)

    model           = models{wModel};
    modelSett       = visualizationSettings(models, model);

    c = 1;
    axOrder     = [5 6 1 2 3 4];

    for ii = 1:modelSett.totParams

        subplot(1,6,axOrder(ii))

        % skip plotting if current model does not have this param
        if strcmp(modelSett.allLabels{ii}, modelSett.mLabels{c})

            hold on,
            % median with 68 and 95 CI intervals
            plot(wModel * ones(1,2), allResults.(sprintf('c%sparams95', model))(c,:), 'Color', [0.8 0.8 0.8], 'LineWidth', 3)
            plot(wModel * ones(1,2), allResults.(sprintf('c%sparams68', model))(c,:), 'Color', modelSett.color, 'LineWidth', 3)
            scatter(wModel, median(allResults.(sprintf('%sparams', model))(c,:)), 100, modelSett.color, 'filled')

            c = c+1;

        end

        if wModel == numel(models)
            box off; axis square
            title(modelSett.labels{ii}, 'Interpreter', 'none')
            % ensure 2 gammas have same axes
            if strcmp(modelSett.allLabels{ii}, 'gamma2')

                oldLim = currLim;
                currLim = get(gca, 'YLim'); currLim = [floor(currLim(1)) ceil(currLim(2))];

                currLim(1) = floor(min(oldLim(1), currLim(1)));
                currLim(2) = ceil(max(oldLim(2), currLim(2)));
                subplot(1,6,axOrder(ii-1))
                ylim(currLim)
                set(gca, 'xtick', 1:numel(models), 'xticklabel', models, ...
                    'tickdir', 'out', 'ytick', linspace(currLim(1),currLim(2), 5));
                subplot(1,6,axOrder(ii))
                ylim(currLim)
                set(gca, 'xtick', 1:numel(models), 'xticklabel', models, ...
                    'tickdir', 'out', 'ytick', linspace(currLim(1),currLim(2), 5));
            else
                currLim = get(gca, 'YLim'); currLim =  [floor(currLim(1)*10)/10 ceil(currLim(2)*10)/10];
                ylim(currLim)
                set(gca, 'xtick', 1:numel(models), 'xticklabel', models, ...
                    'tickdir', 'out', 'ytick', linspace(currLim(1),currLim(2), 5));
            end
            %                 ylim([modelSett.mBounds(1,ii) currLim(2)])
            xlim([0 numel(models)+1])

        end
    end


end

if saveFig > 0
    print(tcourseFig, fullfile(figDir, sprintf('fig5b_%s_modelParams', 'fMRI')), '-dpdf')
end
