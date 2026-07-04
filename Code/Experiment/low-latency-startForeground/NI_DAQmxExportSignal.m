function NI_DAQmxExportSignal(taskHandle, line)
out = daq.ni.NIDAQmx.DAQmxExportSignal(taskHandle, daq.ni.NIDAQmx.DAQmx_Val_StartTrigger, line);

end