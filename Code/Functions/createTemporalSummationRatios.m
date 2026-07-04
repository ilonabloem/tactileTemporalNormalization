
function createTemporalSummationRatios(allResults, expInfo, figHandle)

if ~exist('allResults', 'var') || isempty(allResults)
    error('[%s] allResults struct should be given as input', mfilename)
end

if ~exist('expInfo', 'var') || isempty(expInfo)
    expInfo     = visualizationSettings();
end

if ~exist('figHandle', 'var') || isempty(figHandle)
    showFigure  = false;
else
    showFigure  = true;
end

%% (Sub-) Linear temporal summation

% Compare response to stimulus with length 2x divided by twice the response of x
singlePulseIndx = find(contains(expInfo.condNames, 'ONE-PULSE'));
singlePulseIndx = singlePulseIndx(expInfo.stimDur(:) >= 0.05 & expInfo.stimDur(:) <= 0.8);

%-- create linear prediction from single pulse data
meanSumDur      = allResults(1).sumResp(singlePulseIndx(2:end),:);
sumDur          = allResults(1).btstrSumResp(singlePulseIndx(2:end),:);
ciSumDur        = prctile(sumDur', [0 100] + (32/2 * [1 -1]))';
meanSumDurx2    = allResults(1).sumResp(singlePulseIndx(1:end-1),:) * 2;
sumDurx2        = allResults(1).btstrSumResp(singlePulseIndx(1:end-1),:) * 2;
ciSumDurx2      = prctile(sumDurx2', [0 100] + (32/2 * [1 -1]))';

%-- double pulse data
% doublePulseIndx = find(contains(expInfo.condNames, 'TWO-PULSE'));
% doublePulseIndx = doublePulseIndx(expInfo.stimDur(:) >= 0 & expInfo.stimDur(:) <= 0.8);
% sumITI          = allResults(1).btstrSumResp(doublePulseIndx(2:end),:);
% sumITIx2        = allResults(1).btstrSumResp(doublePulseIndx(1:end-1),:) * 2;

%-- compute temporal summation ratio based on one pulse conditions
funcRatio       = @(s,d)(mean(s,1)./mean(d,1));  % compute ratio
ratios          = mean(funcRatio(sumDur, sumDurx2));
CIratio         = prctile(funcRatio(sumDur, sumDurx2), [0 100] + (32/2 * [1 -1]), 2);

if showFigure

    clf; 

    %-- data and linear prediction from single pulse data
    for ii = 1:numel(singlePulseIndx)-1
        subplot(1,2,1)
        hold on,
        plot(ii * ones(2,1), ciSumDur(ii,:), 'Color', [0.8 0.8 0.8], 'LineWidth', 3, 'HandleVisibility', 'off')
        plot(ii, meanSumDur(ii), '.k-', 'MarkerSize', 50)
    
        plot(0.04+ii * ones(2,1), ciSumDurx2(ii,:), 'Color', [0.8 0.8 0.8], 'LineWidth', 3, 'HandleVisibility', 'off')
        plot(0.04+ii, meanSumDurx2(ii), '.r-', 'MarkerSize', 50)
    end

    box off; ylabel('Summed response (%SC)')
    set(gca, 'TickDir', 'out', 'xtick', 1:numel(singlePulseIndx)-1, 'XTickLabel', expInfo.stimDur(singlePulseIndx(2:end)), 'FontSize', 16)
    xlabel('Duration single pulse'); xlim([.8 4.2]); 
    legend('Data', 'Linear prediction')
    
    %-- data and linear prediction from double pulse data
    % for ii = 1:numel(singlePulseIndx)-1
    %     subplot(1,3,2)
    %     hold on,
    %     plot(ii * ones(2,1), prctile(sumITI(ii,:), [0 100] + (32/2 * [1 -1])), 'Color', [0.8 0.8 0.8], 'LineWidth', 3, 'HandleVisibility', 'off')
    %     plot(ii, mean(sumITI(ii,:)), '.k-', 'MarkerSize', 50)
    % 
    %     plot(ii * ones(2,1), prctile(sumITIx2(ii,:), [0 100] + (32/2 * [1 -1])), 'Color', [0.8 0.8 0.8], 'LineWidth', 3, 'HandleVisibility', 'off')
    %     plot(ii, mean(sumITIx2(ii,:)), '.r-', 'MarkerSize', 50)
    % end

    %-- temporal summation ratio over all pulse durations
    subplot(1,2,2)
    hold on,
    % plot 68% bootstrapped CI
    plot([1; 1],  CIratio, 'k', 'LineWidth', 2, 'HandleVisibility', 'off')
    plot(1,  ratios, '.k', 'MarkerSize', 50,  'HandleVisibility', 'off')
    set(gca, 'TickDir', 'out', 'xtick', [], 'FontSize', 16)
    ylabel('Summation ratio'); ylim([0.3 1])
    sgtitle('Temporal summation', 'Fontsize', 20)

end

