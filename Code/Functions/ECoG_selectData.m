function [out, epochs, channels] = ECoG_selectData(data, p)
% Based on tde_selectData

%% Loop through all participants
    
% Options for function ecog_selectEpochs
if ~isfield(p,'epoch_jump_thresh') || isempty(p.epoch_jump_thresh)
    p.epoch_jump_thresh = []; % max jump in voltage allowed within stim_on period
end
if ~isfield(p,'epoch_outlier_thresh') || isempty(p.epoch_outlier_thresh)
    p.epoch_outlier_thresh = 4; % xfold of the standard deviation of the maximum broadband values within each epoch
end
if ~isfield(p,'stim_on') || isempty(p.stim_on)
    p.stim_on = [0 1]; % time period across which stimulus is presented
end
if ~isfield(p,'baseline_time') || isempty(p.baseline_time)
    p.baseline_time = [-0.2 0]; % time period across which to compute normalization baseline
end
if ~isfield(p,'elec_selection_method') || isempty(p.elec_selection_method)
    p.elec_selection_method = 'thresh'; % thresh, splithalf, meanpredict
end
if ~isfield(p,'elec_max_thresh')
    p.elec_max_thresh = 0.85; % minimum required maximal response in % signal change for electrode inclusion
end
if ~isfield(p,'elec_mean_thresh') || isempty(p.elec_mean_thresh)
    p.elec_mean_thresh = 0; % minimum required mean response during stim_on period in % signal change
end
if ~isfield(p,'elec_splithalf_thresh') || isempty(p.elec_splithalf_thresh)
    p.elec_splithalf_thresh = 0.22; % minimum required R2 between split halves of data
