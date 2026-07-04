function show_figure7(saveFig, figDir)
%
% Visualizes figure 7 from paper:
% Group iEEG response time courses, temporal sub-additivity and recovery from adaptation 
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


%-- options
dataStr         = 'iEEG';
fileName        = 'selectData';
subjName        = 'sub-group';
bounds          = @(x) [floor(min(x(:))*10) ceil(max(x(:))*10)]/10;


%-- find results file
fnameList       = dir(fullfile(dataRootDir, dataStr, subjName, sprintf('%s_%s.mat', subjName, fileName)));
assert(~isempty(fnameList), 'ECoG select data file not found, verify paths')


%-- load data
results         = load(fullfile(fnameList.folder, fnameList.name), ...
    'avgELEC', 'avgBTST', 'avgROI', 'ROIs', 'stim_info', 't', 'stim_ts', 'srate');

x_data          = results.t;
stim_ts         = results.stim_ts;
stim_info       = results.stim_info;
xaxisScale      = 'lin'; % 'log' or 'lin'

%-- compute 68% CI
CIrange         = [16 84]; % to compute 68% CI
data            = results.avgELEC;
data_se         = cat(3, prctile(results.avgBTST, CIrange(1), 3), ...
    prctile(results.avgBTST, CIrange(2), 3));

% setup indexes
one_idx         = find(contains(stim_info.name, 'ONE-PULSE'));
xDur            = stim_info.duration(one_idx); % in s
pair_idx        = find(contains(stim_info.name, {'ONE-PULSE-4', 'TWO-PULSE'}));
xISI            = stim_info.ISI(pair_idx); %

%% - ECoG figure

% Panel A: ECoG time courses
ieegFig       = figure('Color', [1 1 1], 'Position', [30 300 650 300]);
set(ieegFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[650 300])
T1 = tiledlayout(2, 1,'TileIndexing','rowmajor', 'TileSpacing', 'tight', 'Padding','loose');
T1.Title.String = sprintf('iEEG time courses,  %s', subjName);

% limit ts
x_idx           = x_data >= -0.2 & x_data <= 2;

% combine one-pulse conditions
onePulseIndx    = find(contains(results(1).stim_info.name, 'ONE'));

% combine two-pulse conditions
twoPulseIndx    = cat(1, find(contains(results(1).stim_info.name, 'ONE-PULSE-4')), ...
    find(contains(results(1).stim_info.name, 'TWO')));

allPulsesIndx   = cat(1, onePulseIndx, twoPulseIndx);

ybounds = [-1 4];

Responses       = NaN(numel(allPulsesIndx), sum(x_idx));
ciResponses     = NaN(numel(allPulsesIndx), sum(x_idx), 2);

t = tiledlayout(T1,1,7,'TileIndexing','columnmajor', 'TileSpacing', 'tight', 'Padding','tight');
t.Layout.Tile = 1;
t.XLabel.String = 'Time (s)';
t.Title.String = 'Single Pulse Conditions';
nexttile(t,[1 1])
axis off

