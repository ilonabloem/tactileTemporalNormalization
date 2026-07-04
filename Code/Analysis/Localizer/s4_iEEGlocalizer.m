clearvars, close all

%-- Setup params
projectName     = 'tactileTemporalNormalization';
dataFolder      = 'ECoGBroadband_exclude110hz_epoched';
dataStr         = 'allelectrodes_epoched.mat'; 
locStr          = 'localizer_epoched.mat';
saveStr         = 'ECoG';
subjNames       = {'ny726', 'umcudrouwen'};
fingerNames     = {'Thumb', 'Index', 'Middle', 'Ring', 'Little'};
numFingers      = numel(fingerNames);
recompute       = 1;

%-- Setup paths
[projectDir, dataRootDir] = rootPath(false, projectName);
dataDir         = fullfile(dataRootDir, '..', 'derivatives', dataFolder);

%-- Current subject
subject         = subjNames{2};
saveDir         = fullfile(dataRootDir, saveStr, sprintf('sub-%s', subject));
if ~exist(saveDir, 'dir'), mkdir(saveDir); end
figureDir       = fullfile(dataRootDir, '..', 'Figures', saveStr, sprintf('sub-%s', subject));
if ~exist(figureDir, 'dir'), mkdir(figureDir); end

%-- Find data
fname           = dir(fullfile(dataDir, sprintf('%s_%s', subject, dataStr)));
epochData       = load(fullfile(dataDir, fname.name));
fname           = dir(fullfile(dataDir, sprintf('%s_%s', subject, locStr)));
if ~isempty(fname)
    skipLocalizer   = true;
    locData         = load(fullfile(dataDir, fname.name));
else
    skipLocalizer   = false;
end

%-- Organize events
totalTrials     = height(epochData.events);
trialLabels     = epochData.events.trial_type; %ascending sweep
numStim         = numel(unique(epochData.events.trial_type));

%-- Select electrodes
stage           = 'selectEpoch';
p               = [];
p.epochTime     = [-0.2 2]; % stim duration 1 s
p.stim_on       = [0 0.4]; % select based on initial peak
p.elec_max_thresh = []; % minimum required maximal response in % signal change for electrode inclusion, if empty, threshold will be determined based on responses across electrodes

p.figureDir     = figureDir;
p.outputDir     = saveDir;
p.IDList        = {subject};
p.doPlots       = false;
selectdata      = ECoG_selectData(epochData, p);

switch subject
    case 'ny726'
        %-- exclude electrodes based on anatomy inside white matter or outside brain 
        exclElecs   = {'W15', 'Z12', 'Z13', 'Z14', 'Z15'};
        indx        = ~ismember(selectdata.channels.name, exclElecs);
        channels    = selectdata.channels(indx,:);
        epochs      = selectdata.epochs(:,:,indx); 
        %-- add area names
        roiMap      = table({'V2'; 'V3'; 'V4'; 'V7'; 'W4'; 'W5'; 'W9'; 'W10'; 'W11'; 'W12'; 'H9'; 'P3'; 'P5'; 'S9'; 'S10'}, ...   % electrode name patterns
                         {'supramarginal'; 'supramarginal'; 'supramarginal'; 'postcentral'; 'supramarginal'; 'postcentral'; 'postcentral'; 'postcentral'; 'postcentral'; 'postcentral'; 'insula';  'postcentral'; 'postcentral'; 'postcentral'; 'postcentral'}, ...
                         {'PFop'; 'PFop'; 'PFop'; 'BA2'; 'PFt'; 'BA2'; 'BA3b'; 'BA3b'; 'BA1'; 'BA1'; 'BA52'; 'BA1'; 'BA3b'; 'BA1'; 'BA3b'}, ...
                         'VariableNames', {'name','aparc', 'glasser'});
        [tf, indx] = ismember(channels.name, roiMap.name);
        channels    = addvars(channels, roiMap.glasser(indx(tf)), 'NewVariableName', 'glasser', 'after', 'name');
        channels    = addvars(channels, roiMap.aparc(indx(tf)), 'NewVariableName', 'aparc', 'after', 'name');
       
        selectdata.channels = channels;
        selectdata.epochs = epochs;
end

fileName        = sprintf('sub-%s_selectData.mat', subject);
save(fullfile(saveDir, fileName), '-struct', 'selectdata');

%{
A_std = regexprep(selectdata.channels.name, '(^[A-Z])0*', '$1');      % 'A01' -> 'A1' etc.
if isempty(A_std)
    % sub-drouwen
    chanIndx            = [19 20 27 28];
    selectdata.channels = epochData.channels(chanIndx,:);
    selectdata.epochs   = epochData.epochs(:,:,chanIndx);
    A_std = selectdata.channels.name;
end

if skipLocalizer == 0
    p.epochTime     = [-0.2 1.2];
    p.stim_on       = [0 1];
    localizerdata   = ECoG_selectData(locData, p);
    B_std = regexprep(localizerdata.channels.name, '(^[A-Z])0*', '$1');  

end

stimnames       = unique(selectdata.events.trial_name);
avgResp         = NaN(size(selectdata.epochs,1), numel(stimnames), size(selectdata.epochs,3));
for ii = 1:numel(stimnames)
    indx        = contains(selectdata.events.trial_name, stimnames{ii}); 
    avgResp(:,ii,:) = mean(selectdata.epochs(:,indx,:), 2, 'omitnan');

end
%-- visualize selected electrodes

for el = 1:height(A_std)
    
    %-- split up figure for visibility
    if ismember(el, 1:7:height(A_std))
        figure('Color', [1 1 1], 'Position', [1 1 1400 450])
        T = tiledlayout(3, 1);
        t1 = tiledlayout(T, 1, 7);
        t1.Layout.Tile = 1;
        t2 = tiledlayout(T, 1, 7);
        t2.Layout.Tile = 2;
        t3 = tiledlayout(T, 1, 7);
        t3.Layout.Tile = 3;
        c = 0;
    
        colororder(parula(7))
    end
    c = c+1;
    elecName    = A_std{el};

    %-- main exp selection
    t_indx = selectdata.t > -0.2 & selectdata.t < 1.8;
    % one pulse
    nexttile(t1)    
    stim_indx = contains(stimnames, 'ONE');
    plot(selectdata.t(t_indx), avgResp(t_indx,stim_indx,el))
    box off
    title(A_std(el))
    if ismember(el, 7:7:height(A_std))
        legend(stimnames(stim_indx))
    end

    % paired pulse
    nexttile(t2)
    stim_indx = contains(stimnames, 'TWO');
    plot(selectdata.t(t_indx), avgResp(t_indx,stim_indx,el))
    box off
    if ismember(el, 7:7:height(A_std))
        legend(stimnames(stim_indx))
    end

    %-- localizer selection
    if skipLocalizer == 0

        if sum(ismember(B_std, elecName)) > 0
            nexttile(t3, tilenum(t3, 1, c))
    
            locStim = unique(localizerdata.events.trial_type);
    
            for stm = 1:numel(locStim)
    
                stimIdx     = localizerdata.events.trial_type == stm;
                hold on
                plot(localizerdata.t, squeeze(mean(localizerdata.epochs(:, stimIdx, ismember(B_std, elecName)),2, 'omitnan')))
    
            end
            box off
        end
        if ismember(el, 7:7:height(A_std)-1)
            legend(fingerNames)
        end
    end

end
%}




