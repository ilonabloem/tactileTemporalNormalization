
%% Create design matrix and save as .tsv files

projectName     = 'tactileTemporalNormalization';

[projectDir, dataRootDir] = rootPath(false, projectName);

dataDir         = fullfile(dataRootDir, 'behavioralData');
outDir          = fullfile(dataRootDir, 'designMatrices');

expPrms         = expDetailsTemporalTactile(projectName);

numConditions   = numel(expPrms.ConditionNames);

%% find all participants
fnameList       = fullfile(dataRootDir, '..', sprintf('participants.tsv'));
T               = readtable(fnameList, 'FileType', 'delimitedtext', 'Delimiter', '\t');
subjNames       = T.participant_id;
numSubjects     = numel(subjNames);

for s = 1:numel(subjNames)
    
    %% Current subject
    subject         = subjNames{s};
    
    % Find behavioral data files
    dataFile = dir(fullfile(dataDir, sprintf('%s_*%s_*_task-%s*.mat', projectName, subject, expPrms.taskNames{1})));
    
    if ~isempty(dataFile)
        
        saveDir = fullfile(outDir, subject);
        if ~exist(saveDir, 'dir'), mkdir(saveDir); end
 
        for d = 1:numel(dataFile)
            
            strSplit    = split(dataFile(d).name, ["_", "."]);
            curSess     = strSplit{contains(strSplit, 'ses')};
%              curSess   = sprintf('%s%02d', session, d);
            if ~exist(fullfile(saveDir, sprintf('%s', curSess)), 'dir'); mkdir(fullfile(saveDir, sprintf('%s', curSess))); end

            %% Load behavioral data
            if ~isempty(dir(fullfile(saveDir, sprintf('%s', curSess), sprintf('%s_%s_%s_run-*_design.tsv', projectName, subject, curSess))))
                
                fprintf('[%s] Design matrices exist for %s %s \n', mfilename, subject, curSess)
                
            else
                
                currFile        = dir(fullfile(dataDir, sprintf('%s_%s_%s*.mat', projectName, subject, curSess)));
                
                if isempty(currFile)
                
                    fprintf('[%s] No tasks runs found for %s %s \n', mfilename, subject, curSess)
                    
                else
                    
                    fprintf('[%s] Creating design matrices for %s %s \n', mfilename, subject, curSess)
                    
                    results         = load(fullfile(currFile.folder, currFile.name), 'TheData');
                    numRuns         = numel(results.TheData);

                    totalTR         = results.TheData(1).t.totalTR;

                    fullMatrix      = cell(1,numRuns);
                    ITIs            = [];
                    behavReports    = zeros(numRuns, 4); % behavioral reports 

                    dmFig           = figure('Color', [1 1 1], 'Position', [30 600 1400 700]);
                    set(dmFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[1400 700])

                    itiFig          = figure('Color', [1 1 1], 'Position', [30 600 1400 700]);
                    set(itiFig,'Units', 'Pixels', 'PaperPositionMode','Auto','PaperUnits','points','PaperSize',[1400 700])

                    % Create design matrices
                    for n = 1:numRuns

                        allEvents       = results.TheData(n).output.allEvents;                    
                        designMatrix    = zeros(totalTR, numConditions);
                        runITI          = []; 

                        % Loop through all events
                        for tr = 1:size(allEvents,1)

                            % record events in designmatrix
                            if allEvents(tr,3) > 0
                                whichCondition  = allEvents(tr,3);
                                designMatrix(allEvents(tr,1)+1, whichCondition) = ones(1,1);
                            % record duration of intertrial interval
                            else
                                runITI     = cat(1, runITI, allEvents(tr,2));
                            end
                        end

                        % Combine design matrices for each stimulation condition/run
                        fullMatrix{n}   = designMatrix;
 
                        % Write tsv for each run
                        fileName    = sprintf('%s_%s_%s_run-%02d_design.tsv', projectName, subject, curSess, n);
                        fid         = fopen(fullfile(saveDir, sprintf('%s', curSess), fileName), 'w');
                        fprintf(fid, [repmat('%d\t ', [1 size(fullMatrix{n},2)]) '\n'], fullMatrix{n}');
                        fclose(fid);

                        figure(dmFig)
                        subplot(1,numRuns,n)
                        imagesc(fullMatrix{n})
                        title(['Run ' num2str(n)])
                        xlabel('Condition'), ylabel('Time (TR)')

                        % Combine ITIs across runs, removing the initial and final blank periods 
                        runITI          = runITI(2:end,:);
                        runITI(end)     = runITI(end)-10;
                        ITIs            = cat(2, ITIs, runITI); 

                        %-- visualize
                        figure(itiFig)
                        subplot(1,numRuns,n)
                        histogram(runITI, 0.5:1:18.5)
                        title(['Run ' num2str(n)]); box off; ylim([0 18])
                        xlabel('ITI (s)'), ylabel('Count')

                        %-- find behavioral report
                        if strcmp(projectName, 'tactileTemporalNormalization')
                            behavReports(n,:) = cat(2, results.TheData(n).t.totalChanges, results.TheData(n).output.response, results.TheData(n).output.respAcc, abs(results.TheData(n).t.totalChanges-results.TheData(n).output.response));

                        end

                    end
                    
                    figure(dmFig)
                    sgtitle(sprintf('%s %s', subject, curSess))
                    print(gcf, fullfile(saveDir, sprintf('%s', curSess), sprintf('%s_%s_%s_designMatrices', projectName, subject, curSess)), '-dpdf')

                    figure(itiFig)
                    sgtitle(sprintf('%s %s ITI range [%i %i]', subject, curSess, min(ITIs(:)), max(ITIs(:))))
                    print(gcf, fullfile(saveDir, sprintf('%s', curSess), sprintf('%s_%s_%s_ITIinfo', projectName, subject, curSess)), '-dpdf')

                    behavPerf       = array2table(behavReports, 'VariableNames', {'colorChanges' 'numberReport' 'correct', 'missedCounts'});
                    writetable(behavPerf, fullfile(saveDir, sprintf('%s_%s_%s_behavReports.csv', projectName, subject, curSess)))
                    
                    accuracy(s)     = sum(behavPerf.correct)/height(behavPerf);
                    missedCounts(s) = mean(abs(behavPerf.numberReport - behavPerf.colorChanges));
                end
            end
        end
    end

end