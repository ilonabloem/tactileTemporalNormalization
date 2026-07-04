% Create thresholded maps for visualization of finger selective responses

clearvars; close all; clc

% 
addpath(genpath('/Applications/freesurfer'))

%% set up directories
if ~exist('useCluster', 'var') || isempty(useCluster)
    useCluster = false;
end
[projectDir, dataRootDir] = rootPath(useCluster);
analysisDir     = fullfile(dataRootDir, 'phaseEncodedAnal');
roiDir          = fullfile(dataRootDir, 'roiVols');

ROIname         = {'localizerROI', 'S1'};

subjList        = dir(fullfile(analysisDir, 'sub*'));
subjNames       = {subjList.name};
numSubjects     = numel(subjNames);

%% subject loop
for s = 1:numSubjects

    %-- Current subject
    subject         = subjNames{s};
    
    %-- Load localizer coherence
    coherenceFile   = dir(fullfile(analysisDir, subject, 'TSeries', 'volOverlays', 'TSeries_avg',  sprintf('Co_%s_allRuns_wholeBrain.nii.gz', subject)));
    assert(~isempty(coherenceFile), 'Localizer coherence volume not found');
    co              = MRIread(fullfile(coherenceFile(1).folder, coherenceFile(1).name));
    volDims         = co.volsize;
    coVec           = reshape(co.vol, [prod(volDims), 1]);

    %-- Load localizer phase
    phaseFile       = dir(fullfile(analysisDir, subject, 'TSeries', 'volOverlays', 'TSeries_avg',  sprintf('Phase_%s_allRuns_wholeBrain.nii.gz', subject)));
    assert(~isempty(phaseFile), 'Localizer phase volume not found');
    ph              = MRIread(fullfile(phaseFile(1).folder, phaseFile(1).name));
 
    %-- Load ROI to mask data
    maskFile        = dir(fullfile(roiDir, subject, sprintf('*h.%s.VOL.nii.gz', ROIname{1})));
    assert(~isempty(maskFile), 'Localizer volume not found');
    mask            = MRIread(fullfile(maskFile(1).folder, maskFile(1).name));
    maskVec         = reshape(mask.vol, [prod(volDims), 1]);    
    
    %-- Load Glasser atlas for subregions within ROIs
    whichHemi       = maskFile.name(1:2);
    glasserFile     = dir(fullfile(roiDir, subject, sprintf('%s.Glasser2016.VOL.nii.gz', whichHemi)));
    assert(~isempty(glasserFile), 'Glasser atlas volume not found');
    glasser         = MRIread(fullfile(glasserFile(1).folder, glasserFile(1).name));
    glasserVec      = reshape(glasser.vol, [prod(volDims), 1]);
            
    %-- Create S1 index based on Glasser atlas
    glasserIndx         = glasserVec == 51 | ...
                          glasserVec == 52 | ...
                          glasserVec == 9;

    %-- select specific ROI
    ROIindx             = maskVec & glasserIndx;

    %-- select voxels based on localizer coherence within the ROI 
    coTreshold          = prctile(coVec(ROIindx), 70);
    coIndx              = coVec >= coTreshold & ROIindx;
       
    
    %-- Thresholded volumes
    thresIndx               = ~reshape(coIndx, volDims);   
    volThresCo              = co.vol;
    volThresCo(thresIndx)   = NaN;
    volThresPh              = ph.vol;
    volThresPh(thresIndx)   = NaN;
                            
    %-- write thresholded volumes
    outDir                  = fullfile(analysisDir, subject, 'TSeries', 'volOverlays', 'TSeries_avg');
    saveInfo                = co;
    saveInfo.Description    = 'Modified using MATLAB R2020b'; 
    saveInfo.nframes        = 1;
    saveInfo.vol            = volThresCo;
    MRIwrite(saveInfo, fullfile(outDir, ['thresCo_' subject '_allRuns_wholeBrain.nii.gz' ]));
    saveInfo.vol            = volThresPh;
    MRIwrite(saveInfo, fullfile(outDir, ['thresPhase_' subject '_allRuns_wholeBrain.nii.gz' ]));

                
    
end



