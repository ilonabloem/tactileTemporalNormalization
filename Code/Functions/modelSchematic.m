function modelSchematic(modality, figDir, saveFig)
% -- Visualize normalization model components
% modality:  'fMRI' or 'iEEG', default is 'fMRI'
% figDir: if no directory is provided it will save in dataroot/../Figures/modelSchematic

if ~exist('modality', 'var') || isempty(modality)
    modality        = 'fMRI';
end
if ~exist('figDir', 'var') || isempty(figDir)
    [~, dataRootDir] = rootPath(false);
    figDir           = fullfile(dataRootDir, '..', 'Figures');
end
if ~exist('saveFig', 'var') || isempty(saveFig)
    saveFig        = false;
end

if ~exist(figDir, 'dir'), mkdir(figDir); end

%-- model settings
switch modality
    case {'fMRI', 'fmri'}
        saveStr     = 'modelSchematic_fMRI';

        % Model parameters
        tau1        = 0.05;
        w1          = 0;
        sigma       = 0.3;
        gain        = 1;
        p1          = 4;
        p2          = 7;
        w           = 0.4;
        n           = 2; % fixed to 2
        numSec      = 11; % in sec
    case 'iEEG'
        saveStr     = 'modelSchematic_iEEG';

        % Model parameters
        tau1        = 0.05;
        w1          = 0.6;
        tau2        = 0.1; 
        sigma       = 0.3;
        gain        = 1;
        n           = 2; % fixed to 2
        numSec      = 4; % in sec   
end

stimdur         = 0.5;  % in sec
xMax            = stimdur * 2;
x_data          = 0:1:numSec-1; 
samples         = 1000;
dt              = 1/samples; % in s

finer_t         = 0:1:4*samples; % model out to 4s (max duration is 1.6s)
t_length        = numSec * samples;

normSum         = @(x) x./sum(x(:));

%% 
fig = figure('Color', [1 1 1], 'Position', [30 300 600 170]);
set(fig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[600 180])

%Stimulus sequence
stimSeq         = finer_t > 0 & finer_t <= stimdur * samples;

subplot(2,6,1)
plot(finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('Stimulus', 'FontSize', 14)

% set up h1, the impulse response function
h1_t            = x_data(1):dt:2;
h1              = gampdf(h1_t, 2, tau1) - w1.* gampdf(h1_t, 2, tau1*1.5); % assume weight = 0;
h1              = normSum(h1);

subplot(2,6,6)
plot(h1, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
switch saveStr
    case 'modelSchematic_fMRI'
        title('h1 (tau1)', 'FontSize', 14)
    otherwise
         title('h1 (tau1, w)', 'FontSize', 14)
end

% convolve with irf to create neural prediction
linResp         = conv(stimSeq, h1, 'full');
linResp         = linResp(1:length(finer_t));
numResp         = linResp.^n;

subplot(2,6,2)
hold on,
plot(finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(finer_t, linResp, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('lin resp', 'FontSize', 14)

subplot(2,6,3)
hold on,
plot(finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(finer_t, numResp, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('num resp^n', 'FontSize', 14)

% normalization denominator
switch saveStr
    case 'modelSchematic_fMRI'
        poolResp    = linResp;
        denomResp   = sigma.^n + poolResp.^n;
    case 'modelSchematic_iEEG'
        % set up h2, low pass filter for linear response
        h2          = exp(-h1_t/tau2);
        h2          = normSum(h2);

        % normalization denominator
        poolResp    = conv(linResp, h2, 'full');
        poolResp    = poolResp(1:length(finer_t));
        denomResp   = sigma.^n + abs(poolResp).^n;

        subplot(2,6,12)
        plot(h2, 'k', 'LineWidth', 2)
        box off; axis off
        xlim([0 xMax*samples])
        xlabel('(ms)')
        title('h2 (tau2)', 'FontSize', 14)
end

subplot(2,6,9)
hold on,
plot(finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(finer_t, denomResp, 'k', 'LineWidth', 2)
box off; axis off
xlim([0 xMax*samples])
xlabel('(ms)')
title('sigma^n + denom resp^n', 'FontSize', 14)

%-- normalization response
normResp        = numResp ./ denomResp;

if contains(saveStr, 'ECoG')
    normResp    = gain* normResp./max(normResp);
end

subplot(2,6,4)
hold on,
plot(finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
plot(finer_t, normResp, 'k', 'LineWidth', 2)
xlim([0 xMax*samples])
xlabel('(ms)')
box off; axis off
title('norm resp', 'FontSize', 14)

% BOLD HIRF
switch saveStr
    case 'modelSchematic_fMRI'
        hrf_t           = x_data(1):dt:100; 
        hirf            = gampdf(hrf_t, p1, 1) - (w * gampdf(hrf_t, p2, 1));
        hirf            = hirf(1:(numSec*samples)); % make HRF one TR shorter predicted neural response
        hirf            = normSum(hirf);
        
        subplot(2,6,12)
        plot(hirf, 'k', 'LineWidth', 2)
        box off; axis off
        xlim([0 numSec*samples])
        xlabel('(s)')
        title('hirf (p1,p2,w)', 'FontSize', 14)
        
        %-- convolve with a HIRF to create BOLD prediction
        boldPred        = conv(normResp, hirf, 'full');
        boldPred        = boldPred(1:t_length);
        boldPred        = gain * (boldPred/max(boldPred));
        
        subplot(2,6,5)
        hold on,
        plot(finer_t, stimSeq, 'Color', 0.5*ones(1,3), 'LineWidth', 2)
        plot(1:t_length, boldPred, 'k', 'LineWidth', 2)        
        box off; axis off
        xlim([0 numSec*samples])
        xlabel('(s)')
        title('BOLD pred', 'FontSize', 14)
        
    otherwise

        sgtitle(saveStr, 'interpreter', 'none')
        if saveFig > 0
            print(gcf, fullfile(figDir, sprintf('fig8a_iEEG_temporalModels')), '-dpdf')
        end

end



