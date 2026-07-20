function allResults = loadResultsfMRI(projectName, models)

if ~exist('projectName', 'var') || isempty(projectName)
    projectName = 'tactileTemporalNormalization';
end
if ~exist('models', 'var') || isempty(models)
    models      = {'NORM', 'HRF'}; %{'NORM', 'HRF', 'TTC'};
end
%% Set up parameters
%-- Experimental details
savestr         = 'bads';
modelStr        = 'modelOutput_fMRI';

ROInames        = {'localizerROI-S1'};
numROIs         = length(ROInames);

%-- Set up paths
[~, dataRootDir] = rootPath(false, projectName);

%-- Preallocate variables
allResults      = struct('ROI', cell(1,numROIs), ...
    'models', cell(1,numROIs), ...
    'resp', cell(1,numROIs), ...
    'c_resp', cell(1,numROIs), ...
    'sumResp', cell(1,numROIs));

allResults(1).ROI     = ROInames{1};
allResults(1).models  = models;

subject         = 'group';

for wModel = 1:numel(models)

    model           = models{wModel};
    modelSett       = visualizationSettings(models, model);

    %-- Necessary paths
    resultsDir      = fullfile(dataRootDir, modelStr, model);

    %-- Results file names (bootstrapped, avg fits, and cross val R2)
    fileNames       = dir(fullfile(resultsDir, sprintf('sub-%s_%s_model-%s_crossval-*_optimizer-*_*%s.mat', subject, ROInames{1}, model, modelStr)));

    %-- Skip if model output files don't exist
    if length(fileNames) < 1

        fprintf('[%s] No or not all model results found: skipping %s - %s \n', mfilename, subject, ROInames{1})
        continue

    end

    %-- Load results
    clearvars results
    for n = 1:numel(fileNames)
        if contains(fileNames(n).name, 'bts')
            % bootstrap, nocross results
            results(2) = load(fullfile(resultsDir, fileNames(n).name), 'subject', 'model', 'currModel', 'ROIname', 'condOrder', 'x_data', 'y_data', 'y_est', 'params', 'R2');
        elseif contains(fileNames(n).name, 'withCross')
            % fit average, cross results
            results(3) = load(fullfile(resultsDir, fileNames(n).name), 'subject', 'model', 'currModel', 'ROIname', 'condOrder', 'x_data', 'y_data', 'y_est', 'params', 'R2');
        else
            % fit average results
            results(1) = load(fullfile(resultsDir, fileNames(n).name), 'subject', 'model', 'currModel', 'ROIname', 'condOrder', 'x_data', 'y_data', 'y_est', 'params', 'R2');

            if strcmp(func2str(results(1).currModel), 'fitTTCmodel')
                load(fullfile(resultsDir, fileNames(n).name), 'hrfParams');
            end
        end
    end
    
    % combine one-pulse conditions
    onePulseIndx    = cat(1, find(contains(results(1).condOrder, 'BLANK')), ...
        find(contains(results(1).condOrder, 'ONE')));

    % combine two-pulse conditions
    twoPulseIndx    = cat(1, find(contains(results(1).condOrder, 'ONE-PULSE-4')), ...
        find(contains(results(1).condOrder, 'TWO')));

    allPulsesIndx   = cat(1, onePulseIndx, twoPulseIndx);

    % get model prediction
    opt             = [];
    opt.numConditions = modelSett.numCond;
    opt.stimdur     = modelSett.stimDur;

    %-- add hrfparams to TTC params
    if strcmp(func2str(results(1).currModel), 'fitTTCmodel')
        opt.hrfParams = hrfParams;
    end

    out             = createSmoothPrediction(results(1).params, model, false, opt);
    modelPrediction = out.pred; 
    onePulsePred    = modelPrediction(1:numel(out.stimdur), :);
    twoPulsePred    = modelPrediction(numel(out.stimdur)+1:end, :);

    %-- Preallocate variables
    Responses       = NaN(modelSett.numCond, length(results(1).x_data));
    cResponses68    = NaN(modelSett.numCond, length(results(1).x_data), 2);
    cResponses95    = NaN(modelSett.numCond, length(results(1).x_data), 2);
    btstrSumResp    = NaN(modelSett.numCond, size(results(2).y_data,3));

    %-- Extract data for all pulse conditions
    for ii = 1:modelSett.numCond

        % time series data & predictions
        Responses(ii,:)         = results(1).y_data(:,allPulsesIndx(ii));

        if ~isempty(results(2).y_data)
            btstrSumResp(ii,:)      = sum(squeeze(results(2).y_data(:,allPulsesIndx(ii),:)),1);
    
            % confidence interval data based on bootstrapped data
            cResponses95(ii,:,:)    = prctile(squeeze(results(2).y_data(:,allPulsesIndx(ii),:)), [0 100] + (5/2 * [1 -1]), 2);
            cResponses68(ii,:,:)    = prctile(squeeze(results(2).y_data(:,allPulsesIndx(ii),:)), [0 100] + (32/2 * [1 -1]), 2);
        end
    end

    %-- Save responses for all participants [cond tr sub]
    if wModel == 1
        allResults(1).resp        = Responses;
        allResults(1).cResp95     = cResponses95;
        allResults(1).cResp68     = cResponses68;
        allResults(1).sumResp     = sum(Responses,2);
        allResults(1).btstrSumResp = btstrSumResp;
        allResults(1).allPulsesIndx= allPulsesIndx;
        allResults(1).onePulseIndx = onePulseIndx;
        allResults(1).twoPulseIndx = twoPulseIndx;
    end

    %-- Extract model params and CI
    allResults(1).(sprintf('%spred', model))      = cat(1, onePulsePred(ismember(out.stimdur, modelSett.stimDur), :), ...
        twoPulsePred(ismember(out.stimdur, modelSett.stimDur), :));
    allResults(1).(sprintf('sum%spred', model))   = sum(allResults(1).(sprintf('%spred', model)),2);
    allResults(1).(sprintf('%sparams', model))    = results(1).params;

    if ~isempty(results(2).params)
        allResults(1).(sprintf('c%sparams95', model))   = prctile(results(2).params, [0 100] + ((100-95)/2 * [1 -1]), 2);
        allResults(1).(sprintf('c%sparams68', model))   = prctile(results(2).params, [0 100] + ((100-68)/2 * [1 -1]), 2);
    end

    allResults(1).(sprintf('%scrossR2', model))   = results(3).R2;

    allResults(1).(sprintf('mse%s', model))       = mean((Responses - allResults(1).(sprintf('%spred', model))).^2,2);

end

allResults.condNames    = modelSett.condNames;
allResults.x_data       = modelSett.x_data;
allResults.stimDur      = modelSett.stimDur;




