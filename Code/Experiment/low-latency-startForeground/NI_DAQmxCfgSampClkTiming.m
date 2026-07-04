function  NI_DAQmxCfgSampClkTiming( taskHandle, rate, numScans )
% Wrapper function for DAQmxCfgSampClkTiming
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver

[status] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming(...
        taskHandle,...                              % taskHandle
        'OnboardClock',...                          % clockSource
        double(rate),...                            % rate
        daq.ni.NIDAQmx.DAQmx_Val_Rising,...         % activeEdge
        daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps,...    % sampleMode
        uint64(numScans));                          % sampsPerChanToAcquire
   
daq.ni.utility.throwOrWarnOnStatus(status);
end