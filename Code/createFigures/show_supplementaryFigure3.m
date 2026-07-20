function show_supplementaryFigure3(saveFig, figDir)
% MAKE_SUPPLEMENTARYFIGURE3  Regenerate the three panels of Supplementary
% Figure 3 (two-temporal-channel model overlaid on the tactile data) and
% assemble them into a single labelled figure.
%
%   Panel A : fMRI single-pulse/paired-pulse BOLD time courses   (show_figure5)
%   Panel B : summed BOLD responses vs duration / ISI            (show_figure6)
%   Panel C : iEEG broadband time courses                        (show_figure8)
%
% Writes Figures/SupplementaryFigure3.png (and .pdf). This is the single
% script referenced in the Supplementary Figure 3 legend.

if ~exist('saveFig', 'var') || isempty(saveFig)
    saveFig     = false;
end

if ~exist('figDir', 'var') || isempty(figDir)
    [~, dataRootDir] = rootPath(false);
    figDir      = fullfile(dataRootDir, '..', 'Figures');
end

% regenerate the three panels 
showTTC     = true;
show_figure5(saveFig, figDir, showTTC, 'suppFig3');
show_figure6(saveFig, figDir, showTTC, 'suppFig3b');
show_figure8(saveFig, figDir, showTTC, 'suppFig3c');


