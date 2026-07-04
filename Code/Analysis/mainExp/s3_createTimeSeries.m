
function s3_createTimeSeries(projectName, whichROI, numBoots, plotIndvFigures, recompute)
% Create bootstrapped group average BOLD response time courses
%
% whichROI:         define ROI to create average for. default: S1
% numBoots:         number of bootstrap samples. default: 500
% plotIndvFigures:  visualize individual timeseries. default: false
% recompute:        will recompute outputs if true. default: false
%
% 2024 - Ilona Bloem

clearvars; close all

%% -- Necessary inputs
if ~exist('projectName', 'var') || isempty(projectName)
    projectName   = 'tactileTemporalNormalization';
end
if ~exist('whichROI', 'var') || isempty(whichROI)
    whichROI    = 'S1';
end
if ~exist('numBoots', 'var') || isempty(numBoots)
    numBoots    = 500;
end
if ~exist('plotIndvFigures', 'var') || isempty(plotIndvFigures)
    plotIndvFigures   = false;
end
if ~exist('recompute', 'var') || isempty(recompute)
    recompute   = false;
end

%% Setup paths & params
[~, dataRootDir] = rootPath(false, projectName);

figDir          = fullfile(fileparts(dataRootDir), 'Figures', 'FIRtimeSeries');
if ~exist(figDir, 'dir'), mkdir(figDir); end

%-- define necessary variables
expPrms         = expDetailsTemporalTactile(projectName);

taskNames       = expPrms.taskNames;
hrfmodel        = 'fir'; % 'optimize' or 'fir'
glmFolder       = 'corticalRibbon';
glmDir          = fullfile(dataRootDir, 'GLMdenoise', glmFolder);
savestr         = 'avgTimeSeries';
saveDir         = fullfile(dataRootDir, savestr);

stimdur         = [0 0.05 0.1 0.2 0.4 0.8 1.2]; % seconds
twoPulseDur     = 0.2; % pulse duration in two-pulse condition, in seconds
numPulses       = numel(stimdur);
tr              = 1;

ConditionNames  = expPrms.ConditionNames;
condOrder       = cat(1, find(contains(ConditionNames, 'BLANK')), ...
    find(contains(ConditionNames, 'ONE')), ...
    find(contains(ConditionNames, 'ONE-PULSE-4')), ...
    find(contains(ConditionNames, 'TWO')));

numConditions   = numel(ConditionNames); %sum(contains(ConditionNames, 'PULSE'));
coThres         = 25; % select top 25% of voxels in ROI based on coherence values 
bounds          = @(x) [floor(min(x(:))*10) ceil(max(x(:))*10)]/10;

%-- define ROIs
Glasserlabels   = { 'S1', [9 51 52]
                    'BA3b', 9; ...
                    'BA1', 51; ...
                    'BA2', 52; ...
                    };

allROInames     = { 'localizerROI', 'S1';
                    'localizerROI', 'BA3b';
                    'localizerROI', 'BA1';
                    'localizerROI', 'BA2';
                    };

indxROI         = ismember(Glasserlabels(:,1), whichROI);
assert(sum(indxROI) == 1, sprintf('[%s] Specify a valid ROIname (''S1'', ''BA3b'', ''BA1'' or ''BA2'')', mfilename));
ROIname         = allROInames(indxROI,:);

%-- define participants
fnameList       = fullfile(dataRootDir, '..', sprintf('participants.tsv'));
T               = readtable(fnameList, 'FileType', 'delimitedtext', 'Delimiter', '\t');
numSubjects     = numel(T.participant_id);
subjNames       = T.participant_id;


%-- check if output file exists
saveName        = sprintf('sub-group_%s-%s_%s.mat', ROIname{1,1}, ROIname{1,2}, savestr);

if exist(fullfile(saveDir, saveName), 'file') > 0 && recompute < 1
    
    fprintf('[%s] loading %s for visualization', mfilename, saveName)
    load(fullfile(saveDir, saveName), 'btsAvgTS', 'ConditionNames');

