
function results = loadResultsIEEG(projectName, models)

if ~exist('projectName', 'var') || isempty(projectName)
    projectName = 'tactileTemporalNormalization';
end
if ~exist('models', 'var') || isempty(models)
    models      = {'DN', 'LIN'}; %{'DN', 'LIN', 'TTC'};
end

%-- Set up paths
useCluster       = false;
[~, dataRootDir] = rootPath(useCluster, projectName);
figDir          = fullfile(dataRootDir, '..', 'Figures');
if ~exist(fullfile(figDir), 'dir'), mkdir(fullfile(figDir)); end

% Settings
subjNames       = {'sub-group'};
resultsstr      = 'modelOutput_iEEG';

%% Load data and modelfits for each model, with and without cross-validation
results = struct( 'model', cell(numel(models),3), ...
                  'currModel', cell(numel(models),3), ...
                  'condOrder', cell(numel(models),3), ...
                  'x_data', cell(numel(models),3), ...
                  'y_data', cell(numel(models),3), ...
                  'y_est', cell(numel(models),3), ...
                  'params', cell(numel(models),3), ...
                  'R2', cell(numel(models),3), ...
                  'stim_info', cell(numel(models),3), ...
                  'stim_ts', cell(numel(models),3), ...
                  't', cell(numel(models),3));

for mm = 1:numel(models)
    model = models{mm};
    
    %-- model output path
    resultsDir  = fullfile(dataRootDir, sprintf('%s', resultsstr), model);

    %-- Results file names (bootstrapped, avg fits, and cross val R2)
    fileNames       = dir(fullfile(resultsDir, sprintf('%s_model-%s_crossval-*_optimizer-*_*%s.mat', subjNames{1}, model, resultsstr)));

    %-- Skip if not all model output files exist
    if length(fileNames) < 1

        fprintf('[%s] No or not all model results found: skipping %s modelOutput \n', mfilename, subjNames{1})
        continue

    end

    % -- Load results
    for n = 1:numel(fileNames)

        tmp = load(fullfile(resultsDir, fileNames(n).name), 'model', 'currModel', 'condOrder', 'x_data', 'y_data', 'y_est', 'params', 'R2', 'stim_info', 'stim_ts', 't');
        if contains(fileNames(n).name, 'bst')
            % bootstrap, nocross results
            results(mm,2) = tmp;
        elseif contains(fileNames(n).name, 'withCross')
            % fit average, cross results
            results(mm,3) = tmp;
        else
            % fit average results
            results(mm,1) = tmp;
        end
    end

end






