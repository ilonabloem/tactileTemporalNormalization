function show_figure8(saveFig, figDir, showTTC, figName)
%
% Visualizes figure 8 from paper:
% IEEG results
%
% saveFig:      true or false
% figDir:       directory where figures are saved
% showTTC:      if true also show TTC model prediction
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
    models          = {'DN', 'LIN'}; %{'NORM', 'HRF', 'TTC'};
else
    showTTC         = true;
    models          = {'DN', 'LIN', 'TTC'};
end

if ~exist('figName', 'var') || isempty(figName)
    figName        = 'fig8';
end

%-- create folder if it doesn't exists
if ~exist(figDir, 'dir'), mkdir(figDir); end

%-- load data
projectName     = 'tactileTemporalNormalization';
subjNames       = {'group'}; 
results         = loadResultsIEEG(projectName, models);
CV_R2           = NaN(1,numel(models));
for ii = 1:numel(models)
    CV_R2(ii)           = results(ii,3).R2;
end

%-- Panel A. Model illustration
if showTTC == 0
    modelSchematic('iEEG', figDir, saveFig)
end
%-- Panel B. Plot time series of the group data with model fits

% Data/stimulus, same for both models
data        = results(1,1).y_data;
stim_info   = results(1,1).stim_info;
stim_ts     = results(1,1).stim_ts;
t           = results(1,1).t;
% limit ts
t_idx       = t >= -0.2 & t <= 2;

% combine one-pulse conditions
onePulseIndx    = find(contains(results(1).condOrder, 'ONE-PULSE'));

% combine two-pulse conditions
twoPulseIndx    = cat(1, find(contains(results(1).condOrder, 'ONE-PULSE-4')), ...
                         find(contains(results(1).condOrder, 'TWO')));

n_one       = numel(onePulseIndx);
n_two       = numel(twoPulseIndx);

xDur        = stim_info.duration(onePulseIndx)';
xISI        = stim_info.ISI(twoPulseIndx)';

% Initialize figure
tcourseFig      = figure('Color', [1 1 1], 'Position', [30 300 650 300]);
set(tcourseFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[650 300])
T1 = tiledlayout(2, 1, 'TileIndexing', 'rowmajor', 'TileSpacing', 'tight', 'Padding','loose');
titleStr = 'Cross-validated r2: ';
for m = 1:numel(models)
    titleStr = cat(2, titleStr, sprintf('%s = %.2f, ', models{m}, CV_R2(m)));
end
titleStr = cat(2, titleStr, sprintf('sub-%s', subjNames{1}));

T1.Title.String = titleStr;
ybounds = [-1 4];

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
    for mm = 1:numel(models)
        modelSett   = visualizationSettings(models, models{mm});
        plot(ax, t(t_idx), results(mm,1).y_est(t_idx,onePulseIndx(ii)), 'Color', modelSett.color, 'LineWidth', 2, 'DisplayName', models{mm})
    end
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
    for mm = 1:numel(models)
        modelSett   = visualizationSettings(models, models{mm});
        plot(ax, t(t_idx), results(mm,1).y_est(t_idx,twoPulseIndx(ii)), 'Color', modelSett.color, 'LineWidth', 2, 'DisplayName', models{mm})
    end
    set(ax,'TickDir', 'out', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', ...
        'LineWidth', 1, 'TickLength', [0.05 0.05])
    title(ax, sprintf('ISI %.2fs', xISI(ii)), 'FontSize', 10)
    ylim(ax, ybounds)
    box(ax, 'off')

end

if saveFig > 0
    if showTTC == 0
        panelName = sprintf('%sb', figName);
    else
        panelName = figName;
    end
    print(tcourseFig, fullfile(figDir, sprintf('%s_iEEG_timeCourses_wPred', panelName)), '-dpdf', '-vector');
end

%-- Panel C. Bootstrapped parameter estimates across electrodes from both patients

% drop if TTC was requested
if showTTC == 0
    
    % setup figure
    paramFig = figure('Color', [1 1 1], 'Position', [30 300 700 150]);
    set(paramFig, 'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[700 150])
    
    DNinit      = fitDNmodel_IEEG([], {'initialize'});
    DNlabels    = DNinit.labels;
    DNlabels    = DNlabels(~contains(DNlabels, 'shift')); % Exclude 'shift' parameter

    % Tactile bootstrapped model parameters
    for m = 1:numel(models)
        model       = models{m};
        modelSett   = visualizationSettings(models, model);
        
        % find parameters
        init        = results(m,2).currModel([], {'initialize'});
        t_param_names = init.labels;
        t_param_slc = find(~contains(t_param_names, 'shift')); % Exclude 'shift' parameter
    
        tact_params = results(m,2).params(t_param_slc,:);
        c           = 1;
    
        for n = 1:numel(DNlabels) % DN model has 5 params without shift
           
            subplot(1, numel(DNlabels), n);
    
            % skip plotting if current model does not have this param
            if strcmp(DNlabels{n}, t_param_names{t_param_slc(c)})
                hold on
                set(gca, 'LineWidth', 1, 'FontSize', 10, 'TickDir', 'out','TickLength', [0.05 0.05]);
            
                % Plot tactile average with error bars
                hold on,
                % median with 68 and 95 CI intervals
                plot(m*ones(1,2), prctile(tact_params(c,:), [0 100] + (5/2 * [1 -1])), 'Color', [0.8 0.8 0.8], 'LineWidth', 3)
                plot(m*ones(1,2), prctile(tact_params(c,:), [0 100] + (32/2 * [1 -1])), 'Color', modelSett.color, 'LineWidth', 3)
                scatter(m, median(tact_params(c,:)), 100, modelSett.color, 'filled')
            
                c = c + 1;
            end
    
            if m == numel(models)
                xlim([0, numel(models)+1]);
                xticks(1:2);
                xticklabels(models);
    
                title(DNlabels{n}, 'FontSize', 20, 'Interpreter', 'latex');
                % ylabel('Parameter value', 'FontSize', 20);
            
                box off
            
                if n == 1; ylims = [0 0.1]; end
                if n == 2; ylims = [0 1]; end
                if n == 3; ylims = [0 0.3]; end
                if n == 4; ylims = [0.5 2.5]; end
                if n == 5; ylims = [0 0.1]; end
                if n == 6; ylims = [0 1.5]; end
                ylim(ylims), yticks(linspace(ylims(1), ylims(2), 5))
            end
        
        end
    end
    
    % Save figures
    if saveFig > 0
        print(paramFig, fullfile(figDir, sprintf('%sc_iEEG_modelParams', figName)), '-dpdf', '-vector');
    end
end