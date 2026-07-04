function NI_DAQmxWriteDigital( taskHandle, outputData )
% Wrapper function for DAQmxWriteAnalogF64
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver

numScans = size(outputData, 1);
outputData = outputData(:);

[status, ~, ~] = daq.ni.NIDAQmx.DAQmxWriteDigitalLines(...
    taskHandle, ...                                          % taskHandle
    int32(numScans), ...                                     % numSampsPerChan
    uint32(0), ...                                           % autoStart
    10, ...                                                  % timeout
    uint32(daq.ni.NIDAQmx.DAQmx_Val_GroupByChannel), ...     % dataLayout
    uint8(outputData), ...                                          % writeArray
    int32(0),...                                             % sampsPerChanWritten
    uint32(0));                                              % reserved

daq.ni.utility.throwOrWarnOnStatus(status);
end

