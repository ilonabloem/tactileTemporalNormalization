%% Low-latency finite duration finite duration signal generation
% This example shows how to do low-latency finite duration signal
% generation using the (undocumented) MEX "projection layer" for 
% NI-DAQmx driver, available in Data Acquisition Toolbox R2014b.

%% Requires attached MATLAB functions (wrappers for NI-DAQmx driver functions)
% 
% * NI_DAQmxCfgSampClkTiming.m
% * NI_DAQmxStartTask.m
% * NI_DAQmxStopTask.m
% * NI_DAQmxWriteAnalogF64.m
% * NI_DAQmxWaitUntilTaskDone.m

%% Session configuration
s = daq.createSession('ni');
aoCh(1) = addAnalogOutputChannel(s, 'Dev7', 'ao0', 'Voltage');
aoCh(2) = addAnalogOutputChannel(s, 'Dev7', 'ao1', 'Voltage');
aoCh(1).Range = [-10 10];
aoCh(2).Range = [-10 10];

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
aoTaskHandle = aoCh(1).TaskHandle;

%% Finite duration signal generation

% Past this line, do not modify session configuration or properties,
% and do not execute prepare(s), startForeground(s), startBackground(s)

% Configure finite duration acquisition (rate, number of scans)
NI_DAQmxCfgSampClkTiming(aoTaskHandle, s.Rate, numScans);

tic

% Queue output data
NI_DAQmxWriteAnalogF64(aoTaskHandle, outputData);

% Perform a finite duration acquisition operation
NI_DAQmxStartTask(aoTaskHandle);

% Wait until signal generation is finished
NI_DAQmxWaitUntilTaskDone(aoTaskHandle, 10);

NI_DAQmxStopTask(aoTaskHandle);

toc

%% Clean up

delete(s)
clear s


