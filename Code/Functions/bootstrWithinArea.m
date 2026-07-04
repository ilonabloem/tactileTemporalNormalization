function [m, se, m_boot, n_elecs_selected] = bootstrWithinArea(data, fun, numboot, CIrange)
% Bootstrap average across electrodes within the same area
%
% [m, se] = averageWithinArea(data, [fun], [numboot])
%
% Input
%     data:             The to be averaged data, e.g. a list of fitted
%                       parameters for each channel. Can be multi-
%                       dimensional (e.g. a time-course for each channel),
%                       but the last dimension should be channels.
%     fun:              (optional) Averaging function (default: @median).
%     numboot:          (optional) Number of bootstraps (default: 1000).
%     CIrange:          (optional) Confidence interval range (default: 5 to give 95% CI).
%
% Output
%     m:                estimated summary metric (default median).
%     se:               100-CIrange% confidence interval.
%
% IB 2025

if ~exist('fun','var') || isempty(fun)
    fun = @median;
end

if ~exist('numboot','var') || isempty(numboot)
    numboot = 1000;
end

if ~exist('CIrange','var') || isempty(CIrange)
    CIrange = 5; % default is 95% CI
end

% if there are more than one dimension per channel, vectorize data
if ndims(data) == 3
    multiDimData = true;
    dataSz = size(data);
    data = reshape(data, [dataSz(1) * dataSz(2) dataSz(3)]);
else
    multiDimData = false;
end

% pre-allocate
[~, nElecs] = size(data);
m_boot = nan(size(data,1), numboot); 
n_elecs_selected = nan(1, numboot);

if numboot > 1
    fprintf('[%s] Computing %s using %d bootstraps...\n', mfilename, func2str(fun), numboot);

    % each boot, sample all channels at once
    for ii = 1:numboot
        elec_idx = randsample(1:nElecs,nElecs,1);
        sampled_data = data(:,elec_idx);

        m_boot(:,ii) = fun(sampled_data,2);
        % track how many electrodes were sampled on each bootstrap
        n_elecs_selected(ii) = length(unique(elec_idx));
    end
    
    % take mean of bootstrapped distribution and compute confidence intervals
    m = mean(m_boot,2, 'omitnan');
    se = squeeze(prctile(m_boot,[CIrange/2 100-(CIrange/2)],2));
    
    % report average number of electrodes sampled per bootstrap
    mn_elecs_selected = median(n_elecs_selected);
    fprintf('[%s] Median no of included elecs = %0.1f \n',mfilename, mn_elecs_selected);

end

% reshape back to original shape
if multiDimData
    m = reshape(m, [dataSz(1) dataSz(2)]); 
    if ~isempty(se)
        se = reshape(se, [dataSz(1) dataSz(2) 2]);
    end
end

end
