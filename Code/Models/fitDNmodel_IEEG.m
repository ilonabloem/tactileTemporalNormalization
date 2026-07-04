
function out = fitDNmodel_IEEG(freeParams, fixedParams)

mode         = fixedParams{1};

if length(fixedParams) < 6
    fixedParams{6} = 'doubleGamma';
end
switch mode

    case 'initialize'

        % init(1):  tau1, neural IRF peak time, in second
        % init(2):  weight, ratio of negative to positive IRFs (set to 0
        %               for uniphasic irf)
        % init(3):  tau2, time window of adaptation, in second
        % init(4):  n, exponent
        % init(3):  sigma, semi-saturation constant
        % init(5):  shift, time between stimulus onset and when the signal reaches
        %               the cortex (millisecond)
        % init(6):  scale -- response gain
        switch fixedParams{6}
            case 'singleGamma'
                out.opts     = optimset('display','off');
                out.init     = [0.05, 0.1, 1.5, 0.05, 0.06, 3]; % model start params from x0
                out.lb       = [0.001   0.01, 1, 0, 0, 0.01]; % lower bound
                out.ub       = [0.5, 0.5, 2, 1, 0.1, 50]; % upper bound
                out.labels   = {'tau1','tau2','n','sigma','shift','gain'};

                if strcmp(fixedParams{5}, 'bads')
                    out.plb      = [0.01, 0.1, 1.5, 0.01, 0.01, 0.5]; % plausible lower bound
                    out.pub      = [0.3, 0.2, 2, 0.5, 0.08, 20]; % plausible upper bound                
                end

            case 'doubleGamma'
                out.opts     = optimset('display','off');
                out.init     = [0.05,   0.2,    0.1,    1.5,    0.05,   0.06,   3]; % model start params from x0
                out.lb       = [0.001,  0,      0.01,   1,      0,      0,      0.01]; % lower bound
                out.ub       = [0.5,    1,      0.5,    3,      1,      0.1,    50]; % upper bound
                out.labels   = {'tau1','weight','tau2','n','sigma','shift','gain'};
                if strcmp(fixedParams{5}, 'bads')
                    out.plb      = [0.01, 0.1, 0.1, 1.5, 0.01, 0.01, 0.5]; % plausible lower bound
                    out.pub      = [0.3, 0.5, 0.2, 2, 0.5, 0.08, 20]; % plausible upper bound                
                end
        end
        
    case{'optimize', 'prediction'}

        x_data       = fixedParams{2};
        y_data       = fixedParams{3};
        fixedP       = fixedParams{4};

        y_est        = DNmodel_IEEG(freeParams, fixedP);
        
        assert(isequal(size(y_data,1), size(y_est,1)), 'dimensions of data and prediction are not the same')

        if strcmp(mode, 'optimize')

            if any(isnan(y_est))
                out             = 1e10;
            else
                out             = double(sum((y_data(:) - y_est(:)).^2));
            end
            
        elseif strcmp(mode, 'prediction')
            if ~isempty(y_data)
                out.R2      = 1 - sum((y_data(:) - y_est(:)).^2, 1) ./ sum((y_data(:) - mean(y_data(:), 1)).^2, 1);
                out.SSE     = sum((y_data(:) - y_est(:)).^2);

            end
            out.param       = freeParams;
            out.y_est       = y_est;
            out.y_data      = y_data;
            out.x_data      = x_data;
            out.condNames   = fixedP.ConditionNames;
            switch fixedParams{6}
                case 'singleGamma'
                    out.labels      = {'tau1','tau2','n','sigma','shift','scale'};
                case 'doubleGamma'
                    out.labels      = {'tau1','weight','tau2','n','sigma','shift','scale'};
            end

        end

end


end