function show_figure9(saveFig, figDir)
%
% Visualizes figure 9 from paper:
% IEEG fits predict BOLD response
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
models          = {'DN', 'LIN'}; %{'DN', 'LIN'};
subjNames       = {'group'}; 
ieegresults     = loadResultsIEEG(projectName);
fmriresults     = loadResultsfMRI(projectName);

% Indices for fMRI
onePulseIndx    = fmriresults.onePulseIndx;

Responses       = fmriresults.resp;
cResponses68    = fmriresults.cResp68;
cResponses95    = fmriresults.cResp68;

% Use the average iEEG time courses
t_idx           = ieegresults(1,1).t > -0.1 & ieegresults(1,1).t < 2;
ieeg_data       = ieegresults(1, 1).y_data(t_idx,:);

% Predict fMRI responses by scaling model prediction to iEEG
% use same conditions (fmri conditions isi 0 and dur 0.4 are identical)
fmriindx        = ismember(fmriresults.condNames, ieegresults(1,1).condOrder);

scaler          = sum(ieeg_data,1)' \ sum(Responses(fmriindx,:),2);

% Load data for each model, collect predictions and summed data
outs            = cell(1,2);
preds           = cell(1,2);
modelSett       = visualizationSettings(models, models{1});
opt             = [];
opt.stimdur     = modelSett.stimDur;
opt.ConditionNames = modelSett.condNames;
opt.numConditions = numel(opt.ConditionNames);
summedPred      = NaN(opt.numConditions,2);
R2_scaled       = NaN(1,2);

for mm = 1:numel(models)
   
    % Tactile bootstrapped model parameters
    tactile_iEEGparams = median(ieegresults(mm,2).params,2);

    % create finer sampling for model prediction
    outs{mm}    = createSmoothPrediction(tactile_iEEGparams, ieegresults(mm,1), true);
    preds{mm}   = outs{mm}.pred; % summed across time-series  

    % create model prediction for same stimuli as fMRI to compute R2
    tmp             = createSmoothPrediction(tactile_iEEGparams, ieegresults(mm,1), true, opt);
    summedPred(:,mm) = sum(tmp.pred,2) * scaler;
    y_data          = sum(Responses,2);
    R2_scaled(mm)   = 1 - sum((y_data(:) - summedPred(:,mm)).^2, 1) ./ sum((y_data(:) - mean(y_data(:), 1)).^2, 1);
end


% Initialize figure
fmriSummaryFig = figure('Color', [1 1 1], 'Position', [0 0 550 260]);
set(fmriSummaryFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[550 260])
T = tiledlayout(1, 3,'TileIndexing','rowmajor');
T.Title.String = sprintf('r2: %s = %.3f   %s = %.3f,  %s', ...
    models{1}, R2_scaled(1), models{2}, R2_scaled(2), subjNames{1});

