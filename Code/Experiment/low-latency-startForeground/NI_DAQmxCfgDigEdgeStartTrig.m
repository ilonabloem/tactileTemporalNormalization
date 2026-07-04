function NI_DAQmxCfgDigEdgeStartTrig( taskHandle, triggerSource )
% Wrapper function for DAQmxCfgDigEdgeStartTrig
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver

[status] = daq.ni.NIDAQmx.DAQmxCfgDigEdgeStartTrig(...
    taskHandle,...                                % task handle
    triggerSource, ...                            % triggerSource
    int32(daq.ni.NIDAQmx.DAQmx_Val_Rising));      % bufferSize

daq.ni.utility.throwOrWarnOnStatus(status);
end

