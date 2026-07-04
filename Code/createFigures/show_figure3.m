function show_figure3(saveFig, figDir)
%
% Visualizes figure 3 from paper: 
% sub-additive temporal summation 
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


%-- load data
projectName     = 'tactileTemporalNormalization';
allResults      = loadResultsfMRI(projectName);

%-- create linear system prediction
summationFig    = figure('Color', [1 1 1], 'Position', [30 300 500 500]);
set(summationFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[500 500])

figure(summationFig)
createLinearSystemPredictions(allResults, summationFig);

if saveFig > 0
    print(summationFig, fullfile(figDir, sprintf('fig3_fMRI_linearSystemPred')), '-dpdf')
end
