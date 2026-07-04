function s6_fitIEEGModels(model, fitMode, useCluster, recompute, doCross, numCores, projectName)


%% Necessary inputs
if ~exist('projectName', 'var') || isempty(projectName)
    projectName   = 'tactileTemporalNormalization';
end
if ~exist('model', 'var') || isempty(model)
    %'DN': delayed normalization model
    %'LIN': linear model
    model   = 'DN';
end
if ~exist('fitMode', 'var') || isempty(fitMode)
    % 'average' (averaged electrode per subject), 
    % 'bootstrap' (averaged bootstrapped electrodes across subjects)
    fitMode      = 'average'; 
end
if ~exist('useCluster', 'var') || isempty(useCluster)
    useCluster  = false;
end
if ~exist('recompute', 'var') || isempty(recompute)
    recompute   = false;
end
if ~exist('doCross', 'var') || isempty(doCross)
    doCross     = false;
end
% See how many cores we have:
if ~exist('numCores', 'var') || isempty(numCores)
    numCores        = maxNumCompThreads -1;
end
switch useCluster
    case true

        fprintf('Number of cores %i  \n', numCores);
        % Make sure Matlab does not exceed this
        maxNumCompThreads(numCores);

        hpc_job_number = str2double(getenv('SLURM_ARRAY_TASK_ID'));
        if isnan(hpc_job_number), error('Problem with array assigment'); end
    otherwise 
        maxNumCompThreads(numCores);

end

%% set up params
[~, dataRootDir] = rootPath(false);

% parameters
expPrms         = expDetailsTemporalTactile(projectName);

% 'fmincon' or 'bads' for optimization
savestr         = 'bads';
irfshape        = 'doubleGamma'; % 'singleGamma' or 'doubleGamma'

if doCross > 0
    crossstr = 'withCross';
else
    crossstr = 'noCross';
end

ConditionNames  = expPrms.ConditionNames;
stimdur         = expPrms.stimdur; % in s
twoPulseDur     = expPrms.twoPulseDur; % in s

% save fixed parameters needed for fitting
fixedP.onePulseIndx    = find(contains(ConditionNames, 'ONE'));
fixedP.twoPulseIndx    = find(contains(ConditionNames, 'TWO'));
fixedP.ConditionNames  = cat(1, ConditionNames(fixedP.onePulseIndx), ...
    ConditionNames(fixedP.twoPulseIndx));
fixedP.numConditions   = numel(fixedP.ConditionNames);
fixedP.stimdur         = stimdur;
fixedP.twoPulseDur     = twoPulseDur;

%- Where to save the results
resultsstr      = 'modelOutput_iEEG';
resultsDir      = fullfile(dataRootDir, sprintf('%s', resultsstr), model);
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

% Check if group average and bootstrapped time series exist
if exist(fullfile(dataRootDir, 'iEEG', 'sub-group', 'sub-group_selectData.mat'), 'file')
    
    fprintf('[%s] Loading group data \n', mfilename)
    load(fullfile(dataRootDir, 'iEEG', 'sub-group', 'sub-group_selectData.mat'), 'avgELEC', 'avgBTST', 'avgROI', 'ROIs', 'stim_info', 't', 'stim_ts', 'srate')

% compute electrode average and bootstrapped time series 
else

    error('[%s] sub-group_selectData.mat does not exist on dataRootDir, first run s5_createIEEGaverages.m', mfilename)

end

%% Fit data

% Stimulus information are the same for all subjects
fixedP.x_data    = stim_ts(:, [fixedP.onePulseIndx; fixedP.twoPulseIndx]);
x_data           = stim_ts(:, [fixedP.onePulseIndx; fixedP.twoPulseIndx]);
fixedP.srate     = srate;
fixedP.t         = t;  
len_x_data       = size(fixedP.x_data,1);

% Filenames
if strcmp(fitMode, 'bootstrap')
    saveName        = sprintf('sub-group_model-%s_crossval-%s_optimizer-%s_bst%s.mat', model, crossstr, savestr, resultsstr);
elseif strcmp(fitMode, 'average')
    saveName        = sprintf('sub-group_model-%s_crossval-%s_optimizer-%s_%s.mat', model, crossstr, savestr, resultsstr);
elseif strcmp(fitMode, 'roi')
    whichROI        = 3;
    saveName        = sprintf('sub-group_model-%s_crossval-%s_optimizer-%s_roi-%s_%s.mat', model, crossstr, savestr, ROIs{whichROI}, resultsstr);
end

%-- Check if analysis exists and whether we want to recompute
if ~exist(fullfile(resultsDir, saveName),'file') || recompute

    fprintf('[%s] Computing %s %smodel fits for sub-group \n', mfilename, crossstr, model)

    if strcmp(fitMode, 'average')
        %timepoint x condition x 1
        Data = avgELEC;

    elseif strcmp(fitMode, 'bootstrap')
        % timepoint x condition x numBtst
        Data = avgBTST;

    elseif strcmp(fitMode, 'roi')
        Data = avgROI{whichROI};

    end

    %-- for each btst trial
    currModel       = str2func(sprintf('fit%smodel_IEEG', model));

    fixedParams     = cell(1,6);
    fixedParams{1}  = 'initialize';
    fixedParams{5}  = savestr;
    fixedParams{6}  = irfshape; % Variants of the model
    vals            = currModel([], fixedParams);

    numBtst         = size(Data,3);
    y_data          = NaN(len_x_data, fixedP.numConditions, numBtst);
    y_est           = NaN(len_x_data, fixedP.numConditions, numBtst);
    R2              = NaN(1, numBtst);
    params          = NaN(numel(vals.init), numBtst);

    for i_btst = 1:numBtst

        %-- reorganize data into one and two pulse conditions
        tmp_ydata           = Data(:, [fixedP.onePulseIndx; fixedP.twoPulseIndx], i_btst);
        tmp_xdata           = fixedP.x_data;

        %-- fit model to all conditions at once
        fixedParams         = cell(1,6);
        fixedParams{1}      = 'initialize';
        fixedParams{5}      = savestr; % Fitting toolbox
        fixedParams{6}      = irfshape; % Variants of the model
        vals                = currModel([], fixedParams);

        switch doCross
            case false

                fixedParams{1}      = 'optimize';
                fixedParams{2}      = tmp_xdata;
                fixedParams{3}      = tmp_ydata;
                fixedParams{4}      = fixedP;

                switch savestr

                    case 'fmincon'
                        [tmpParams, ~, ~] = ...
                            fmincon(@(x) currModel(x, fixedParams), vals.init,[],[],[],[],vals.lb,vals.ub,[],vals.opts);
                    case 'bads'
                        [tmpParams, ~, ~] = ...
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
                    fixedParams{6}          = irfshape;

                    %-- fit the training data
                    switch savestr

                        case 'fmincon'
                            [tmpParams, ~, ~] = ...
                                fmincon(@(x) currModel(x, trainParams), vals.init,[],[],[],[],vals.lb,vals.ub,[],vals.opts);
                        case 'bads'
                            [tmpParams, ~, ~] = ...
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
                    testParams{6}           = irfshape;

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

    %-- Save output
    save(fullfile(resultsDir, saveName), 'x_data', 'y_data', 'y_est', ...
        'R2', 'params', 'condOrder', 'model', 'currModel', 'doCross', 'stim_info', 'stim_ts', 't')
    fprintf('[%s] %s %smodel fits saved for sub-group ... \n', mfilename, crossstr, model)
else
    fprintf('[%s] %s %smodel fits for sub-group exist - not rerunning \n', mfilename, crossstr, model)
end
