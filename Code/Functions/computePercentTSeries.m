
function pTSeries = computePercentTSeries(TSeries, nFrames)
% Removes the DC and baseline trend of a time series

%-- Inputs
% TSeries:  
% nFrames:
% 
%-- Outputs
% pTSeries:     


%% Demean 
%-- Make sure we will average over the correct dimension
dims        = size(TSeries);
assert(numel(dims) == 2, 'Data can only have 2 dimensions')

wdim        = find(dims == nFrames);

% change dimensions if necessary
if wdim > 1
    TSeries  = TSeries';
end

% Divide by the mean
dc          = nanmean(TSeries,1);
dc(dc==0 | isnan(dc)) = Inf;  % prevents divide-by-zero warnings
pTSeries    = bsxfun(@rdivide, TSeries, dc);

%% Remove linear trend
model       = [linspace(0,1,nFrames); ones(1,nFrames)]';

wgts        = model\pTSeries;
trends      = model*wgts;
pTSeries    = pTSeries - trends;

%% Subtract mean and convert to percent
pTSeries    = bsxfun(@minus, pTSeries, mean(pTSeries,1));
% Multiply by 100 to get percent
pTSeries    = 100*pTSeries;

%% change dimensions if necessary
if wdim > 1
    pTSeries  = pTSeries';
end