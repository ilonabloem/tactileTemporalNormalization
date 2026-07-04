
function s2_runGLMdenoise(useCluster, recompute, projectName)
% Run FIR model using GLMdenoise
%
% useCluster:       whether the job runs on the NYU cluster. default: false
% projectName:      main project folder name. default: 'tactileTemporalNormalization'
% recompute:        will recompute outputs if true. default: false
%
% - Ilona Bloem

%-- verify inputs
if ~exist('useCluster', 'var') || isempty(useCluster)
    useCluster  = false;
end
if ~exist('recompute', 'var') || isempty(recompute)
    recompute  = true;
end
if  ~exist('projectName', 'var') || isempty(projectName)
    projectName  = 'tactileTemporalNormalization';
end

%-- Setup paths
[~, dataRootDir] = rootPath(useCluster, projectName);

switch useCluster
    case true

        % See how many cores we have:
        if ~exist('numCores', 'var') || isempty(numCores)
            numCores        = maxNumCompThreads;
        end
        fprintf('Number of cores %i  \n', numCores);
        % Make sure Matlab does not exceed this
        maxNumCompThreads(numCores);

        hpc_job_number = str2double(getenv('SLURM_ARRAY_TASK_ID'));
        if isnan(hpc_job_number), error('Problem with array assigment'); end

end

expPrms         = expDetailsTemporalTactile(projectName);

saveStr         = 'corticalRibbon';

taskNames       = expPrms.taskNames;
session         = [];
runnums         = [];
dataFolder      = 'fmriprep';
dataStr         = 'T1w_desc-preproc_bold.nii.gz';
stimdur         = 0.2; % seconds
glmOptsPath     = [];
tr              = 1;
hrfmodel        = 'fir'; %'fir' or 'optimize'

switch hrfmodel
    case 'fir'
        hrfknobs        = 10; % number of time points in the future to estimate FIR
        opt             = [];
        opt.wantsanityfigures = 1;
        x_data          = 0:1:hrfknobs;
    case 'optimize'
        opt             = [];
        opt.hrffitmask  = [];
        opt.hrfthresh   = 5; % If R^2 between the estimated HRF and the initial HRF is less than <hrfthresh>, use the initial HRF.
        hrfknobs        = spmhrf(0:tr:20)';
        opt.denoisespec = '10101'; % denoised output will not contain contribution of polynomial drift and noise regressors

end

%-- find all participants
fnameList       = fullfile(dataRootDir, sprintf('participants.tsv'));
T               = readtable(fnameList, 'FileType', 'delimitedtext', 'Delimiter', '\t');
subjNames       = T.participant_id;
numSubjects     = numel(subjNames);

if useCluster; sub_slc = hpc_job_number; else; sub_slc = 1:numSubjects; end

%%
for sub = sub_slc

    %-- Current subject
    subject         = subjNames{sub};

    %% Setup directories
    designDir       = fullfile(dataRootDir, 'designMatrices', sprintf('%s', subject));

    if exist(designDir, 'dir') > 0

        outDir          = fullfile(dataRootDir, 'GLMdenoise', saveStr, ...
            sprintf('%s', subject), hrfmodel);
        saveDir         = fullfile(outDir, 'volOutputs');
        figureDir       = fullfile (dataRootDir, 'GLMdenoise', 'Figures', projectName, saveStr, ...
            sprintf('%s', subject), hrfmodel);

        dataSaveDir     = fullfile(dataRootDir, 'timeSeries', ...
            sprintf('%s',subject));


        if ~exist(figureDir, 'dir'); mkdir(figureDir); end
        if ~exist(saveDir, 'dir'); mkdir(saveDir); end
        if ~exist(dataSaveDir, 'dir'); mkdir(dataSaveDir); end

    else
        fprintf('[%s] No design matrices found for %s, skipping analysis ... \n', mfilename, subject)
        continue
    end

    %% Check if GLMdenoise output exists && whether we want to recompute
    resultsFileName = sprintf('results_%s_task-%s.mat', subject, taskNames{1});

    if ~exist(fullfile(outDir, resultsFileName), 'file') || recompute

        %--
        fprintf('[%s] Running analysis for %s ... \n', mfilename, subject)

        dataDir         = fullfile(dataRootDir, '..', 'derivatives', dataFolder, sprintf('%s',subject));


        % -- Find sessions
        sessList        = dir(fullfile(designDir, 'ses*'));
        numSess         = numel(sessList);

        data            = cell(1,numSess);
        info            = cell(1,numSess);
        runnums         = cell(1,numSess);
        design          = cell(1,numSess);

        for ses = 1:numSess

            sessDir         = fullfile(designDir, sessList(ses).name);

            %-- Only load data if this session contains any scans for the current task
            taskFiles       = dir(fullfile(sessDir, sprintf('*design.tsv')));

            if ~isempty(taskFiles)

                %-- Load design matrices
