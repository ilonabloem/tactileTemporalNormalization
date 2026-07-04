
%% Temporal Tactile fMRI pilot

% Presents tactile stimuli at 5 finger tips of non-dominant hand.

% Behavioral task: count number of color changes of fixation dot

% Total TRs: 320

% setup: use channels 6-10 from cDAQ1Mod1, channels 1-10 from cDAQ1Mod2

%{
restoredefaultpath
addpath(genpath('C:\Users\winawerlab.000\Documents\MATLAB\toolboxes\Psychtoolbox-3\Psychtoolbox'))
addpath(genpath('C:\Users\winawerlab.000\Documents\MATLAB\toolboxes\Psychtoolbox-3\Psychtoolbox\PsychBasic\MatlabWindowsFilesR2007a'))
if exist('PsychStartup'), PsychStartup; end;
%}

restoredefaultpath
addpath(genpath('C:\Users\imblo\Documents\MATLAB\toolboxes\Psychtoolbox-3\Psychtoolbox'))
addpath(genpath('C:\Users\imblo\Documents\MATLAB\toolboxes\Psychtoolbox-3\Psychtoolbox\PsychBasic\MatlabWindowsFilesR2007a'))
if exist('PsychStartup', 'file'), PsychStartup; end

echo off
clearvars; close all

%%%%%%%%%%%
output.Subject      = '999';
output.sess         = 'nyu3t01';
output.CBIid        = '';
output.taskName     = 'tact';
output.wlSubjId     = sprintf('wlsubj%s', output.Subject);

Scan                = 0;
eyeTrackON          = 0;
whichOS             = 2;   % 1 = macOS, 2 = Windows
debugMode           = true;

stim.stimulatedHand = 'left'; % Indicate which hand has the tactile stimulators 'right' or 'left'
saveFileName        = sprintf('tactileTemporalNormalization_sub-%s_ses-%s_task-%s_scanOutput_%s.mat', output.wlSubjId, output.sess, output.taskName, datetime('today'));
stim.numFingers     = 5;

%%%%%%%%%%%

AssertOpenGL;
KbName('UnifyKeyNames');
%%% Set SkipSyncTests to 0 for real exp
Screen('Preference', 'SkipSyncTests',1);
% Screen('Preference', 'ConserveVRAM', 4096);
Screen('Preference', 'VisualDebugLevel', 0);
commandwindow;
input('hit enter to begin...  ');
KbQueueRelease()

%% Initiate and generate data file
w       = struct;
t       = struct;
tact    = struct;

if exist(saveFileName, 'file')
    
    load(saveFileName);
    runNum              = length(TheData)+1;
    output.runOrder      = TheData(runNum-1).output.runOrder;
    if runNum < 10
        output.eyeTrackName = [output.Subject '_T0' num2str(runNum)];
    else
        output.eyeTrackName = [output.Subject '_T' num2str(runNum)];
    end
    
    % Every 20 runs resample the sequence
    if rem(runNum,20) == 0
        output.runOrder = cat(2,output.runOrder, randsample(1:20, 20, 'false'));
    end
else
    runNum              = 1;
    output.eyeTrackName = [output.Subject '_T0' num2str(runNum)];
    output.runOrder     = randsample(1:20, 20, 'false');
end

%%%%%%%
stim.Conditions     = {'tactile'};


%% Setup display parameters
if Scan == 0
    if whichOS == 1
        deviceString        = 'Apple Internal Keyboard / Trackpad';
        triggerBox          = 'Apple Internal Keyboard / Trackpad';
    else
        deviceString        = 'Keyboard';
        triggerBox          = 'Keyboard';
    end
    keyPressNumbers     = [KbName('1!') KbName('2@') KbName('3#') KbName('4$')];
    [~,heigth]          = Screen('DisplaySize', 0);
    w.ScreenHeight      = round(heigth/10);
    w.ViewDistance      = 57;                                              % in cm, ideal distance: 1 cm equals 1 visual degree (at 57 cm)
    w.ScreenSizePixels  = Screen('Rect', 0);                               % Scanner display = [0 0 1024 768];
    w.whichScreen       = max(Screen('Screens'));

