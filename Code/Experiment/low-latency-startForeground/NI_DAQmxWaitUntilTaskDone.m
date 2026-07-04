function NI_DAQmxWaitUntilTaskDone( taskHandle, timeToWait )
% Wrapper function for DAQmxWaitUntilTaskDone
% Using low level NI-DAQmx driver calls via the MEX "projection layer"
% Refer to "NI-DAQmx C Reference Help" file installed with the NI-DAQmx driver



[status] = daq.ni.NIDAQmx.DAQmxWaitUntilTaskDone(...
    taskHandle, ...          % taskHandle
    double(timeToWait));     % timeToWait

daq.ni.utility.throwOrWarnOnStatus(status);
end

