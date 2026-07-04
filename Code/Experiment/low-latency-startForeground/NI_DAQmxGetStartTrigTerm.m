function [startTrigTerm] = NI_DAQmxGetStartTrigTerm( taskHandle )
% Wrapper function for DAQmxGetStartTrigTerm
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver

[status, startTrigTerm] = daq.ni.NIDAQmx.DAQmxGetStartTrigTerm(...
    taskHandle,...      % task handle
    blanks(1024), ...   % data
    uint32(1024));      % bufferSize

daq.ni.utility.throwOrWarnOnStatus(status);
end

