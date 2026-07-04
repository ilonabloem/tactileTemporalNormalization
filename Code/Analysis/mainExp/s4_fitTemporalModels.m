function s4_fitTemporalModels(model, whichROI, fitAvg, useCluster, recompute, doCross)
%
% Fits a temporal model to BOLD response time courses
%
% model:        model form 'NORM' | 'HRF'. default: 'NORM'
% whichROI:     which ROI to fit the models on. default: S1
% fitAvg:       true or false
% useCluster:   necessary to set correct paths local vs cluster
% recompute:    will not overwrite existing outputs if false. default: false
%
% - Ilona Bloem

%% -- Necessary inputs
projectName   = 'tactileTemporalNormalization';

if ~exist('model', 'var') || isempty(model)
    model       = 'NORM';
end
if ~exist('whichROI', 'var') || isempty(whichROI)
    whichROI    = 'S1';
end
if ~exist('fitAvg', 'var') || isempty(fitAvg)
    fitAvg      = true;
end
if ~exist('useCluster', 'var') || isempty(useCluster)
    useCluster  = false;
end
if ~exist('recompute', 'var') || isempty(recompute)
    recompute   = true;
end
if ~exist('doCross', 'var') || isempty(doCross)
    doCross     = false;
end

% See how many cores we have:
numCores        = maxNumCompThreads;
fprintf('Number of cores %i  \n', numCores);
% Make sure Matlab does not exceed this
maxNumCompThreads(numCores-1);


%% set up params
% Set paths
[~, dataRootDir] = rootPath(useCluster, projectName);

% parameters
expPrms         = expDetailsTemporalTactile(projectName);

loadStr         = 'avgTimeSeries';
resultsstr      = 'modelOutput_fMRI';

savestr         = 'bads'; % 'fmincon' or 'bads' for optimization
if doCross > 0
    crossstr    = 'withCross';
else
    crossstr    = 'noCross';
end

% extract ROI info
indxROI         = ismember(expPrms.allROInames(:,2), whichROI);
assert(sum(indxROI) == 1, sprintf('[%s] Specify a valid ROIname (''S1'', ''BA3b'', ''BA1'' or ''BA2'')', mfilename));
ROIname         = expPrms.allROInames(indxROI,:);

% organize condition order
fixedP.onePulseIndx    = cat(1, find(contains(expPrms.ConditionNames, 'BLANK')), ...
    find(contains(expPrms.ConditionNames, 'ONE')));

fixedP.twoPulseIndx    = find(contains(expPrms.ConditionNames, 'TWO'));
fixedP.ConditionNames  = cat(1, expPrms.ConditionNames(fixedP.onePulseIndx), ...
    expPrms.ConditionNames(fixedP.twoPulseIndx));

fixedP.numConditions   = numel(fixedP.ConditionNames);
fixedP.stimdur         = expPrms.stimdur;
fixedP.twoPulseDur     = expPrms.twoPulseDur;
fixedP.tr              = expPrms.tr;

%-- Current subject
subject         = 'group';

%- Where to save the results
resultsDir      = fullfile(dataRootDir, resultsstr, model);
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

%-- load time series
loadDir         = fullfile(dataRootDir, loadStr);
loadName        = sprintf('sub-%s_%s-%s_%s.mat', subject, ROIname{1,1}, ROIname{1,2}, loadStr);

assert(exist(fullfile(loadDir, loadName), 'file'), sprintf('[%s] %s not found', mfilename, loadName))

results         = load(fullfile(loadDir, loadName));
x_data          = results.x_data; 
fixedP.x_data   = x_data;

%-- results file name
if fitAvg > 0
    saveName        = sprintf('sub-%s_%s-%s_model-%s_crossval-%s_optimizer-%s_%s.mat', subject, ROIname{:,1}, ROIname{:,2}, model, crossstr, savestr, resultsstr);
else
    saveName        = sprintf('sub-%s_%s-%s_model-%s_crossval-%s_optimizer-%s_bts%s.mat', subject, ROIname{:,1}, ROIname{:,2}, model, crossstr, savestr, resultsstr);
end

