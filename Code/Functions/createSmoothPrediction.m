
function out = createSmoothPrediction(params, data, isiEEG, opt)

if ~exist("isiEEG","var"); isiEEG = false; end
if isstruct(data); model = data.model; else; model = data; end
if ~exist("opt","var") | isempty(opt)
    opt                 = [];
    opt.numConditions   = 482;
    opt.stimdur         = linspace(0, 1.2, opt.numConditions/2);

end

%-- for which model to create predictions
if isiEEG
    currModel           = str2func(sprintf('%smodel_IEEG', model));
else
    currModel           = str2func(sprintf('%smodel', model));
end

%-- create finer sampling and stimuli names 
opt.x_data          = 0:1:10;
opt.twoPulseDur     = 0.2;
if isiEEG
    opt.x_data          = data.x_data;
    opt.srate           = 512; 
    opt.t               = data.t;
end

onePulseNames       = strrep('ONE-PULSE-%s','%s', cellstr(string((1:opt.numConditions/2)')));
twoPulseNames       = strrep('TWO-PULSE-%s','%s', cellstr(string((1:opt.numConditions/2)')));

opt.ConditionNames  = cat(1, onePulseNames, twoPulseNames); 

%-- create prediction

pred                = currModel(params, opt); 

out.pred            = pred';
out.stimdur         = opt.stimdur;