function [aiData] = NI_DAQmxReadAnalogF64( taskHandle, numScans, timeout )
% Wrapper function for DAQmxReadAnalogF64
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver

numChannels = NI_DAQmxGetReadNumChans(taskHandle);
totalSamples = uint32(numScans) * numChannels;

[status, aiData, ~, ~] =...
    daq.ni.NIDAQmx.DAQmxReadAnalogF64(...
    taskHandle,...                                      % task handle
    int32(numScans),...                                 % numSampsPerChan 
    double(timeout),...                                 % timeout in seconds
    uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByChannel),... % fillMode
    zeros(1, totalSamples),...                          % readArray
    uint32(totalSamples),...                            % arraySizeInSamps
    int32(0),...                                        % sampsPerChanRead
    uint32(0));                                         % reserved

daq.ni.utility.throwOrWarnOnStatus(status);
end

