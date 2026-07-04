function NI_DAQmxStartTask( taskHandle )
% Wrapper function for DAQmxStartTask
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver

[status] = daq.ni.NIDAQmx.DAQmxStartTask(...
            taskHandle);   % task handle

daq.ni.utility.throwOrWarnOnStatus(status);
end

