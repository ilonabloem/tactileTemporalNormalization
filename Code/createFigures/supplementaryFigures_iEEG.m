function supplementaryFigures_iEEG(saveFig, figDir)
%
% Visualizes supplementary figures from paper:
% Compare visual and tactile results
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


% Dependencies

% Model fits of both average-electrodes and individual-electrodes under dataRootDir/ECoG/visual and dataRootDir/ECoG/tactile
% ECoG_utils: groupElecsByVisualArea, averageWithinArea, bootstrWithinArea

%% Supplement Figure 1. Plot time series with DN prediction
model           = 'DN';
modelSett       = visualizationSettings(model, model);
saveFig         = true;

%% Load visual data and bootstrap parameter estimates 
% Load individual electrode fits from visual iEEG study
visual_fits = load(fullfile(dataRootDir, 'iEEG/visual', 'DN_xvalmode0_individualelecs.mat'), ...
                    'data', 'pred', 'stim_info', 'stim', 't', 'channels', 'params');

% Parameter names from DN model
v_param_names = {'tau1','weight','tau2', 'n', 'sigma', 'shift','scale'};
v_param_slc = find(~contains(v_param_names, {'shift', 'gain'})); % Exclude 'shift' parameter

% Process visual electrodes
[~, v_channels, group_prob] = groupElecsByVisualArea(visual_fits.channels, 'probabilisticresample');
v_nChans = height(v_channels);

% Compute avg time course
data    = median(visual_fits.data, 3, 'omitnan');
pred    = median(visual_fits.pred, 3, 'omitnan');

% Compute visual area parameter estimates by bootstrapping electrodes
visual_area_means = nan(length(v_param_slc), v_nChans);
visual_area_se = nan(length(v_param_slc), v_nChans, 2);
for p_idx = 1:length(v_param_slc)
    p = v_param_slc(p_idx);
    visual_params = visual_fits.params(p,:);
    [m, se] = averageWithinArea(visual_params, group_prob);
    visual_area_means(p_idx,:) = m;
    visual_area_se(p_idx,:,:) = se;
end

%% Load tactile data
%-- model output path
resultsDir      = fullfile(dataRootDir, 'modelOutput_iEEG', model);

%-- Results file names (bootstrapped, avg fits, and cross val R2)
fileNames       = dir(fullfile(resultsDir, sprintf('sub-group_model-%s_crossval-noCross_optimizer-bads_bstmodelOutput_iEEG.mat', model)));

% Tactile bootstrapped model parameters
results         = load(fullfile(resultsDir, fileNames(1).name), 'model', 'currModel', 'condOrder', 'x_data', 'y_data', 'y_est', 'params', 'R2', 'stim_info', 'stim_ts', 't');

modelSettings   = results.currModel([], {'initialize'});
t_param_names   = modelSettings.labels; 
t_param_slc     = find(~contains(t_param_names,  {'shift', 'gain'})); % Exclude 'shift' parameter

tactile_params  = results.params(t_param_slc,:);

%% Plot visual time courses
% Visual data and modelfit
stim_info   = visual_fits.stim_info;
stim_ts     = visual_fits.stim;
t           = visual_fits.t;
% limit ts
t_idx       = t >= -0.2 & t <= 2;
R2          = 1 - sum((data(:) - pred(:)).^2, 1) ./ sum((data(:) - mean(data(:), 1)).^2, 1);

% combine one-pulse conditions
onePulseIndx    = find(contains(stim_info.name, 'ONEPULSE'));

% combine two-pulse conditions
twoPulseIndx    = cat(1, find(contains(stim_info.name, 'ONEPULSE-5')), ...
                         find(contains(stim_info.name, 'TWO')));

n_one = numel(onePulseIndx);
n_two = numel(twoPulseIndx);
n_max = max(n_one, n_two);

xDur = stim_info.duration(onePulseIndx)';
xISI = stim_info.ISI(twoPulseIndx)';

% Initialize figure
tcourseFig      = figure('Color', [1 1 1], 'Position', [30 300 650 300]);
set(tcourseFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[650 300])
T1 = tiledlayout(2, 1, 'TileIndexing', 'rowmajor', 'TileSpacing', 'tight', 'Padding','loose');
T1.Title.String = sprintf('Cross-validated r2: %s = %.3f sub-group', ...
    model, R2(1));

bounds          = @(x) [floor(min(x(:))*10) ceil(max(x(:))*10)]/10;
ybounds         = bounds(prctile(data, [1 99], [1 3]));
if mod(ybounds(1), 0.2) > 0; ybounds(1) = ybounds(1)-0.2; end