%                 [session, tasks, runnums] = bidsSpecifyEPIs(dataDir, subject, ...
%                     sprintf('ses-nyu3t%02d', ses), taskNames(1));

                tsvFiles        = dir(fullfile(sessDir, sprintf('%s_%s_%s*_design.tsv', projectName, subject, sessList(ses).name)));
                design{ses}     = cell(1,numel(tsvFiles));
                runnums{ses}    = 1:numel(tsvFiles);

                for ii = 1:numel(runnums{ses})

                    dMatrix             = load(fullfile(sessDir, sprintf('%s_%s_%s_run-%02d_design.tsv', projectName, subject, sessList(ses).name, ii)));
                    design{ses}{ii}     = dMatrix;

                end

                totalTR     = size(design{ses}{1},1);

                %-- Load data
                fprintf('[%s] Loading data %s session %s ...\n', mfilename, subject, sessList(ses).name);

                dataSaveName    = sprintf('%s_%s_%s_timeSeries.mat', projectName, subject, sessList(ses).name);
                if ~exist(fullfile(dataSaveDir, dataSaveName), 'file')

                    for jj = 1:length(runnums{ses})
                        fprintf('.')

                        % we want to check for both 0-padded and non-0-padded versions...
                        fnamePrefix         = sprintf('*_task-%s*run-%d_*%s*',...
                            taskNames{1},runnums{ses}(jj), dataStr);
                        fnamePrefixZeroPad  = sprintf('*_task-%s*run-%02d_*%s*',...
                            taskNames{1},runnums{ses}(jj), dataStr);

                        fname = dir(fullfile(dataDir, sessList(ses).name, 'func', fnamePrefix));
                        % we only need to check both if they're different; if we're
                        % looking at run 10, 0-padded and non-0-padded will be the
                        % same string
                        if ~strcmp(fnamePrefix, fnamePrefixZeroPad)
                            fname = [fname; dir(fullfile(dataDir, sessList(ses).name, 'func', fnamePrefixZeroPad))];
                        end

                        assert(length(fname) == 1);

                        fullDatafile  = MRIread(fullfile(fname.folder, fname.name));
                        data{ses}{jj}      = single(fullDatafile.vol); % MRIread reorders dims
                        info{ses}{jj}      = fullDatafile;
                        info{ses}{jj}      = rmfield(info{ses}{jj}, 'vol');
                        %{
                        fullDatafile  = niftiread(fullfile(dataDir, fname.name));
                        data{jj}      = single(fullDatafile);
                        info{jj}      = niftiinfo(fullfile (dataDir, fname.name));
                        %}
                    end

                    % If number of runs doesn't match, find the run that ended early
                    if numel(runnums{ses}) < numel(data{ses})

                        numFrames = NaN(1,numel(data));
                        for ii = 1:numel(data)
                            dims            = size(data{ii});
                            numFrames(ii)   = dims(4);
                        end

                        tmpdata     = data(numFrames == totalTR);
                        data{ses}   = tmpdata;

                    end

                    sesData     = data{ses};
                    save(fullfile(dataSaveDir, dataSaveName), 'sesData' , '-v7.3');
                else
                    tmp = load(fullfile(dataSaveDir, dataSaveName), 'sesData');
                    data{ses} = tmp.sesData;
                end

            end

        end

        %-- Combine data and design over all sessions
        allData     = cat(2, data{:});
        allDesign   = cat(2, design{:});

        %-- Save input arguments
        fname       = sprintf('%s_%s_HRFmodel-%s_inputVar.json', ...
            projectName, subject, hrfmodel);

        inputVar    = struct('dataDir', dataRootDir, 'outDir', outDir, 'subject', subject, ...
            'numSessions', numel(data), 'tasks', taskNames(1), 'runnums', numel(allData), 'hrfmodel', hrfmodel, ...
            'dataFolder', dataFolder, 'dataStr', dataStr, 'stimdur', stimdur, 'glmOptsPath', glmOptsPath, 'tr', tr, ...
            'hrfknobs', hrfknobs);

        savejson('',inputVar,fullfile(outDir,fname));

        if isempty(allData)
            fprintf('No data found for %s - skipping for now \n', subject)
            continue;
        end

        %-- Reshape volume to a vector
        allData   = cellfun(@(x) reshape(x, [prod(size(x,1,2,3)) size(x,4)]), allData, 'UniformOutput', false);

        %-- Load Glasser atlas to constrain fitting to cortical ribbon
        % Setup path to atlas
        annotDIR    = fullfile(dataRootDir, 'roiVols', subject);
        % load left and right hemi atlas
        lh          = MRIread(fullfile(annotDIR, sprintf('lh.%s.VOL.nii.gz', 'Glasser2016')));
        rh          = MRIread(fullfile(annotDIR, sprintf('rh.%s.VOL.nii.gz', 'Glasser2016')));

        % Combine hemis
        combVol     = lh.vol + rh.vol;
        volDims     = size(combVol);

        % Create binary mask
        ROIlabels   = reshape(combVol, [prod(volDims) 1]);
        brainMask   = ROIlabels > 0;

        %-- Load localizer coherence
        coherenceFile   = dir(fullfile(dataRootDir, 'phaseEncodedAnal', subject, 'TSeries', 'volOverlays', 'TSeries_avg',  sprintf('Co_%s_allRuns_wholeBrain.nii.gz', subject)));
        assert(~isempty(coherenceFile), 'Localizer coherence volume not found');
        co              = MRIread(fullfile(coherenceFile(1).folder, coherenceFile(1).name));
        coVec           = reshape(co.vol, [prod(volDims), 1]);
        selCo           = coVec(brainMask);

        % When running GLM use whole brain to estimate noise regressors,
        % but provide a mask for HRF optimization
        if strcmp(hrfmodel, 'optimize') && isfield(opt, 'hrffitmask')

            % Use primary and secondary somatosensory cortex for HRF fitting
            % 9 = BA1; 51 = BA2; 52 = BA3b; 100-102 = OP1-4
            combIndx    = combVol == 9 | combVol == 51 | combVol == 52;
            combIndx    = reshape(combIndx, [prod(volDims) 1]);

            opt.hrffitmask = combIndx(brainMask);

            % when running FIR restrict voxels to cortical ribbon
            elseif strcmp(hrfmodel, 'fir')

            % Constrain voxels to cortical ribbon
            ROIlabels   = ROIlabels(brainMask);
            allData     = cellfun(@(x) x(brainMask,:), allData, 'UniformOutput', false);

        end

        %% Run the denoising GLM algorithm
        [allResults,denoiseddata] = GLMdenoisedata(allDesign, allData, ...
            stimdur, tr, hrfmodel, hrfknobs, opt, figureDir);

        %% Save data
        switch hrfmodel
            case 'fir'
                results = []; bstresults = [];
                results.modelmd         = allResults.modelmd;
                results.brainMask       = brainMask;
                results.brainIndx       = find(brainMask > 0);
                results.volDims     	= volDims;
                results.subjName        = sprintf('%s', subject);
                results.hrfmodel        = hrfmodel;
                results.ROIlabels       = ROIlabels;
                results.locCoherence    = selCo;

                bstresults.models       = allResults.models;
                bstresults.brainMask    = brainMask;
                bstresults.brainIndx    = find(brainMask > 0);
                bstresults.volDims      = volDims;
                bstresults.subjName     = sprintf('%s', subject);
                bstresults.hrfmodel     = hrfmodel;
                bstresults.ROIlabels    = ROIlabels; 

            case 'optimize'
                results = []; bstresults = [];
                results.hrf             = allResults.modelmd{1};
                results.modelmd         = allResults.modelmd{2};
                results.brainMask       = brainMask;
                results.brainIndx       = find(brainMask > 0);
                results.volDims     	= volDims;
                results.subjName        = sprintf('%s', subject);
                results.hrfmodel        = hrfmodel;
                results.ROIlabels       = ROIlabels(brainMask);
                results.locCoherence    = selCo;

                bstresults.models       = allResults.models{2};
                bstresults.brainMask    = brainMask;
                bstresults.brainIndx    = find(brainMask > 0);
                bstresults.volDims      = volDims;
                bstresults.subjName     = sprintf('%s', subject);
                bstresults.hrfmodel     = hrfmodel;
                bstresults.ROIlabels    = ROIlabels(brainMask);

        end

        % R2
        R2                  = zeros(prod(volDims), 1);
        if ~isequal(size(results.modelmd,1), sum(brainMask))
            R2(brainMask,:) = allResults.R2;
        else
            R2              = allResults.R2;
        end
        results.R2          = allResults.R2;

        save(fullfile(outDir, resultsFileName), 'results', '-v7.3');
        save(fullfile(outDir, sprintf('bst%s', resultsFileName)), 'bstresults', '-v7.3');
        save(fullfile(outDir, sprintf('full-%s', resultsFileName)), 'allResults', '-v7.3');
        save(fullfile(outDir, sprintf('denoiseddata-%s', resultsFileName)), 'denoiseddata', '-v7.3');

        %% Save out R2 map

        if useCluster < 1
            whichSes            = sessList(1).name;
            refInfo             = dir(fullfile(dataDir, whichSes, 'func', sprintf('%s_%s_task-%s_run-*1_space-T1w_boldref.nii.gz', subject, whichSes, taskNames{1})));
            R2info              = MRIread(fullfile(refInfo.folder, refInfo.name));
            R2info.Description  = 'Modified using MATLAB R2020b';
            R2info.Datatype     = 'single';
            R2info.vol          = single(reshape(R2, volDims));

            MRIwrite(R2info, fullfile(saveDir, sprintf('%s_GLMdenoise_R2_%s.VOL.mgz', subject, hrfmodel)));
        end
    elseif exist(fullfile(outDir, resultsFileName), 'file')

        fprintf('[%s] Analysis exists for %s ... \n', mfilename, subject)

    else

        fprintf('[%s] No designmatrices found for %s ... \n', mfilename, subject)

    end
end

end