else
    deviceString        = '932';                                       % name of device box at scanner
    triggerBox          = '932';
    keyPressNumbers     = [KbName('1!') KbName('2@') KbName('3#') KbName('4$')];           % [KbName('1!') KbName('2@')]
    w.ScreenHeight      = 36.2;
    w.ViewDistance      = 83.5;                                            % in cm, ideal distance: 1 cm equals 1 visual degree (at 57 cm)
    w.ScreenSizePixels  = [0 0 1920 1080];                                 % Screen('Rect', 0);
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible')
    w.whichScreen       = max(Screen('Screens'));

end
triggerKey = KbName('5%');                                                  % KbName('=+');
deviceNumber = [];
deviceNumberTrigger = [];

%% Setup display parameters
w.VisAngle          = (2*atan2(w.ScreenHeight/2, w.ViewDistance))*(180/pi);% Visual angle of the whole screen
w.refreshRate       = Screen('FrameRate', w.whichScreen);

w.pixelSize         = (2*atan2((w.ScreenHeight/w.ScreenSizePixels(4))/2, w.ViewDistance))*(180/pi);   % in visual degree
w.pointSize         = (2*atan2((2.54/72)/2, w.ViewDistance))*(180/pi);                                % fontsize is in points (not pixel!) 1 letter point is 1/72 of an inch visual angle

%% Experiment parameters
%%% Timing parameters
t.MySeed            = sum(100*clock); rng('default');                      % Create a unique seed
t.sprev             = rng(t.MySeed);                                       % Make sure we're really using 'random' numbers
t.TheDate           = datestr(now,'yymmdd');                               % Collect todays date
t.TimeStamp         = datestr(now,'HHMM');                                 % Timestamp for saving out a uniquely named datafile (so you will never accidentally overwrite stuff)
t.phaseShift        = 0.1;                                                 % (seconds), grating phase shift rate
t.refresh           = 0.05;                                                % (seconds), refresh is faster than grating flicker for behavioral response collection

t.TR                = 1;

t.stimDur           = [0.05, 0.1, 0.2, 0.4, 0.8, 1.2];                     % seconds, length of tested stimulation (either constant vibration or gap between vibrations)
t.tapCondition      = [1, 2];                                              % either constant vibration == 1 or gap between two vibrations == 2
t.tapDurSecs        = 0.2;                                                 % seconds, duration of the taps in 2 tap condition
t.respDur           = 1.5;                                                 % response time

stim.signalAmpl     = 1;
stim.numAmpl        = numel(stim.signalAmpl);
stim.carrierFreq    = 110; %
stim.numFreq        = numel(stim.carrierFreq); 

%%% Visual stimulus parameters
stim.meanLum        = 128;
stim.ppd            = round(w.ScreenSizePixels(4)/w.VisAngle);             % pixels per degree visual angle
stim.fixPoint       = 0.15;
stim.fix_point      = round(stim.fixPoint*stim.ppd);
stim.textSize       = round(1/w.pointSize);

% make sure values are oneven
if ~mod(stim.fix_point,2), stim.fix_point = stim.fix_point-1; end


%% Setup trial events
% open paradigm file
t.paradigmFile      = fullfile(pwd, 'timing', sprintf('task-%s-0%02d.par', output.taskName, output.runOrder(runNum)));
fid                 = fopen(t.paradigmFile);
C                   = textscan(fid, '%n %n %n %n %s', 'Delimiter', '\t');
fclose(fid);

t.cumDur            = C{1};
t.eventDur          = C{3};
t.stimType          = C{2};
t.stimName          = C{5};

