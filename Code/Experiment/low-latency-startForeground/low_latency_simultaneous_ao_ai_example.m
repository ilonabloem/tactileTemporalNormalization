%% Low-latency finite duration simultaneous signal generation and acquisition
% This example shows how to do low-latency finite duration simultaneous 
% signal generation and acquisition using the (undocumented) MEX 
% "projection layer" for NI-DAQmx driver, available in Data Acquisition 
% Toolbox R2014b.

%% Requires attached MATLAB functions (wrappers for NI-DAQmx driver functions)
% 
% * NI_DAQmxCfgSampClkTiming.m
% * NI_DAQmxStartTask.m
% * NI_DAQmxStopTask.m
% * NI_DAQmxWriteAnalogF64.m
% * NI_DAQmxWaitUntilTaskDone.m
% * NI_DAQmxGetReadNumChans.m
% * NI_DAQmxReadAnalogF64.m
% * NI_DAQmxGetStartTrigTerm.m
% * NI_DAQmxCfgDigEdgeStartTrig.m

%% Session configuration
s = daq.createSession('ni');
aoCh(1) = addAnalogOutputChannel(s, 'Dev7', 'ao0', 'Voltage');
aoCh(2) = addAnalogOutputChannel(s, 'Dev7', 'ao1', 'Voltage');
aoCh(1).Range = [-10 10];
aoCh(2).Range = [-10 10];

aiCh(1) = s.addAnalogInputChannel('Dev7', 'ai0', 'Voltage');
aiCh(2) = s.addAnalogInputChannel('Dev7', 'ai1', 'Voltage');
aiCh(1).Range = [-10 10];
aiCh(2).Range = [-10 10];
aiCh(1).TerminalConfig = 'SingleEnded';
aiCh(2).TerminalConfig = 'SingleEnded';

% Set session rate
s.Rate = 100E+3;

% Synthesize output data
outputDuration = 2;
t = linspace(0, outputDuration, outputDuration * s.Rate)';
outputData1 = sin(100*2*pi*t);
outputData2 = cos(100*2*pi*t);
outputData = [outputData1, outputData2];


numScans = size(outputData, 1);

% TaskHandle property is available (undocumented) in MATLAB R2014b.
% Assuming all analog input channels belong to the same NI-DAQmx task
% Assuming all analog output channels belong to the same NI-DAQmx task
aoTaskHandle = aoCh(1).TaskHandle;
aiTaskHandle = aiCh(1).TaskHandle;


%% Finite duration signal generation and acquisition

% Past this line, do not modify session configuration or properties,
% and do not execute prepare(s), startForeground(s), startBackground(s)

% Configure finite duration generation (rate, number of scans)
NI_DAQmxCfgSampClkTiming(aoTaskHandle, s.Rate, numScans);

% Configure finite duration acquisition (rate, number of scans)
NI_DAQmxCfgSampClkTiming(aiTaskHandle, s.Rate, numScans);

% Required for synchronization of output and input channels
aiStartTrigTerm = NI_DAQmxGetStartTrigTerm(aiTaskHandle);
NI_DAQmxCfgDigEdgeStartTrig(aoTaskHandle, aiStartTrigTerm);

tic
% Queue output data
NI_DAQmxWriteAnalogF64(aoTaskHandle, outputData);

% Perform a finite duration acquisition operation
NI_DAQmxStartTask(aoTaskHandle);
NI_DAQmxStartTask(aiTaskHandle);

inputData = NI_DAQmxReadAnalogF64(aiTaskHandle, numScans, 10);

% Wait until signal generation is finished
NI_DAQmxWaitUntilTaskDone(aoTaskHandle, 10);
NI_DAQmxStopTask(aoTaskHandle);
NI_DAQmxStopTask(aiTaskHandle);

toc
%% Process and display data

% If data grouped by channel in 1D array, reshape data array to 2D
numChannels = NI_DAQmxGetReadNumChans(aiTaskHandle);
inputData = reshape(inputData, [], numChannels);

figure;
plot(inputData);


%% Clean up

delete(s)
clear s