else

    fprintf('[%s] computing bootstrapped timeseries for visualization', mfilename)
    if ~exist(saveDir, 'dir'); mkdir(saveDir); end

    %-- preallocate variables
    allBetas        = NaN(numConditions, 11, numSubjects);

    %-- load data from all participants
    for sub = 1:numSubjects
    
        %-- Current subject
        currSub         = subjNames{sub};
    
        %-- load deconvolution GLMdenoise results
        dataFile        = dir(fullfile(glmDir, currSub, hrfmodel, sprintf('results_%s_task-%s.mat', currSub, taskNames{1})));
        assert(~isempty(dataFile), 'GLM results file not found')
    
        GLMresults      = load(fullfile(dataFile(1).folder, dataFile(1).name));
    
        GLMfield        = fieldnames(GLMresults);
        volDims         = GLMresults.(GLMfield{1}).volDims;
        lastTR          = size(GLMresults.(GLMfield{1}).modelmd,3);
        x_data          = linspace(0,lastTR-1,lastTR);
    
        %-- Create index based on Glasser atlas
        tmpROIname      = split(ROIname(1,2), '-');
        whichLabels     = strcmp(Glasserlabels(:,1), tmpROIname{1});
        glasserMask     = ismember(GLMresults.(GLMfield{1}).ROIlabels, Glasserlabels{whichLabels, 2});
    
        %-- load ROI to mask data
        maskFile        = dir(fullfile(dataRootDir, 'roiVols', currSub, sprintf('*h.%s.VOL.nii.gz', ROIname{1,1})));
        assert(~isempty(maskFile), 'Localizer volume not found');
        mask            = MRIread(fullfile(maskFile(1).folder, maskFile(1).name));
        maskVec         = reshape(mask.vol, [prod(volDims), 1]);
        roiMask         = maskVec(GLMresults.(GLMfield{1}).brainIndx);
    
        %-- select specific ROI
        ROIindx         = roiMask > 0 & glasserMask;
    
        %-- select the top xx voxels based on localizer coherence within the ROI
        coThreshold     = prctile(GLMresults.results.locCoherence(ROIindx), 100-coThres);
        selectedVoxels  = ROIindx & GLMresults.results.locCoherence >= coThreshold;
    
        assert(sum(selectedVoxels) > 1, sprintf('No voxels that matched criteria for %s %s ROI', currSub, ROIname{1,2}))
        
        %-- average across selected voxels
        % cond x timepoints
        betas            = squeeze(mean(double(GLMresults.(GLMfield{1}).modelmd(selectedVoxels,:,1:lastTR)),1));
    
        allBetas(:,:,sub) = betas;
    
        %-- save out some stats about voxel selection
        fname           = sprintf('%s_roi-%s_GLM-%s_voxelStats.json', currSub, ROIname{1,2}, glmFolder);
        inputVar        = struct('scriptName', mfilename, 'subId', currSub, ...
                            'roiName', ROIname(1,2), 'glasserLabels', Glasserlabels(whichLabels, 2), ...
                            'nVoxlocROI', sum(roiMask), 'glasserLabelslocROI', unique(GLMresults.(GLMfield{1}).ROIlabels(roiMask>0)), ...
                            'nVoxlocROIbyGlasserLabel', histc(GLMresults.(GLMfield{1}).ROIlabels(roiMask > 0), unique(GLMresults.(GLMfield{1}).ROIlabels(roiMask>0))), ...
                            'nVoxGlasser', sum(ROIindx), 'nVoxthresCo', sum(selectedVoxels), ...
                            'coThreshold', coThreshold, ...
                            'nVoxthresCobyGlasserLabel', histc(GLMresults.(GLMfield{1}).ROIlabels(selectedVoxels > 0), unique(GLMresults.(GLMfield{1}).ROIlabels(selectedVoxels>0))));        
        savejson('',inputVar,fullfile(dataFile.folder,fname));
    
        %-- save results
        subName        = sprintf('sub-%s_%s-%s_%s.mat', currSub, ROIname{1,1}, ROIname{1,2}, savestr);
        save(fullfile(saveDir, subName), 'betas', 'ConditionNames', 'x_data');
    
        %-- Plot avg FIR  
        if plotIndvFigures > 0
            
            ybounds     = bounds(betas);
    
            figHandle       = figure('Color', [1 1 1], 'Position', [30+sub*10 300 1400 800]);
            set(figHandle,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[1400 800])
        
            for cond = 1:numel(condOrder)
          
                figure(figHandle)
                subplot(2, 7, cond);
                hold on;  
                plot(x_data, betas(condOrder(cond), :), '.-', 'Color', [.5 .5 .5], 'LineWidth', 2, 'MarkerSize', 20);
                box off;
                ylim(ybounds);
                title(ConditionNames{condOrder(cond)}, 'Interpreter','none');
        
            end
            figure(figHandle)
            sgtitle(sprintf('%s: %s FIR time series, nVoxel: %i', currSub, ROIname{1, 2}, sum(selectedVoxels)), 'fontsize', 16);
            
            subjFigDir = fullfile(figDir, currSub);
            if ~exist(subjFigDir, 'dir'), mkdir(subjFigDir); end
            print(figHandle, fullfile(subjFigDir, sprintf('FIRtimeseries_%s_%s', currSub, ROIname{1,2})), '-dpdf')
    
        end
    
    end
    
    %% bootstrap average time series across participants
    
    %-- define seed for reproducibility
    seed        = rng('shuffle', 'twister'); % random seed based on current time
    rng(seed);
    
    %-- bootstrap independently for each condition
    btsAvgTS    = NaN(numConditions, numel(x_data), numBoots);
    for cond = 1:numConditions
        
        % bootstrap over first dimension (participants)
        data                = squeeze(allBetas(cond,:,:))'; 
        btsAvgTS(cond,:,:)  = bootstrp(numBoots, @mean, data)';
    
    end

    %-- save results
    save(fullfile(saveDir, saveName), 'btsAvgTS', 'allBetas', 'ConditionNames', 'x_data', 'seed');

