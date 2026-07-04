function out = fitHRFmodel(freeParams, fixedParams)

mode         = fixedParams{1};

switch mode

    case 'initialize'

        % init(1):  tau1, neural IRF peak time, in second
        % init(2):  response gain of the predicted BOLD responses
        % init(3):  gamma1 time to peak, in second
        % init(4):  gamma2 time to peak, in second
        out.opts     = optimset('display','off');
        out.init     = [   1       5       8       1]; % model start params
        out.lb       = [   0       0       0       0]; % lower bound
        out.ub       = [ 1e3      20      20     1e3]; % upper bound
        out.plb      = [   1       4       5     0.8]; % plausible lower bound
        out.pub      = [  20       8      10     1.2]; % plausible upper bound
        out.labels   = {'gain','gamma1', 'gamma2','gamma2_gain'};

    case{'optimize', 'prediction'}

        x_data       = fixedParams{2};
        y_data       = fixedParams{3};
        fixedP       = fixedParams{4};

        y_est        = HRFmodel(freeParams, fixedP);

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
            out.labels      = {'gain','gamma1', 'gamma2','gamma2_gain'};

        end

end


end