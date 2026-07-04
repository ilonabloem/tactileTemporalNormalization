
% Use BOLD response to a shorter pulses to predict the response to a longer pulse
function data = createLinearSystemPredictions(allResults, figHandle)

if ~exist('figHandle', 'var') || isempty(figHandle)
    showFigure  = false;
else
    showFigure  = true;
end
bounds          = @(x) [floor(min(x(:))*10) ceil(max(x(:))*10)]/10;

% Find duration conditions
singlePulseIndx = find(contains(allResults.condNames, 'ONE'));
singlePulseIndx = singlePulseIndx(allResults.stimDur(:) >= 0.05 & allResults.stimDur(:) <= 0.8);
numPulses       = numel(singlePulseIndx)-1;

padZeros        = 1.5 * 1000;
data            = struct('predictions', cell(1,numPulses), ...
                         'responses', cell(1,numPulses));

% BOLD data
if diff(allResults.x_data(1:2)) == 1
    lineStyle = '.k-';
else
    lineStyle = 'k-';
end

if showFigure > 0 
    figure(figHandle)
    t = tiledlayout(numPulses, numPulses);
end

% loop through all duration conditions
for dur = numPulses:-1:1
    
    % upsample response to ms resolution for BOLD data
    currResp    = allResults.resp(singlePulseIndx(dur),:); 
    currResp    = interp1(allResults.x_data, currResp, allResults.x_data(1):0.001:allResults.x_data(end));

    % duration of current pulse
    currDur     = allResults.stimDur(singlePulseIndx(dur)) * 1000;

    % find how many predictions to create
    whichPulses = sort(singlePulseIndx(singlePulseIndx > singlePulseIndx(dur)), 'desc');

    % preallocate prediction variable
    predictions = zeros(numel(whichPulses), length(allResults.x_data));
    responses   = zeros(numel(whichPulses), length(allResults.x_data));

    % create prediction by time shifting response
    for nPred = 1:numel(whichPulses)

        % create time shifted copies of the response to create the prediction
        msShift     = allResults.stimDur(whichPulses(nPred)) * 1000;
        
        tmpPred     = cat(2, currResp, zeros(1, padZeros));

        % how many shifted copies to create
        for numShifts = 1:(msShift / currDur -1)
            
            tmpPred = tmpPred + cat(2, zeros(1, numShifts * currDur), currResp, zeros(1, padZeros - (numShifts * currDur)));

        end
        
        % remove padding and downsample for BOLD data
        predictions(nPred,:) = interp1(allResults.x_data(1):0.001:allResults.x_data(end), tmpPred(1:length(currResp)), allResults.x_data); 

        % measured response to this duration
        responses(nPred,:)   = allResults.resp(whichPulses(nPred),:); 

        % visualize
        if showFigure > 0
            nexttile(sub2ind([numPulses, numPulses], dur, numPulses-nPred+1))
            plot(allResults.x_data, responses(nPred,:), lineStyle, 'MarkerSize', 15, 'LineWidth', 2), 
            hold on, 
            plot(allResults.x_data, predictions(nPred,:), 'r', 'LineWidth', 2), 
            if nPred == 1
                xlabel(cat(2, num2str(currDur/1000), ' s'))
            end
            if dur == 1
                ylabel(cat(2, num2str(msShift/1000), ' s'), 'Rotation', 0); % num2str(expInfo.stimDur(whichPulses(nPred))))
            end
            box off;
        end
    end

    data(dur).predictions   = predictions;
    data(dur).responses     = responses;

end

if showFigure > 0
    
    ax      = findall(figHandle, 'type', 'axes');
    ybounds = bounds(data(1).predictions);
    
    if ybounds(2) > 6 % ECoG data
        ybounds = [-2 8];
        ylim(ax, ybounds)

        xlim(ax, [-.2 2])
        set(ax, 'tickDir', 'out', 'ytick', linspace(ybounds(1), ceil(ybounds(2)), 6), ...
            'yticklabels', linspace(ybounds(1), ceil(ybounds(2)), 6), 'xtick', 0:1:2)
    else
        ylim(ax, ybounds)

        set(ax, 'tickDir', 'out', 'ytick', floor(ybounds(1)):1:ceil(ybounds(2)))
    end
    xlabel(t,'Prediction from response to:','FontSize',14)
    ylabel(t,'Response to:','FontSize',14)

    l = legend({'Response to single pulse', ['Prediction from shifted' newline 'and summed response']}, 'Location', 'northeast', 'FontSize', 8);
    l.Layout.Tile = sub2ind([numPulses, numPulses], numPulses-1, 1);
end