% One-pulse conditions
h = tiledlayout(T1,1,7,'TileIndexing','columnmajor', 'TileSpacing', 'tight', 'Padding','tight');
h.Layout.Tile = 1;
h.XLabel.String = 'Time (s)';
h.Title.String = 'Single Pulse Conditions';
nexttile(h,[1 1])
axis off
for ii = 1:n_one

    ax = nexttile(h, [1 1]);
    hold(ax, 'on')
    plot(ax, t(t_idx), stim_ts(t_idx, onePulseIndx(ii)) * ybounds(end), 'Color', [.5 .5 .5], 'HandleVisibility', 'off','LineWidth', 1.5)
    plot(ax, [-0.2 2], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    plot(ax, t(t_idx), data(t_idx,onePulseIndx(ii)), 'k-', 'LineWidth', 1.5, 'DisplayName', 'Data')
    plot(ax, t(t_idx), pred(t_idx,onePulseIndx(ii)), 'Color', modelSett.color, 'LineWidth', 2, 'DisplayName', model)
    set(ax,'TickDir', 'out', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', ...
        'LineWidth', 1, 'TickLength', [0.05 0.05])
    title(ax, sprintf('Dur %.2fs', xDur(ii)), 'FontSize', 10)
    ylim(ax, ybounds)
    box(ax, 'off')

end

% Two-pulse conditions
h = tiledlayout(T1,1,7,'TileIndexing','columnmajor', 'TileSpacing', 'tight', 'Padding','tight');
h.Layout.Tile = 2;
h.XLabel.String = 'Time (s)';
h.Title.String = 'Paired Pulse Conditions';
for ii = 1:n_two
    
    ax = nexttile(h, [1 1]);
    hold(ax, 'on')
    plot(ax, t(t_idx), stim_ts(t_idx, twoPulseIndx(ii)) * ybounds(end), 'Color', [.5 .5 .5], 'HandleVisibility', 'off','LineWidth', 1.5)
    plot(ax, [-0.2 2], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    plot(ax, t(t_idx), data(t_idx,twoPulseIndx(ii)), 'k-', 'LineWidth', 1.5, 'DisplayName', 'Data')
    plot(ax, t(t_idx), pred(t_idx,twoPulseIndx(ii)), 'Color', modelSett.color, 'LineWidth', 2, 'DisplayName', model)
    set(ax,'TickDir', 'out', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', ...
        'LineWidth', 1, 'TickLength', [0.05 0.05])
    title(ax, sprintf('ISI %.2fs', xISI(ii)), 'FontSize', 10)
    ylim(ax, ybounds)
    box(ax, 'off')

end

if saveFig > 0
    print(tcourseFig, fullfile(figDir, sprintf('suppFig_iEEG_visual_timeCourses_wPred')), '-dpdf', '-vector');
end

%% Plot parameter estimates
paramFig = figure('Color', [1 1 1], 'Position', [100 100 1200 600]);
set(paramFig, 'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[1200 600])

for n = 1:numel(t_param_slc)
    p = t_param_slc(n);

    subplot(2, ceil(numel(t_param_slc)/2), n);
    hold on
    set(gca, 'LineWidth', 1, 'FontSize', 10, 'TickDir', 'out','TickLength', [0.05 0.05]);

    % Plot visual areas with error bars
    hold on,
    plot(ones(2,1)*(1:v_nChans), [visual_area_se(n,:,1); visual_area_se(n,:,2)], 'Color', 'k', 'LineWidth', 2)
    scatter(1:v_nChans, visual_area_means(n,:), 80, 'k', 'filled')

    % Plot tactile average with error bars
    tactile_pos = v_nChans + 1;
    hold on,
    % median with 68 and 95 CI intervals
    plot(tactile_pos*ones(1,2), prctile(tactile_params(n,:), [0 100] + (5/2 * [1 -1])), 'Color', [0.8 0.8 0.8], 'LineWidth', 2)
    plot(tactile_pos*ones(1,2), prctile(tactile_params(n,:), [0 100] + (32/2 * [1 -1])), 'Color', modelSett.color, 'LineWidth', 2)
    scatter(tactile_pos, median(tactile_params(n,:)), 80, modelSett.color, 'filled')

    all_labels = [v_channels.name; {'Tactile'};];

    xlim([0, v_nChans + 2]);
    xticks(1:(v_nChans + 1));
    xticklabels(all_labels);
    xtickangle(45);

    title(t_param_names{p}, 'FontSize', 20, 'Interpreter', 'latex');
    % ylabel('Parameter value', 'FontSize', 20);

    box off

    if p == 1; ylim([0 0.1]); end
    if p == 2; ylim([0 0.6]); end
    if p == 3; ylim([0 0.4]); end
    if p == 4; ylim([0.8 1.8]); end
    if p == 5; ylim([0 0.1]); end

end

% Save figures
if saveFig > 0
    saveas(paramFig, fullfile(figDir, sprintf('suppFig_iEEG_visual-VS-tactile_%s-parameters', model)), 'pdf');
end