end

%% visualize group results
CItimeseries    = NaN(numConditions, numel(x_data), 2);
ybounds         = bounds(btsAvgTS) - [-0.1 0.1];

figHandle       = figure('Color', [1 1 1], 'Position', [30+sub*10 300 1400 800]);
set(figHandle,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[1400 800])
        
for cond = 1:numel(condOrder)

    %-- 90% confidence interval data based on bootstrapped data
    CItimeseries(cond,:,:)      = prctile(squeeze(btsAvgTS(condOrder(cond),:,:)), [5 95], 2);

    figure(figHandle)
    subplot(2, 7, cond);
    hold on;  
    hCI = fill([x_data, fliplr(x_data)], [squeeze(CItimeseries(cond,:,1)), fliplr(squeeze(CItimeseries(cond,:,2)))], 'k', 'HandleVisibility', 'off');
    hCI.FaceAlpha = 0.2; hCI.EdgeColor = [1 1 1];
    plot(x_data, mean(allBetas(condOrder(cond), :, :),3), '.-', 'Color', [.5 .5 .5], 'LineWidth', 2, 'MarkerSize', 20);
    box off;
    set(gca, 'TickDir', 'out', 'ytick', ybounds(1):0.4:ybounds(2))
    ylim(ybounds);
     if cond <= numel(stimdur)
        title(sprintf('Dur %.2fs', stimdur(cond)), 'FontSize', 12)
    else
        title(sprintf('ISI %.2fs', stimdur(cond-numel(stimdur))), 'FontSize', 12)
     end

end
figure(figHandle)
sgtitle(sprintf('%s group average time courses (bootstrapped 90%s CI)', ROIname{1, 2}, '%'), 'fontsize', 16);

subjFigDir = fullfile(figDir, 'groupAverage');
if ~exist(subjFigDir, 'dir'), mkdir(subjFigDir); end
print(figHandle, fullfile(subjFigDir, sprintf('FIRtimeseries_%s_%s', 'groupAverage', ROIname{1,2})), '-dpdf')



