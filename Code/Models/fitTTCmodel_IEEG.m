function out = fitTTCmodel_IEEG(freeParams, fixedParams)
% FITTTCMODEL_IEEG  Fit wrapper for the iEEG two-temporal-channel model.
% Mirrors fitLINmodel_IEEG.m interface.
%   freeP = [weight shift scale]

mode = fixedParams{1};
if length(fixedParams) < 6, fixedParams{6} = 'doubleGamma'; end

switch mode

    case 'initialize'
        out.opts   = optimset('display','off');
        %              weight  shift(ms)  scale
        out.init   = [  0.5      0.06      3   ];
        out.lb     = [  0        0         0.01];
        out.ub     = [  1        0.1      50   ];
        out.labels = {'weight','shift','scale'};
        if strcmp(fixedParams{5}, 'bads')
            out.plb = [0.1  0.01  0.5];
            out.pub = [0.9  0.08  20 ];
        end

    case {'optimize','prediction'}
        x_data = fixedParams{2};
        y_data = fixedParams{3};
        fixedP = fixedParams{4};

        y_est  = TTCmodel_IEEG(freeParams, fixedP);
        assert(isequal(size(y_data,1), size(y_est,1)), 'data/prediction size mismatch')

        if strcmp(mode,'optimize')
            if any(isnan(y_est))
                out = 1e10;
            else
                out = double(sum((y_data(:) - y_est(:)).^2));
            end
        else % prediction
            if ~isempty(y_data)
                out.R2  = 1 - sum((y_data(:)-y_est(:)).^2,1) ./ sum((y_data(:)-mean(y_data(:),1)).^2,1);
                out.SSE = sum((y_data(:)-y_est(:)).^2);
            end
            out.param     = freeParams;
            out.y_est     = y_est;
            out.y_data    = y_data;
            out.x_data    = x_data;
            out.condNames = fixedP.ConditionNames;
            out.labels    = {'weight','shift','scale'};
        end
end
end