% add initial and final blank period
t.addBlank          = 10; % in secs
t.eventDur          = cat(1, t.addBlank, C{3});
t.eventDur(end)     = t.eventDur(end) + t.addBlank;
t.cumDur            = cat(1, 0, cumsum(t.eventDur(1:end-1)));
t.stimType          = cat(1, 0, C{2});
t.stimName          = cat(1, 'NULL ', C{5});

t.numConditions     = numel(unique(t.stimType))-1; % Don't count NULL
t.numTrials         = sum(t.stimType ~= 0);
t.numReps           = sum(t.stimType == 1);

conditionNames      = {'ONE-PULSE-1';
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

% Varying tap durations:
intervalOneDur      = [t.stimDur'; t.tapDurSecs*ones(size(t.stimDur')); NaN];
intervalTwoDur      = [zeros(size(t.stimDur')); t.tapDurSecs*ones(size(t.stimDur')); NaN];
isiDur              = [zeros(size(t.stimDur')); t.stimDur'; NaN];
trialDur            = sum([intervalOneDur, isiDur, intervalTwoDur],2);

tapConditions       = repmat(t.tapCondition, [size(t.stimDur,2) 1]);
tapConditions       = [tapConditions(:); NaN];

% Collect all trial info into a table:
output.allCond      = table(trialDur, intervalOneDur, isiDur, ...
                            intervalTwoDur, tapConditions, ...
                            conditionNames);

% Setup paradigm structure:
output.allEvents    = cat(2, t.cumDur, t.eventDur, t.stimType); 

output.eventLabels  = {'cumTime', ...
                        'duration', ...
                        'whichCondition'};

t.runDur            = t.cumDur(end)+t.eventDur(end);
t.totalTR           = t.runDur / t.TR;

% create fixation time changes
t.numFixChanges     = 20:1:30;
totalChanges        = randsample(t.numFixChanges, 1);

expTimes            = exprnd(10, [totalChanges,1]) + 3;
fixChanges          = cumsum(cat(1, expTimes));
%-- round to match refresh of stimulus flips
fixChanges          = round(fixChanges, 1);
%-- make sure changes fall within scan duration
t.fixChanges        = fixChanges(fixChanges < (t.runDur - 3));
t.totalChanges      = numel(t.fixChanges);

%% Tactile stimuli
if whichOS == 2 % Can only present tactile stimuli on windows
    % add path to the folder containing the low latency scripts
    addpath(fullfile(pwd, 'low-latency-startForeground'))

    tact.NIdaqRate      = 1000;
    tact.NIdaqNames     = {'cDAQ1Mod1' 'cDAQ1Mod2'};
    
    tact.signalDuration = t.eventDur(1); %create same length stimulus for all temporal conditions
    tact.samplPerPulse  = tact.signalDuration * tact.NIdaqRate;
    
    % Amount of stimulators per finger pad:
    tact.numStimFinger  = 3;
    
    % See if we need more than 1 headbox:
    if stim.numFingers*tact.numStimFinger > 10
        tact.numAnalogCh1   = 10;
        tact.numAnalogCh2   = 10;
    else
        tact.numAnalogCh1   = stim.numFingers*tact.numStimFinger;
        tact.numAnalogCh2   = 0;
    end
    tact.noAnalogCh  = [tact.numAnalogCh1 tact.numAnalogCh2];

    tact.stimulatorIndx = (1:tact.numStimFinger:tact.numStimFinger*stim.numFingers)+5;
    tact.totalAnalogCh = tact.numStimFinger*stim.numFingers;
    
    tact.allPulses      = zeros(t.numConditions-1, tact.samplPerPulse);
    % figure('Color', [1 1 1])
    for ii = 1:t.numConditions
        
        % One pulse condition:
        if output.allCond.tapConditions(ii) == 1
            % create sin wave ranging from 0 to 2 (max output allowed with VTS)
            % shift sinusoid by pi/2 so that signal starts at 0
            stimOn  = zeros(1,tact.samplPerPulse);
            stimOn(1:round(output.allCond.intervalOneDur(ii)*tact.NIdaqRate)) = 1;
            
            base    = 1 + (sin(-pi/2 + (2*pi*stim.carrierFreq * ...
                       linspace(0, tact.signalDuration-(1/tact.NIdaqRate), tact.samplPerPulse))));
            base    = base/(max(base)/2);
       
            pulse   = base .* stimOn;
            
        % Two pulse condition:
        elseif output.allCond.tapConditions(ii) == 2
            % create sin wave ranging from 0 to 2 (max output allowed with VTS)
            % shift sinusoid by pi/2 so that signal starts at 0
            stimOn  = zeros(1,tact.samplPerPulse);
            stimOn(1:round(output.allCond.intervalOneDur(ii)*tact.NIdaqRate)) = 1;
            
            stimOn(round((output.allCond.intervalOneDur(ii)+output.allCond.isiDur(ii))*tact.NIdaqRate + 1):...
                round((output.allCond.intervalOneDur(ii)+output.allCond.isiDur(ii)+output.allCond.intervalTwoDur(ii))*tact.NIdaqRate)) = 1;
   
            base    = 1 + (sin(-pi/2 + (2*pi*stim.carrierFreq * ...
                       linspace(0, tact.signalDuration-(1/tact.NIdaqRate), tact.samplPerPulse))));
            base    = base/(max(base)/2);
       
            pulse   = base .* stimOn;
            
        end
        tact.allPulses(ii,:)    = pulse;
        tact.allPulses(ii,end)  = 0;

    end
end


%% Open window
white           = [255 255 255];
red             = [205 0 0];
green           = [0 205 0];
blue            = [0 0 255];
orange          = [255 165 0];
black           = [0 0 0];
[window, rect]  = PsychImaging('OpenWindow', w.whichScreen, stim.meanLum);
Screen('BlendFunction',window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% find some useful coordinates:
xCenter = rect(3)/2;
yCenter = rect(4)/2;

% CLUT - force linear CLUT with ProPIXX
if Scan > 0 && whichOS == 1 
    w.OriginalCLUT = Screen('ReadNormalizedGammaTable', window);
    Screen('LoadNormalizedGammaTable', window, linspace(0,1,256)'*ones(1,3));
end
w.OriginalCLUT = Screen('ReadNormalizedGammaTable', window);
Screen('LoadNormalizedGammaTable', window, linspace(0,1,256)'*ones(1,3));

w.monFlipInterval = Screen('GetFlipInterval', window);

% Query maximum useable priorityLevel on this system:
priorityLevel   = MaxPriority(window);
Priority(priorityLevel);
HideCursor;

Screen('TextStyle', window, 0);
Screen('TextSize', window, stim.textSize);

LoadText = 'Creating tactile stimuli ...';
DrawFormattedText(window, LoadText, 'center', 'center', white);
Screen('Flip', window);

%% Initialize session and parameters
if whichOS == 2 % Can only present tactile stimuli on windows
    NiDaq           = daq.createSession('ni'); % daq.createSession('ni')
    NiDaq.Rate      = tact.NIdaqRate;

    % add analog output channels to the session
    % and create handles
    for dd = 1:numel(tact.NIdaqNames)    
        for ii = 0:(tact.noAnalogCh(dd) - 1)

            stimName    = sprintf('ao%d', ii);
            addAnalogOutputChannel(NiDaq, tact.NIdaqNames{dd}, stimName, 'Voltage');

        end
    end
    
    % Create handle
    aoCh(1)         = NiDaq.Channels(1);
    % initialize current output matrix
    currentOutput   =  zeros(numel(tact.NIdaqNames)*10, 100);
    % add pulse at current output channel to output matrix
    currentOutput(1,1:100) = tact.allPulses(1,1:100);

    %%% Run commands once before real trial loop
    % Configure handles (rate, number of scans)
    NI_DAQmxCfgSampClkTiming(aoCh(1).TaskHandle, NiDaq.Rate, size(currentOutput', 1));
    % queue output data
    NI_DAQmxWriteAnalogF64(aoCh(1).TaskHandle, currentOutput(1:tact.totalAnalogCh,:));
    % start the task of outputting either signal
    NI_DAQmxStartTask(aoCh(1).TaskHandle);
    % wait until signal generation is finished
    NI_DAQmxWaitUntilTaskDone(aoCh(1).TaskHandle, 10);
    % Need to stop the task
    NI_DAQmxStopTask(aoCh(1).TaskHandle);

end

Screen('FillOval', window, white, CenterRectOnPoint([0 0 stim.fix_point  stim.fix_point ], xCenter, yCenter));
Screen('Flip', window);

%% Eye link setup
if eyeTrackON == 1
    [el, edf_filename] = eyeTrackingOn(window, output.eyeTrackName, rect, stim.ppd);
end

%% Start Experiment
% wait for trigger
fixColor = white;

Screen('FillOval', window, fixColor, CenterRectOnPoint([0 0 stim.fix_point  stim.fix_point ], xCenter, yCenter));
DrawFormattedText(window, '~', stim.ppd, stim.ppd, white, stim.meanLum);
Screen('Flip', window);

% Create a queue which records all keypresses throughout the experiment - except the trigger key
keylist = ones(1,256);                                                      % keys for KbQueueCreate
keylist(triggerKey) = 0;
keylist(KbName('5')) = 0;

fprintf('Waiting for trigger... \n')
KbQueueRelease()

% Wait for scanner trigger or mouse click
if Scan > 0 && ~debugMode
    KbTriggerWait(triggerKey, deviceNumberTrigger);
else
    GetClicks;
end
Screen('FillOval', window, fixColor, CenterRectOnPoint([0 0 stim.fix_point stim.fix_point], xCenter, yCenter));
Screen('Flip', window);

PsychHID('KbQueueCreate', deviceNumber, keylist);

fprintf('Trigger detected! \n')

%% Start recording eye link
if eyeTrackON == 1
    [status, el] = eyeTrackingRecord(el, rect, stim.ppd);
end

%% Initialize some variables
stimIndex       = 0;
stimOn          = false;
tactStart       = false;

StartTime       = GetSecs;
next            = StartTime;
nextStim        = StartTime;
end_loop        = StartTime + t.runDur;
IPItime         = StartTime;
nextTarget      = StartTime + t.fixChanges(1);
targetCount     = 1;

output.realTime = GetSecs - StartTime;
output.AllTimes = NaN(length(t.stimType),2);
output.tactStart= [];
output.tactTime = [];
output.tactStop = [];

% start recording responses
PsychHID('KbQueueStart', deviceNumber);

% Start trial loop 
while 1
    
    % which condition should be presented?
    if GetSecs >= next
        stimIndex   = stimIndex+1;
        if stimIndex > size(output.allEvents,1)
            break;
        end
        next            = next + output.allEvents(stimIndex,2);
        output.realTime = [output.realTime next-StartTime];
          
        % Send messages to eyelink to keep track of events
        if eyeTrackON == 1
            if ~output.allEvents(stimIndex, 3) == 0
                Eyelink('Message', conditionNames(output.allEvents(stimIndex, 3)));
            else
                Eyelink('Message', 'Blank');
            end
        end
        
        % No tactile stim during blanks:
        if t.stimType(stimIndex) == 0 || strcmp(conditionNames(t.stimType(stimIndex)), 'BLANK_PULSE')
            
            output.AllTimes(stimIndex,:) = [(GetSecs - StartTime) t.stimType(stimIndex)];
            trialPulse      = [];
            
        % Present current temporal condition: 
        else           
            
            output.AllTimes(stimIndex,:) = [(GetSecs - StartTime) t.stimType(stimIndex)];
            
            if whichOS == 2 % only on windows
                % first 5 channels are empty - remaining 15 are used
                trialPulse      = cat(1, zeros(5,tact.samplPerPulse), ...
                                repmat(tact.allPulses(output.allEvents(stimIndex, 3),:), [tact.totalAnalogCh, 1]));
            else
                trialPulse = [];
            end
        end
    end
    
    % see whether its time to present the tactile stimulus
    if GetSecs >= nextStim && ~isempty(trialPulse) && ~stimOn
        output.tactStart = [output.tactStart GetSecs-StartTime];
        stimOn          = true; 
        tactStart       = true;
        nextStim        = GetSecs + output.allEvents(stimIndex,2);

        
        % create handle
        aoTaskHandle(1) = aoCh(1).TaskHandle;       
        % Configure handles
        NI_DAQmxCfgSampClkTiming(aoTaskHandle(1), NiDaq.Rate, tact.samplPerPulse);    
        % queue output data
        NI_DAQmxWriteAnalogF64(aoTaskHandle(1), trialPulse');
        % start the task of outputting the signal
        NI_DAQmxStartTask(aoTaskHandle(1));

        output.tactTime = [output.tactTime GetSecs-StartTime-output.realTime(end-1)];
    end
    
    % Stop the tactile stimulation
    if GetSecs >= nextStim && stimOn        
        % stop the task
        NI_DAQmxStopTask(aoTaskHandle(1));
        output.tactStop = [output.tactStop GetSecs-StartTime-output.tactStart(end)];
        stimOn          = false;
    end
    
    % Prepare drawing of visual stimuli
    if GetSecs >= nextTarget
                     
        if range(fixColor) == 0 % current color is white
            fixColor = red;
        else
            fixColor = white;
        end

        if targetCount <= t.totalChanges
            Screen('FillOval', window, fixColor, CenterRectOnPoint([0 0 stim.fix_point stim.fix_point], xCenter, yCenter));
            Screen('Flip', window);
            nextTarget  = t.fixChanges(targetCount) + StartTime;
            targetCount = targetCount+1;
        else
            nextTarget = t.runDur + StartTime;
        end
    end
     
    if GetSecs >= end_loop
        break;
    end
    
end

% End of experiment
output.totalDur = GetSecs - StartTime;

% Get count response
output.respOptions =  Shuffle(cat(2, t.totalChanges, randsample(t.numFixChanges(t.numFixChanges ~= t.totalChanges), 3)));
countText = sprintf('How many fixation changes? \n\n %d   %d   %d   %d', output.respOptions);
DrawFormattedText(window, countText, 'center', round(yCenter-stim.fix_point*3), white);
Screen('Flip', window);

%% End eyetracking
if eyeTrackON == 1
    % reset so tracker uses defaults calibration for other experiments
    Eyelink('command', 'generate_default_targets = yes')
    Eyelink('Command', 'set_idle_mode');
    Eyelink('command', ['screen_pixel_coords' num2str(w.ScreenSizePixels)])% ScreenSizePixels = [0 0 1024 768];
    
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    status = Eyelink('ReceiveFile', edf_filename);
    Eyelink('ShutDown')
    fprintf('ReceiveFile status %d\n', status);
end

% get response
while true

    [pressed, firstpress, ~, ~] = PsychHID('KbQueueCheck', deviceNumber);

    if pressed
        % Look at the last response
        [m, indice]                 = max(firstpress);
        
        if ismember(indice, keyPressNumbers)        
            break
        end
    end       

end
  
output.response = output.respOptions(keyPressNumbers == indice);
output.respAcc  = output.response == t.totalChanges;

WaitSecs(1);

%% Clean up screen and tactile stim
if whichOS == 2
    release(NiDaq);
end
Screen('LoadNormalizedGammaTable', window, w.OriginalCLUT);
Screen('CloseAll');
PsychHID('KbQueueStop');
KbQueueRelease()

ShowCursor;
Priority(0);


%% Save data ...
TheData(runNum).w       = w;
TheData(runNum).t       = t;
TheData(runNum).tact    = tact;
TheData(runNum).stim    = stim;
TheData(runNum).output  = output;

save(saveFileName, 'TheData');

