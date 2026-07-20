function make_supplementaryFigure3()
% MAKE_SUPPLEMENTARYFIGURE3  Regenerate the three panels of Supplementary
% Figure 3 (two-temporal-channel model overlaid on the tactile data) and
% assemble them into a single labelled figure.
%
%   Panel A : fMRI single-pulse/paired-pulse BOLD time courses   (show_fig5_TTC)
%   Panel B : summed BOLD responses vs duration / ISI            (show_fig6_TTC)
%   Panel C : iEEG broadband time courses                        (show_fig8b_TTC)
%
% Writes Figures/SupplementaryFigure3.png (and .pdf). This is the single
% script referenced in the Supplementary Figure 3 legend.

here   = fileparts(mfilename('fullpath'));
addpath(genpath(fileparts(here)));   % add repo Code tree (Models, Functions, ...)
[~, dataRootDir] = rootPath(false, 'tactileTemporalNormalization');
figDir = fullfile(dataRootDir, '..', 'Figures');
if ~exist(figDir,'dir'), mkdir(figDir); end

% 1) regenerate the three panels (each saves a PNG to figDir)
show_fig5_TTC(figDir);
show_fig6_TTC(figDir);
show_fig8b_TTC(figDir);

% 2) assemble panels vertically with A/B/C labels
panels = {'fig5a_fMRI_timeCourses_wTTC.png', ...
          'fig6_fMRI_summed_wTTC.png', ...
          'fig8b_iEEG_timeCourses_wTTC.png'};
labels = {'A','B','C'};

imgs = cell(1,3);
W = 0;
for i = 1:3
    imgs{i} = imread(fullfile(figDir,panels{i}));
    W = max(W, size(imgs{i},2));
end
labW = 60; gap = 30; W = W + labW;

rows = {};
for i = 1:3
    im = imgs{i};
    if size(im,3)==1, im = repmat(im,1,1,3); end
    % pad on the left for the panel label, and on the right to common width
    padL = uint8(255*ones(size(im,1), labW, 3));
    padR = uint8(255*ones(size(im,1), W - size(im,2) - labW, 3));
    row  = [padL, im, padR];
    rows{end+1} = row;                                   %#ok<AGROW>
    if i < 3
        rows{end+1} = uint8(255*ones(gap, W, 3));        %#ok<AGROW>
    end
end
canvas = vertcat(rows{:});

% draw panel letters
canvas = insertLabels(canvas, imgs, labels, labW, gap);

imwrite(canvas, fullfile(figDir,'SupplementaryFigure3.png'));
fprintf('[make_supplementaryFigure3] wrote %s\n', fullfile(figDir,'SupplementaryFigure3.png'));

% also save a PDF version
f = figure('Visible','off','Color','w','Units','pixels', ...
           'Position',[0 0 size(canvas,2) size(canvas,1)]);
ax = axes('Parent',f,'Position',[0 0 1 1]); image(ax,canvas); axis(ax,'off','image');
set(f,'PaperUnits','points','PaperPosition',[0 0 size(canvas,2) size(canvas,1)], ...
      'PaperSize',[size(canvas,2) size(canvas,1)]);
print(f, fullfile(figDir,'SupplementaryFigure3.pdf'),'-dpdf','-vector');
close(f);
fprintf('[make_supplementaryFigure3] wrote %s\n', fullfile(figDir,'SupplementaryFigure3.pdf'));
end

function canvas = insertLabels(canvas, imgs, labels, labW, gap)
% place bold panel letters at the top-left of each panel band
y = 1;
for i = 1:numel(imgs)
    h = size(imgs{i},1);
    try
        canvas = insertText(canvas,[5 y+4],labels{i}, ...
            'FontSize',34,'BoxOpacity',0,'TextColor','black');
    catch
        % insertText requires Computer Vision Toolbox; fall back silently
    end
    y = y + h + gap;
end
end
