function [numChannels] = NI_DAQmxGetReadNumChans( taskHandle )
% Wrapper function for DAQmxGetReadNumChans
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver

[status, numChannels] = daq.ni.NIDAQmx.DAQmxGetReadNumChans(...
    taskHandle,...   % task handle
    uint32(0));      % numChans

daq.ni.utility.throwOrWarnOnStatus(status);
end

