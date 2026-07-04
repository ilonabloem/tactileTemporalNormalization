
projectName     = 'tactileTemporalNormalization';

[projectDir, dataRootDir] = rootPath(false, projectName);

dataDir         = fullfile(dataRootDir, 'designMatrices');

%-- find all participants
fnameList       = fullfile(dataRootDir, sprintf('participants.tsv'));
T               = readtable(fnameList, 'FileType', 'delimitedtext', 'Delimiter', '\t');
subjNames       = T.participant_id;
numSubjects     = numel(subjNames);

minChanges      = NaN;
maxChanges      = NaN;
maxMisses       = NaN;
accCount        = NaN(1,numSubjects);
missCount       = NaN(1,numSubjects);

for s = 1:numSubjects

    % Current subject
    subject     = subjNames{s};
    
    % Find performance overview
    dataFile    = dir(fullfile(dataDir, subject, sprintf('%s_%s_*behavReports.csv', projectName, subject)));
    
    % Make sure file exists
     if isempty(dataFile)
                
            fprintf('[%s] No performance file found for %s \n', mfilename, subject)
            
        else
            
            fprintf('[%s] Loading performance file for %s \n', mfilename, subject)

            fname           = fullfile(dataFile.folder, dataFile.name);
            opts            = detectImportOptions(fname);
            data            = readtable(fname, opts);

            % keep track of range of color changes across participants
            minChanges      = min(minChanges, min(data.colorChanges));
            maxChanges      = max(maxChanges, max(data.colorChanges));
            
            maxMisses       = max(maxMisses, max(data.missedCounts));

            % keep track of average missed counts
            accCount(s)     = mean(data.correct);
            missCount(s)    = mean(data.missedCounts);
            
     end

end

%-- save out some stats about voxel selection
fname           = sprintf('%s_behavioralPerformance.json', projectName);
inputVar        = struct('scriptName', mfilename, ...
                    'minChanges', minChanges, ...
                    'maxChanges', maxChanges, ...
                    'accuracy', accCount, ...
                    'absError', missCount, ...
                    'subjAges', T.age);        
savejson('',inputVar, fullfile(dataRootDir, fname));

disp(inputVar)
fprintf('average accuracy selecting correct number of changes: %.1f \n', mean(accCount)*100)
fprintf('average absolute error changes: %.1f [%.1f %.1f] \n', mean(missCount), min(missCount), max(missCount))


