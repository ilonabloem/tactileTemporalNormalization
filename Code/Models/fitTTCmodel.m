function out = fitTTCmodel(freeParams, fixedParams)
% FITTTCMODEL  Fit wrapper for the fMRI two-temporal-channel model.
% Fixed channel IRFs and fixed HRF (via fixedP.hrfParams); free params are
% the transient weight and gain, as in Zhou 2018 / Groen 2022.
%   freeP = [weight gain]

mode = fixedParams{1};

switch mode
    case 'initialize'
        out.opts   = optimset('display','off');
        out.init   = [ 0.5    1  ];
        out.lb     = [ 0      0  ];
        out.ub     = [ 1    1e3  ];
        out.labels = {'weight','gain'};

    case {'optimize','prediction'}
        x_data = fixedParams{2};
        y_data = fixedParams{3};
        fixedP = fixedParams{4};

        y_est  = TTCmodel(freeParams, fixedP);
        assert(isequal(size(y_data,1), size(y_est,1)), 'data/prediction size mismatch')

        if strcmp(mode,'optimize')
            if any(isnan(y_est))
                out = 1e10;
            else
                out = double(sum((y_data(:) - y_est(:)).^2));
            end
        else
            if ~isempty(y_data)
                out.R2  = 1 - sum((y_data(:)-y_est(:)).^2,1) ./ sum((y_data(:)-mean(y_data(:),1)).^2,1);
                out.SSE = sum((y_data(:)-y_est(:)).^2);
            end
            out.param     = freeParams;
            out.y_est     = y_est;
            out.y_data    = y_data;
            out.x_data    = x_data;
            out.condNames = fixedP.ConditionNames;
            out.labels    = {'weight','gain'};
        end
end
end
