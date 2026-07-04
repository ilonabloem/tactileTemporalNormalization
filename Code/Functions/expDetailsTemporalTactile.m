
function out = expDetailsTemporalTactile(projectName)


switch projectName 
    
    case 'TemporalTactile'
        
        taskNames       = {'temp'};
        session         = 'nyu3t';
                
        ConditionNames  = {'ONE-PULSE-1';
                           'ONE-PULSE-2';
                           'ONE-PULSE-3';
                           'ONE-PULSE-4';
                           'ONE-PULSE-5';
                           'ONE-PULSE-6';
                           'TWO-PULSE-1';
                           'TWO-PULSE-2';
                           'TWO-PULSE-3';
                           'TWO-PULSE-4';
                           'TWO-PULSE-5';
                           'TWO-PULSE-6';
                           'BLANK_PULSE';
                           'TASK_PULSE'};
        
                       
    case 'tactileTemporalNormalization'
        
        taskNames       = {'tact'};
        session         = 'nyu3t';
                
        ConditionNames  = {'ONE-PULSE-1';
                           'ONE-PULSE-2';
                           'ONE-PULSE-3';
                           'ONE-PULSE-4';
                           'ONE-PULSE-5';
                           'ONE-PULSE-6';
                           'TWO-PULSE-1';
                           'TWO-PULSE-2';
                           'TWO-PULSE-3';
                           'TWO-PULSE-4';
                           'TWO-PULSE-5';
                           'TWO-PULSE-6';
                           'BLANK_PULSE'};
        
               
end

%-- ROIs of interest
allROInames     = { 'localizerROI', 'S1';
                    'localizerROI', 'BA3b';
                    'localizerROI', 'BA1';
                    'localizerROI', 'BA2';
                    };

%-- experiment variables
stimdur         = [0.05 0.1 0.2 0.4 0.8 1.2]; % seconds
twoPulseDur     = 0.2; % pulse duration in two-pulse condition, in seconds
tr              = 1;

out             = variable2struct(taskNames, session, ConditionNames, ...
                    allROInames, stimdur, twoPulseDur, tr);


end
 

function s = variable2struct(varargin)

    s       = struct;
    for var = 1:nargin
       s.(inputname(var)) = varargin{var};
    end

end