function NI_DAQmxStopTask( taskHandle )
% Wrapper function for DAQmxStopTask
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver

[status] = daq.ni.NIDAQmx.DAQmxStopTask(...
            taskHandle);   % task handle

daq.ni.utility.throwOrWarnOnStatus(status);
end

