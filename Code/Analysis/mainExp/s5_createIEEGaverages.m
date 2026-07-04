function s5_createIEEGaverages(recompute)
% Summary figure illustrating temporal dynamics in ECoG data
%
% Script uses output from:
% Select electrodes (s4_iEEGlocalizer.m). This creates a channel-selected data file in dataRootDir/data/ECoG
%
% 2025 - Ilona Bloem
%
% Dependencies: ECoG_utils toolbox

if ~exist('recompute', 'var') || isempty(recompute)
    recompute     = false;
end

bounds          = @(x) [floor(min(x(:))*10) ceil(max(x(:))*10)]/10;

%-- Set up paths
dataStr         = 'iEEG';
fileName        = 'selectData';
subjName        = 'sub-group';
subjNames        = {'umcudrouwen','ny726'};

[~, dataRootDir]= rootPath(false);
figRoot         = fullfile(dataRootDir, '..', 'Figures');
figDir          = fullfile(figRoot, dataStr);
if ~exist(fullfile(figDir), 'dir'), mkdir(fullfile(figDir)); end

%-- Find data
fnameList       = dir(fullfile(dataRootDir, dataStr, subjName, sprintf('%s_%s.mat', subjName, fileName)));
assert(~isempty(fnameList), 'ECoG select data file not found, verify paths')

%-- Load results
% Check if electrode average and bootstrapped time series exist
if exist(fullfile(fnameList.folder, fnameList.name), 'file') && recompute == 0

    fprintf('[%s] Group data exists \n', mfilename)

    % compute electrode average and bootstrapped time series
else

    % Structure for loaded data
    BTST_DATA   = [];
    ELEC_DATA   = [];
    numBtst     = 1e3;

    %-- load data for all patients
    for sub = 1:numel(subjNames)

        % Current subject
        subject          = subjNames{sub};

        % Look for channel-selected, epoched data
        fileName         = dir(fullfile(dataRootDir, dataStr, sprintf('sub-%s', subject), sprintf('sub-%s*', subject)));

        % Load the channel-selected, epoched data for the current subject
        fprintf('[%s] Loading channel-selected data of sub-%s \n', mfilename, subject)
        D                = load(fullfile(fileName.folder, fileName.name));

        % see if area labels exist
        if sum(strcmp(D.channels.Properties.VariableNames, 'aparc')) > 0
            ROIs            = unique(D.channels.aparc);
            numROIs         = numel(ROIs);
            chanIdx         = cell(1,numROIs);
            for n = 1:numROIs
                chanIdx{n}  = find(strcmp(D.channels.aparc, ROIs{n}));
            end
            ts_mean         = cell(1, numROIs);

            % average across trials per condition
            for roi = 1:numel(chanIdx)

                stim_names = D.stim_info.name;
                epochs_per_condition = zeros(size(D.epochs,1), numel(stim_names), numel(chanIdx{roi}));

                for ii = 1:length(stim_names)
                    idx_trials = find(strcmp(D.events.trial_name, stim_names{ii}));
                    epochs_per_condition(:,ii,:) = mean(D.epochs(:, idx_trials, chanIdx{roi}),2,'omitnan');
                end

                % bootstrap electrodes from each patient
                chan_idx_btst       = randi(numel(chanIdx{roi}), [numel(chanIdx{roi}), numBtst]);
                ts_btst             = reshape(epochs_per_condition(:,:,chan_idx_btst),[size(epochs_per_condition, 1,2), numel(chanIdx{roi}), numBtst]);
                % average across electrodes for each bootstrap
                ts_mean{roi}        = squeeze(mean(ts_btst,3));

            end

            avgROI          = cellfun(@(x) mean(x,3), ts_mean, 'UniformOutput',false);

            %-- exclude electrodes not in postcentral / supramarginal
            inclElecs       = strcmp(D.channels.aparc, 'postcentral') | strcmp(D.channels.aparc, 'supramarginal');
            D.channels      = D.channels(inclElecs,:);
            D.epochs        = D.epochs(:,:,inclElecs);
            numChan         = height(D.channels);

        else
            numChan         = height(D.channels); % Number of channels from this subject
            avgROI          = {};
            ROIs            = {'Somatosensory'} ;
        end

        % do the same for all electrodes
        stim_names = D.stim_info.name;
        D.epochs_per_condition = zeros(size(D.epochs,1), numel(stim_names), numChan);

        for ii = 1:length(stim_names)
            idx_trials = find(strcmp(D.events.trial_name, stim_names{ii}));
            D.epochs_per_condition(:,ii,:) = mean(D.epochs(:, idx_trials, :),2,'omitnan');
        end

        % bootstrap electrodes from each patient
        chan_idx_btst      = randi(numChan, [numChan, numBtst]);
        D.ts_btst          = reshape(D.epochs_per_condition(:,:,chan_idx_btst),[size(D.epochs_per_condition, 1,2), numChan, numBtst]);
        % average across electrodes for each bootstrap
        D.ts_mean          = squeeze(mean(D.ts_btst,3));
        D.idxChannels_btst = chan_idx_btst;

        % concatenate bootstrap data across participants
        BTST_DATA   = cat(4, D.ts_mean, BTST_DATA);

        % average across bootstraps to get an mean time series
        ELEC_DATA   = cat(3, mean(D.ts_mean,3), ELEC_DATA);
    end

    %-- compute participant average time series
    avgELEC     = mean(ELEC_DATA, 3, 'omitnan'); % time x cond x participant

    %-- compute bootstrap participant average time series
    avgBTST     = mean(BTST_DATA,4,'omitnan'); % time x cond x numbootstr x participant

    fprintf('[%s] Save group data \n', mfilename)
    %-- save data
    stim_info   = D.stim_info;
    stim_ts     = D.stim_ts;
    t           = D.t;
    srate       = D.srate;
    if ~exist(fnameList.folder, 'dir'), mkdir(fnameList.folder), end
    save(fullfile(fnameList.folder, fnameList.name), 'avgELEC', 'avgBTST', 'avgROI', 'ROIs', 'stim_info', 't', 'stim_ts', 'srate')

end