for wModel = 1:numel(models)

    modelSett   = visualizationSettings(models, models{wModel});
    if wModel == 1

        xvalues         = modelSett.stimDur;

        %-- one pulse
        t1 = tiledlayout(T,1,3,'TileIndexing','columnmajor');
        t1.Layout.Tile = 1;
        ax1 = nexttile(t1,[1 1]);
        hold on,
        plot([-0.1 0.1], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
        plot(0 .* [1; 1], squeeze(sum(cResponses95(1,:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(0 .* [1; 1], squeeze(sum(cResponses68(1,:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(0,  sum(Responses(1, :),2), '.k', 'MarkerSize', 25,  'HandleVisibility', 'off')

        ax2 = nexttile(t1,[1 2]);
        hold on
        plot([0.04 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
        plot(xvalues(2:end) .* [1; 1], squeeze(sum(cResponses95(2:numel(modelSett.stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xvalues(2:end) .* [1; 1], squeeze(sum(cResponses68(2:numel(modelSett.stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xvalues(2:end),  sum(Responses(2:numel(modelSett.stimDur), :),2), '.k', 'MarkerSize', 25,  'HandleVisibility', 'off')

        %-- paired pulse
        t2 = tiledlayout(T,1,3,'TileIndexing','columnmajor');
        t2.Layout.Tile = 2;
        ax3 = nexttile(t2,[1 1]);
        hold on
        plot([-0.1 0.1], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
        plot(0 .* [1; 1], squeeze(sum(cResponses95((1)+numel(onePulseIndx),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(0 .* [1; 1], squeeze(sum(cResponses68((1)+numel(onePulseIndx),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(0,  sum(Responses((1)+numel(onePulseIndx), :),2), '.k', 'MarkerSize', 25,  'HandleVisibility', 'off')

        ax4 = nexttile(t2,[1 2]);
        hold on
        plot([0.04 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
        plot(xvalues(2:end) .* [1; 1], squeeze(sum(cResponses95((2:numel(modelSett.stimDur))+numel(modelSett.stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xvalues(2:end) .* [1; 1], squeeze(sum(cResponses68((2:numel(modelSett.stimDur))+numel(modelSett.stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xvalues(2:end),  sum(Responses((2:numel(modelSett.stimDur))+numel(modelSett.stimDur), :),2), '.k', 'MarkerSize', 25,  'HandleVisibility', 'off')


        %-- linear xaxis
        t3 = tiledlayout(T,2,1,'TileIndexing','columnmajor');
        t3.Layout.Tile = 3;
        ax5 = nexttile(t3, [1 1]);
        hold on
        plot([-0.05 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
        plot(xvalues .* [1; 1], squeeze(sum(cResponses95(1:numel(modelSett.stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xvalues .* [1; 1], squeeze(sum(cResponses68(1:numel(modelSett.stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xvalues,  sum(Responses(1:numel(modelSett.stimDur), :),2), '.k', 'MarkerSize', 10,  'HandleVisibility', 'off')

        ax6 = nexttile(t3,[1 1]);
        hold on
        plot([-0.05 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
        plot(xvalues .* [1; 1], squeeze(sum(cResponses95((1:numel(modelSett.stimDur))+numel(modelSett.stimDur),:,:),2))', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xvalues .* [1; 1], squeeze(sum(cResponses68((1:numel(modelSett.stimDur))+numel(modelSett.stimDur),:,:),2))', 'Color', [0 0 0], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xvalues,  sum(Responses((1:numel(modelSett.stimDur))+numel(modelSett.stimDur), :),2), '.k', 'MarkerSize', 10,  'HandleVisibility', 'off')


    end

    out                 = outs{wModel};
    modelPrediction     = preds{wModel} .* scaler;
    onePulsePred        = modelPrediction(1:numel(out.stimdur), :);
    twoPulsePred        = modelPrediction(numel(out.stimdur)+1:end, :);
    plot(ax1, out.stimdur(out.stimdur < 0.01), sum(onePulsePred((out.stimdur < 0.01), :),2), 'Color', modelSett.color, 'LineWidth', 2)
    plot(ax2, out.stimdur(out.stimdur >= xvalues(2)-0.01), sum(onePulsePred((out.stimdur >= xvalues(2)-0.01), :),2), 'Color', modelSett.color, 'LineWidth', 2)

    plot(ax3, out.stimdur(out.stimdur < 0.01), sum(twoPulsePred((out.stimdur < 0.01), :),2), 'Color', modelSett.color, 'LineWidth', 2)
    plot(ax4, out.stimdur(out.stimdur >= xvalues(2)-0.01), sum(twoPulsePred((out.stimdur >= xvalues(2)-0.01), :),2), 'Color', modelSett.color, 'LineWidth', 2)

    plot(ax5, out.stimdur, sum(onePulsePred,2), 'Color', modelSett.color, 'LineWidth', 1)
    plot(ax6, out.stimdur, sum(twoPulsePred,2), 'Color', modelSett.color, 'LineWidth', 1)

    if wModel == numel(models)

        ybounds = get(ax2, 'YLim');
        ygap = 1;

        set(ax1, 'TickDir', 'out', 'XTick', 0, 'XTickLabel', 0, ...
            'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
            'YTick', ybounds(1):ygap:ybounds(2), 'YLim', ybounds, 'XLim', [-0.005 0.01]);
        ax2.Box = 'off';
        t1.Title.String = 'Single pulse conditions';
        t1.XLabel.String = 'Stimulus duration (s)';
        t1.YLabel.String = {'Summed BOLD time series';'(%SC)'};


        set(ax2, 'TickDir', 'out', 'XTick', [0.1 1], 'XTickLabel', [0.1 1], ...
            'Xscale', 'log', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
            'YTick', ybounds(1):ygap:ybounds(2), 'YLim', ybounds, 'XLim', [0.04 1.3]);
        ax2.Box = 'off';
        ax2.YAxis.Visible = 'off';

        set(ax3, 'TickDir', 'out', 'XTick', 0, 'XTickLabel', 0, ...
            'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
            'YTick', ybounds(1):ygap:ybounds(2), 'YLim', ybounds, 'XLim', [-0.005 0.01]);
        ax3.Box = 'off';
        t2.Title.String = 'Paired pulse conditions';
        t2.XLabel.String = 'Interstimulus interval (s)';
        t2.YLabel.String = {'Summed BOLD time series';'(%SC)'};

        set(ax4, 'TickDir', 'out', 'XTick', [0.1 1], 'XTickLabel', [0.1 1], ...
            'Xscale', 'log', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
            'YTick', ybounds(1):ygap:ybounds(2), 'YLim', ybounds, 'XLim', [0.04 1.3]);
        ax4.Box = 'off';
        ax4.YAxis.Visible = 'off';


        set(ax5, 'TickDir', 'out', 'XTick', 0:0.4:1.2, 'XTickLabel', 0:0.4:1.2, ...
            'FontSize', 8, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
            'YTick', ybounds(1):ygap:ybounds(2), 'YLim', ybounds, 'XLim', [-0.1 1.3]);
        ax5.Box = 'off';
        ax5.Title.String = 'Single pulse conditions';
        ax5.XLabel.String = 'Duration (s)';
        ax5.DataAspectRatio = [1 4 1];
        t3.YLabel.String = {'Summed BOLD time series';'(%SC)'};

        set(ax6, 'TickDir', 'out', 'XTick', 0:0.4:1.2, 'XTickLabel', 0:0.4:1.2, ...
            'FontSize', 8, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
            'YTick', ybounds(1):ygap:ybounds(2), 'YLim', ybounds, 'XLim', [-0.1 1.3]);
        ax6.Box = 'off';
        ax6.Title.String = 'Paired pulse conditions';
        ax6.DataAspectRatio = [1 4 1];
        ax6.XLabel.String = 'ISI (s)';

    end
end

if saveFig > 0
    print(fmriSummaryFig, fullfile(figDir, sprintf('fig9_predfMRI_summedResponses')), '-dpdf');
end