end
if ~isfield(p,'elec_meanpredict_thresh') || isempty(p.elec_meanpredict_thresh)
    p.elec_meanpredict_thresh = 0; % minimum required R2 for prediction by mean (1 - (SSEresidual/SSEtotal)
end
if ~isfield(p,'average_trials') || isempty(p.average_trials)
    p.average_trials = false; 
end
% Keep all current fields in data struct
out     = data;

figureDir       = fullfile(p.figureDir, 'selectData');
if ~exist(figureDir, 'dir'), mkdir(figureDir), end

for id = 1

    broadPowData    = data(id).epochs;
    events          = data(id).events;
    channels        = data(id).channels;
    t               = data(id).t;
    
    %% Stage 2: Data selection 
    fprintf('[%s] Select data for subject %s to %s \n', mfilename, p.IDList{id}, p.outputDir);
    
    %-- Copy events and change trial names 
    %-- include pRF stimuli, and prf BLANK 
    stmlist = double(ismember(events.task_name,'tacttestascending') | ...
                contains(events.task_name,'temporalpattern')); 

    % Select all conditions
    p.stimnames = unique(events.trial_name(stmlist==1));
    
    % Find stimulus events and restrict selection to relevant stimuli only
    stimIndx            = contains(events.trial_name, p.stimnames); %~strcmp(events.task_name, 'prf');
    selectbroadPowdata  = broadPowData(:, stimIndx, :);
    events              = events(stimIndx, :);
    
    % Include only requested areas -  do not have area names for NY726
    %{
    if ~isempty(p.areanames)
        if ~iscell(p.areanames), p.areanames = {p.areanames}; end
        [~, ~, group_prob]      = groupElecsByVisualArea(channels, 'probabilisticresample', p.areanames);
        chan_idx = any(group_prob,2);
        if ~any(chan_idx)
            fprintf('[%s] Did not find matching electrodes in area %s for subject p%02d\n', mfilename, [p.areanames{:}], id);
            channels            = [];
            out(id).voltEpochs  = [];
            out(id).channels    = channels;
            out(id).epochs      = [];
            out(id).stimnames   = [];
    
            continue
        else
            channels            = channels(chan_idx,:);
            selectbroadPowdata  = selectbroadPowdata(:,:,chan_idx);
            selectVoltData      = selectVoltData(:,:,chan_idx);      
        end
    end
    %}

    % Broadband trials

    % Provide run index to perform separately for each run and session
    [~,~,task_idx]  = unique(events.trial_name);
    [~,~,ses_idx]   = unique(events.session_name);
    [~,~,run_idx]   = unique(events.run_name);
    [~,~,idx]       = unique([task_idx ses_idx run_idx], 'rows');

    %-- data was already normalized!!
    %selectbroadPowdata  = ecog_normalizeEpochs(selectbroadPowdata, t, p.baseline_time, 'percentsignalchange', idx);

    % --------------------
    % Identify bad epochs
    fprintf('[%s] Removing bad epochs...\n',mfilename);

    if isempty(p.epochTime)
        t_sel   = true(size(t));
    else
        t_sel   = t >= p.epochTime(1) & t < p.epochTime(2);
    end
    
    [select_idx, max_epochs, outlier_thresh] = ecog_selectEpochs([], selectbroadPowdata(t_sel,:,:), t(t_sel), p);
    outlier_idx = ~select_idx;
    
    % Plot the included and excluded trials: all channels combined
    if p.doPlots
        fprintf('[%s] Plotting epoch selection ...\n',mfilename);
        % Make separate plots for different electrode groups
        groups = unique(channels.group);
        nGroups = length(groups);
        for jj = 1:nGroups
            chan_idx = find(strcmp(channels.group, groups{jj}));
            nChans = length(chan_idx);
            plotList = ones(nChans,1);
            % Split large HDgrid, otherwise plotting takes very long
            switch groups{jj}
                case 'HDgrid'
                    plotList(round(nChans/3):round(nChans/3)*2) = 2;
                    plotList(round(nChans/3)*2:end) = 3;
            end
            for kk = 1:max(plotList)
                figureName = sprintf('outlierepochs_allchans_sub-%02d-%s-%d', id, groups{jj}, kk);
                figure('Name', figureName);hold on
                chanstoPlot = chan_idx(plotList == kk);
                outlier_idx_group = outlier_idx(:,chanstoPlot);
                epochs_b_group = selectbroadPowdata(:,:,chanstoPlot);        
                if any(outlier_idx_group(:)) 
                    subplot(1,2,1); 
                    plot(t(t_sel), epochs_b_group(t_sel,outlier_idx_group)); axis tight
                    title('excluded epochs - broadband')
                end
                subplot(1,2,2); 
                plot(t(t_sel), epochs_b_group(t_sel,~outlier_idx_group)); axis tight
                title('included epochs - broadband')
                % Set axes
                set(findall(gcf,'-property','FontSize'),'FontSize',14)
                set(gcf, 'Position', [150 100 1400 600]);
                % Save
                saveas(gcf, fullfile(figureDir, figureName), 'png'); close;
            end
        end
    end
    
    % Plot the outlier trials: individual plots
    if p.doPlots
        fprintf('[%s] Plotting removed epochs...\n',mfilename);

        for jj = 1:height(channels)
            
            if any(outlier_idx(:,jj))
                outliers_found = find(outlier_idx(:,jj));
                nOutliers = length(outliers_found);
                dim1 = round((nOutliers+1)/2);
                dim2 = round((nOutliers+1)/dim1);
                % plot
                figureName = sprintf('outlierepochs_sub-%02d_chan-%s-broadband', id, channels.name{jj});
                figure('Name', figureName); hold on;
                subplot(dim2,dim1,1); hold on; title(channels.name{jj}); 
                histogram(max_epochs(:,jj),100); line([outlier_thresh(jj) outlier_thresh(jj)], get(gca, 'YLim'), 'Color', 'r','LineStyle', ':', 'LineWidth', 2);
                set(gca, 'fontsize', 14); xlabel('max pows'); ylabel('number of epochs');
                for kk = 1:nOutliers
                    subplot(dim2,dim1,kk+1); 
                    ecog_plotSingleTimeCourse(t(t_sel), selectbroadPowdata(t_sel,outliers_found(kk),jj), [], [], sprintf('epoch %d %s', outliers_found(kk), events.trial_name{outliers_found(kk)}));    
                end
                set(gcf, 'Position', [150 100 300*dim1 300*dim2]);
                saveas(gcf, fullfile(figureDir, figureName), 'png'); close;
            end
        end
    end
    
    % Mask the broadband epochs to include only the selected epochs.
    epochs = selectbroadPowdata;
    epochs(:,outlier_idx) = NaN;
    
     
    % ------------------------------
    % STEP 3 Select electrodes   
    fprintf('[%s] Selecting electrodes...\n',mfilename);

    [select_idx, R2, epochs_split] = ECoG_selectElectrodes(epochs(t_sel,:,:), channels, events, t(t_sel), p);
    % channels.noiseceilingR2 = round(R2,2);
    epochs_selected = epochs(:,:,select_idx);
    channels_selected = channels(select_idx,:);

    if p.doPlots    

        fprintf('[%s] Plotting electrode selection...\n',mfilename);

        if ~isempty(epochs_split)
            for el = 1:height(channels)
                figureName = sprintf('Splithalf_%02d_%s_%s_%s', id, channels.name{el}, channels.benson14_varea{el}, channels.wang15_mplbl{el});
                figure;hold on;
                plot(squeeze(epochs_split(1,el,:)), 'r','LineWidth', 2);
                plot(squeeze(epochs_split(2,el,:)), 'b','LineWidth', 2);
                axis tight
                nSamp = sum(t_sel); nSampTot = nSamp * length(p.stimnames);
                set(gca, 'XTick', 1:nSamp:nSampTot, 'XTickLabel', p.stimnames);
                xtickangle(45)
                title(sprintf('%s %s %s R2 = %0.2f', channels.name{el}, channels.benson14_varea{el}, channels.wang15_mplbl{el}, R2(el)));
                scrSz = get(0, 'Screensize');
                set(gcf, 'Position', scrSz);
                set(findall(gcf,'-property','FontSize'),'FontSize',14)
                saveas(gcf, fullfile(figureDir, figureName), 'png'); close;
            end
        end

        % Compute mean across all trials
        mean_resp = mean(epochs,2,'omitnan');
        % Compute std deviations for plotting
        llim = (mean_resp - (std(epochs,0,2,'omitnan')));
        ulim = (mean_resp + (std(epochs,0,2,'omitnan')));
        mean_resp_sd = cat(2, llim, ulim);
        % Plot all channels
        nEl = size(mean_resp,3); 
        figureName = sprintf('tactelec_%02d_all', id);
        figure('Name', figureName); plotDim1 = round(sqrt(nEl)); plotDim2 = ceil((nEl)/plotDim1);
        for el = 1:nEl
            subplot(plotDim1,plotDim2,el); hold on
            plotTitle = sprintf('%s ', channels.name{el});        
            ecog_plotSingleTimeCourse(t, mean_resp(:,:,el), squeeze(mean_resp_sd(:,:,el)), [], plotTitle);
            %if el == 1; xlabel('Time (s)'); ylabel('Broadband signal change');end
            set(gcf, 'Position', [150 100 1500 1250]);
        end
        saveas(gcf, fullfile(figureDir, figureName), 'png'); close;
        % Plot selected channels
        figureName = sprintf('tactelec_%02d_selected', id);
        figure('Name', figureName); 
        for el = 1:nEl
            if select_idx(el)
                subplot(plotDim1,plotDim2,el); hold on
                plotTitle = sprintf('%s ', channels.name{el});        
                ecog_plotSingleTimeCourse(t, squeeze(mean_resp(:,:,el)), squeeze(mean_resp_sd(:,:,el)), [], plotTitle)    
                set(gcf, 'Position', [150 100 1500 1250]);
            end
        end
        saveas(gcf, fullfile(figureDir, figureName), 'png'); close;
    end
    
     % Select the channels
    epochs      = epochs_selected;
    
    % Update channels table
    channels    = channels_selected;
       
    out(id).channels    = channels;
    out(id).epochs      = epochs;
    out(id).events      = events;
    out(id).stimnames   = p.stimnames;
    
end 