%-- Check if analysis exists and whether we want to recompute
if ~exist(fullfile(resultsDir, saveName),'file') || recompute

    fprintf('[%s] Computing %s %smodel fits for %s %s %s ROI \n', mfilename, crossstr, model, subject, ROIname{:,1}, ROIname{:,2})

    %-- data to fit
    if fitAvg > 0
        % cond x timepoints
        Data        = mean(results.allBetas,3); % average across participants
    else
        % cond x timepoints x btst_trials
        Data        = results.btsAvgTS;
    end

    %-- for each btst trial
    currModel       = str2func(sprintf('fit%smodel', model));

    fixedParams     = cell(1,5);
    fixedParams{1}  = 'initialize';
    fixedParams{5}  = savestr;
    vals            = currModel([], fixedParams);

    numBtst         = size(Data,3);
    y_data          = NaN(numel(x_data), fixedP.numConditions, numBtst);
    y_est           = NaN(numel(x_data), fixedP.numConditions, numBtst);
    R2              = NaN(1, numBtst);
    params          = NaN(numel(vals.init), numBtst);

    for i_btst = 1:numBtst

        %-- reorganize data into one and two pulse conditions
        tmpData             = Data([fixedP.onePulseIndx; fixedP.twoPulseIndx], :, :);
        tmp_xdata           = x_data;

        %-- timepoint x condition
        tmp_ydata           = tmpData(:,:,i_btst)';

        %-- fit model to all conditions at once
        fixedParams         = cell(1,5);
        fixedParams{1}      = 'initialize';
        fixedParams{5}      = savestr;
        vals                = currModel([], fixedParams);

        switch doCross
            case false

                fixedParams{1}      = 'optimize';
                fixedParams{2}      = tmp_xdata;
                fixedParams{3}      = tmp_ydata;
                fixedParams{4}      = fixedP;

                switch savestr

                    case 'fmincon'
                        [tmpParams, SSE, ~] = ...
                            fmincon(@(x) currModel(x, fixedParams), vals.init,[],[],[],[],vals.lb,vals.ub,[],vals.opts);
                    case 'bads'
                        [tmpParams, SSE, ~] = ...
                            bads(@(x) currModel(x, fixedParams), vals.init, vals.lb, vals.ub, vals.plb, vals.pub, [], []);

                end

                fixedParams{1}      = 'prediction';
                results             = currModel(tmpParams, fixedParams);

                y_data(:, :, i_btst)= results.y_data;
                y_est(:, :, i_btst) = results.y_est;

                params(:, i_btst)   = results.param;
                R2(:, i_btst)       = results.R2;

            case true

                trainP                  = fixedP;
                trainP.numConditions    = fixedP.numConditions-1;
                testP                   = fixedP;
                testP.numConditions     = 1;

                for xfold = 1:fixedP.numConditions

                    %-- define train data
                    keep_idx                = setdiff(1:fixedP.numConditions, xfold);

                    trainP.ConditionNames   = fixedP.ConditionNames(keep_idx);

                    trainParams             = cell(1,5);
                    trainParams{1}          = 'optimize';
                    trainParams{2}          = tmp_xdata;
                    trainParams{3}          = tmp_ydata(:,keep_idx);
                    trainParams{4}          = trainP;
                    trainParams{5}          = savestr;

                    %-- fit the training data
                    switch savestr

                        case 'fmincon'
                            [tmpParams, SSE, ~] = ...
                                fmincon(@(x) currModel(x, trainParams), vals.init,[],[],[],[],vals.lb,vals.ub,[],vals.opts);
                        case 'bads'
                            [tmpParams, SSE, ~] = ...
                                bads(@(x) currModel(x, trainParams), vals.init, vals.lb, vals.ub, vals.plb, vals.pub, [], []);

                    end

                    %-- define test data
                    testP.ConditionNames    = fixedP.ConditionNames(xfold);

                    testParams              = cell(1,5);
                    testParams{1}           = 'prediction';
                    testParams{2}           = tmp_xdata;
                    testParams{3}           = tmp_ydata(:,xfold);
                    testParams{4}           = testP;
                    testParams{5}           = savestr;

                    %-- predict test data
                    results                 = currModel(tmpParams, testParams);

                    y_data(:, xfold, i_btst)= results.y_data;
                    y_est(:, xfold, i_btst) = results.y_est;

                end

                %-- evaluate performance
                tmpR2               = 1 - sum((y_data(:) - y_est(:)).^2, 1) ./ sum((y_data(:) - mean(y_data(:), 1)).^2, 1);
                R2(:, i_btst)       = tmpR2;

        end

    end

    condOrder   = fixedP.ConditionNames;
    ROIname     = sprintf('%s-%s', ROIname{:,1}, ROIname{:,2});

    %-- Save output
    save(fullfile(resultsDir, saveName), 'x_data', 'y_data', 'y_est', ...
        'R2', 'params', 'condOrder', 'model', 'currModel', 'ROIname', 'subject', 'doCross', 'savestr')
    fprintf('[%s] %s %smodel fits saved for %s ROI: %s ... \n', mfilename, crossstr, model, subject, ROIname)

%-- No need to compute model estimates again
else

    fprintf('[%s] %s %smodel results exist for %s %s %s ROI \n', mfilename, crossstr, model, subject, ROIname{roi,1}, ROIname{roi,2})

end


%% Delete parpool
if ~isempty(gcp('nocreate'))
    delete(gcp)
end

end