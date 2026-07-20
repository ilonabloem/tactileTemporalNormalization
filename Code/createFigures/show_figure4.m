function show_figure4(saveFig, figDir)
%
% Visualizes figure 4 from paper: 
% fMRI temporal dynamics models
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

%-- model params
tau1            = 0.05;
w1              = 0;
sigma           = 0.3;
gain            = 1;
p1              = 4;
p2              = 7;
w               = 0.4;
n               = 2; % fixed to 2
numSec          = 11; % in sec

stimdur         = 0.5;  % in sec
xMax            = stimdur * 2;
x_data          = 0:1:numSec-1; 
samples         = 1000;
dt              = 1/samples; % in s

finer_t         = 0:1:4*samples; % model out to 4s (max duration is 1.6s)
t_length        = numSec * samples;

normSum         = @(x) x./sum(x(:));

%-- Impulse response functions
% set up h1, the impulse response function
h1_t            = x_data(1):dt:2;
h1              = gampdf(h1_t, 2, tau1) - w1.* gampdf(h1_t, 2, tau1*1.5); % assume weight = 0;
h1              = normSum(h1);

% set up hirf, the hemodynamic response function
hrf_t           = x_data(1):dt:100; 
hirf            = gampdf(hrf_t, p1, 1) - (w * gampdf(hrf_t, p2, 1));
hirf            = hirf(1:(numSec*samples)); % make HRF one TR shorter predicted neural response
hirf            = normSum(hirf);

%-- figure 
fig = figure('Color', [1 1 1], 'Position', [30 300 600 290]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[600 290])

figlayout       = tiledlayout(3,1);
HRFlayout       = tiledlayout(figlayout, 1, 5);
HRFlayout.Layout.Tile = 1;
NORMlayout      = tiledlayout(figlayout, 1, 5);
NORMlayout.Layout.Tile = 2;
NORM2layout     = tiledlayout(figlayout, 1, 5);
NORM2layout.Layout.Tile = 3;

%-- Stimulus sequence
stimSeq         = finer_t > 0 & finer_t <= stimdur * samples;

ax              = nexttile(HRFlayout, 1);
plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
box off; axis off
xlim([0 t_length])
xlabel('(s)')

ax              = nexttile(NORMlayout, 1);
plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
box off; axis off
xlim([0 t_length])
xlabel('(s)')

%-- linear prediction
% convolve with irf to create neural prediction
linResp         = conv(stimSeq, h1, 'full');
linResp         = linResp(1:length(finer_t));
numResp         = linResp.^n;

ax              = nexttile(HRFlayout, 2);
hold(ax, 'on'),
plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(ax, finer_t, linResp, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('lin resp', 'FontSize', 14)

ax              = nexttile(NORMlayout, 2);
hold(ax, 'on'),
plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(ax, finer_t, linResp, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('lin resp', 'FontSize', 14)

%-- numerator norm model
ax              = nexttile(NORMlayout, 3);
hold(ax, 'on'),
plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(ax, finer_t, numResp, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('num resp^n', 'FontSize', 14)

%-- denominator norm model
poolResp        = linResp;
denomResp       = sigma.^n + poolResp.^n;

ax              = nexttile(NORM2layout, 3);
hold(ax, 'on'),
plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(ax, finer_t, denomResp, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('sigma^n + denom resp^n', 'FontSize', 14)

%-- norm response norm model
normResp        = numResp ./ denomResp;

ax              = nexttile(NORMlayout, 4);
hold(ax, 'on'),
plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(ax, finer_t, normResp, 'k', 'LineWidth', 2)
xlim([0 xMax*samples])
xlabel('(ms)')
box off; axis off
title('norm resp', 'FontSize', 14)

%-- BOLD prediction
linPred         = conv(linResp, hirf, 'full');
linPred         = linPred(1:t_length);
linPred         = gain * (linPred/max(linPred));

ax              = nexttile(HRFlayout, 3);
hold(ax, 'on'),
plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(ax, 1:t_length, linPred, 'k', 'LineWidth', 2)        
box off; axis off
xlim([0 numSec*samples])
xlabel('(s)')
title('BOLD pred', 'FontSize', 14)

ax              = nexttile(NORMlayout, 5);
hold(ax, 'on'),
normPred        = conv(normResp, hirf, 'full');
normPred        = normPred(1:t_length);
normPred        = gain * (normPred/max(normPred));

plot(ax, finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(ax, 1:t_length, normPred, 'k', 'LineWidth', 2)        
box off; axis off
xlim([0 numSec*samples])
xlabel('(s)')
title('BOLD pred', 'FontSize', 14)


%-- visualize IRF & HIRF
ax              = nexttile(HRFlayout, 4);
hold(ax, 'on'),
plot(h1, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('h1 (tau1)', 'FontSize', 14)

ax              = nexttile(HRFlayout, 5);
hold(ax, 'on'),
plot(ax, hirf, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 numSec*samples])
xlabel('(s)')
title('hirf (p1,p2,w)', 'FontSize', 14)

title(HRFlayout, 'Linear model')
title(NORMlayout, 'Normalization model')

if saveFig > 0
    print(fig, fullfile(figDir, sprintf('fig4_fMRI_temporalModels')), '-dpdf')
end