%-- Extract data for all pulse conditions
for ii = 1:numel(allPulsesIndx)

    % time series data & predictions
    Responses(ii,:)         = data(x_idx,allPulsesIndx(ii)); %results(1).data(:,allPulsesIndx(ii));

    % confidence interval data based on bootstrapped data
    ciResponses(ii,:,:)     = data_se(x_idx,allPulsesIndx(ii),:);

    %-- Visualize time courses for all pulse conditions
    figure(ieegFig)

    if ii == 7
        t = tiledlayout(T1,1,7,'TileIndexing','columnmajor', 'TileSpacing', 'tight', 'Padding','tight');
        t.Layout.Tile = 2;
        t.XLabel.String = 'Time (s)';
        t.Title.String = 'Paired Pulse Conditions';

    end

    nexttile(t,[1 1])
    hold on,
    plot(x_data(x_idx), stim_ts(x_idx, allPulsesIndx(ii)) * ybounds(end), 'Color', [.5 .5 .5], 'HandleVisibility', 'off')

    plot([-0.2 2], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
    hCI = fill([x_data(x_idx)', fliplr(x_data(x_idx)')], [squeeze(ciResponses(ii,:,1)), fliplr(squeeze(ciResponses(ii,:,2)))], 'k', 'HandleVisibility', 'off');
    hCI.FaceAlpha = 0.2; hCI.EdgeColor = 'none';
    plot(x_data(x_idx), Responses(ii,:)', 'k-', 'LineWidth', 2, 'HandleVisibility', 'off')
    if ii <= numel(onePulseIndx)
        title(sprintf('Dur %.2fs', xDur(ii)), 'FontSize', 10)
    else
        title(sprintf('ISI %.2fs', xISI(ii-numel(onePulseIndx))), 'FontSize', 10)
    end
    set(gca,'TickDir', 'out', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, 'TickLength', [0.05 0.05])
    ylim(ybounds)
    % set(gca, 'ytick', ybounds(1):0.4:ybounds(2), 'tickdir', 'out')
    box off

end

if saveFig > 0
    print(ieegFig, fullfile(figDir, sprintf('fig7a_iEEG_timecourses')), '-dpdf','-vector')
end

%% -- panel B: temporal sub-additivity
subAddFig      = figure('Color', [1 1 1], 'Position', [30 300 300 350]);
set(subAddFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[350 400])

% create linear system prediction
allResults              = struct;
allResults.condNames    = stim_info.name(one_idx);
allResults.stimDur      = xDur;
allResults.resp         = data(x_idx, one_idx)';
allResults.x_data       = x_data(x_idx);

createLinearSystemPredictions(allResults, subAddFig);

if saveFig > 0
    print(subAddFig, fullfile(figDir, sprintf('fig7b_iEEG_subAdditivity')), '-dpdf')
end

%% -- panel C: recovery from adaptation
recFig      = figure('Color', [1 1 1], 'Position', [30 300 250 350]);
set(recFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[250 400])
T1 = tiledlayout(2, 1,'TileIndexing','rowmajor');
ta = tiledlayout(T1,2,1,'TileIndexing','columnmajor');

% Select two conditions to plot
conditionsOfInterest = {'TWO-PULSE-2', 'TWO-PULSE-5'};
timepointsOfInterest = [-0.10 1.4];

tmp_idx        = find(contains(stim_info.name, conditionsOfInterest));
x_idx           = x_data>timepointsOfInterest(1) & x_data<=timepointsOfInterest(2);

maxResp         = max(data(x_idx,tmp_idx(1))); % scale stimulus to max of lowest duration
ybounds         = bounds(data(x_idx,tmp_idx) ./ maxResp);

% plot time courses + stimulus duration
for ii = 1:numel(conditionsOfInterest)
    nexttile(ta,[1,1])
    hold on
    plot(x_data(x_idx), stim_ts(x_idx, tmp_idx(ii)), 'Color', [.5 .5 .5], 'HandleVisibility', 'off')

    % se_conc  = [data_se(x_idx,stim_idx(ii),1); flipud(data_se(x_idx,stim_idx(ii),2))]';

    % hCI = fill([x_data(x_idx); flipud(x_data(x_idx))]', se_conc./maxResp, 'k', 'HandleVisibility', 'off');
    % hCI.FaceAlpha = 0.2; hCI.EdgeColor = [1 1 1];
    plot(x_data(x_idx), data(x_idx, tmp_idx(ii))./maxResp, 'k', 'LineWidth', 2)
    ylim(ybounds)

end
ta.Title.String = 'Paired pulse examples';
ta.XLabel.String = 'Time (s)';
ta.YLabel.String = 'Response magnitude';


% Compute recovery per electrode
srate           = 512;
[m, ~]          = computeISIrecovery(results.avgELEC,results.t,results.stim_info,srate, 0.4, [], 'max');

%-- compute 68% CI around recovery
[btstM, ~]      = computeISIrecovery(results.avgBTST,results.t,results.stim_info,srate, 0.4, [], 'max');
CIrange         = [16 84]; % to compute 68% CI
se              = cat(2, prctile(btstM, CIrange(1), 2), ...
    prctile(btstM, CIrange(2), 2));
ybounds         = bounds(se);

switch xaxisScale
    case 'log'

        % panel B - single pulses
        tb = tiledlayout(T1,1,3,'TileIndexing','columnmajor');
        tb.Layout.Tile = 2;

        nexttile(tb,[1 1])
        hold on
        plot(xISI(1), [1 1], 'k:', 'LineWidth', 2);
        plot(xISI(1)' .* [1; 1], se(1,:)', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xISI(1),  m(1), '.k', 'MarkerSize', 25)
        set(gca, 'TickDir', 'out', 'XTick', 0, 'XTickLabel', 0, ...
            'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
            'YTick', ybounds(1):1:ybounds(2), 'YLim', ybounds, 'XLim', [-0.005 0.01]);

        box off

        nexttile(tb,[1 2])
        hold on
        plot(xISI([2 end]), [1 1], 'k:', 'LineWidth', 2);
        plot(xISI(2:end)' .* [1; 1], se(2:end,:)', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xISI(2:end),  m(2:end), '.k', 'MarkerSize', 25)
        set(gca, 'TickDir', 'out', 'XTick', [0.1 1], 'XTickLabel', [0.1 1], ...
            'Xscale', 'log', 'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
            'YTick', ybounds(1):1:ybounds(2), 'YLim', ybounds, 'XLim', [0.04 1.3]);


        %         plot([0.04 1.3], [0 0], 'k', 'LineWidth', 1, 'HandleVisibility','off')
        %         plot(xISI(2:end)' .* [1; 1], sumResp_se(pair_idx(2:end),:)' ./ maxSum, 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        %         plot(xISI(2:end)',  sumResp(pair_idx(2:end)) ./ maxSum, '.k', 'MarkerSize', 25)
        %         set(gca, 'xscale', 'log', 'TickDir', 'out', 'XTick', [0.1 1], 'XTickLabel', [0.1 1], ...
        %             'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1, ...
        %             'YTick', ybounds(1):1000:ybounds(2));  xlim([0.1 1])
        %         legend({'summed Resp', 'linear pred'})
        box off
        tb.YLabel.String = {'Ratio second stimulus /', 'first stimulus'};
        tb.Title.String = 'Recovery from adaptation';
        tb.XLabel.String = 'Inter stimulus interval (s)';

    case 'lin'

        % recovery from adaptation
        tc = tiledlayout(T1,1,1,'TileIndexing','columnmajor');
        tc.Layout.Tile       = 2;
        tc.YLabel.String = {'Ratio second stimulus /', 'first stimulus'};
        tc.XLabel.String = 'Inter stimulus interval (s)';
        tc.Title.String = 'Recovery from adaptation';

        nexttile(tc,[1 1])
        hold on
        plot(xISI([1 end]), [1 1], 'k:', 'LineWidth', 2);
        plot(xISI' .* [1; 1], se', 'Color', [0.8 0.8 0.8], 'LineWidth', 2, 'HandleVisibility', 'off')
        plot(xISI,  m, '.k', 'MarkerSize', 25)
        set(gca, 'TickDir', 'out', 'XTick', 0:0.2:1.2, 'XTickLabel', 0:0.2:1.2, ...
            'FontSize', 10, 'XColor', 'k', 'YColor', 'k', 'LineWidth', 1);
        xlim([-0.1 1.2])

end

if saveFig > 0
    print(recFig, fullfile(figDir, sprintf('fig7c_iEEG_adaptationRecovery')), '-dpdf')
end