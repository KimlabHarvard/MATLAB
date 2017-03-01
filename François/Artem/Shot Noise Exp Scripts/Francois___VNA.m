function Francois___VNA(UniqueName, start_dir)
    %FRANCOI___VNA Summary of this function goes here
    %   Detailed explanation goes here
    StartTime=clock;
        FileName = strcat(datestr(StartTime, 'yyyy-mm-dd_HH-MM-SS'),'_Francois___VNA_',UniqueName,'.mat');
    
    VNA = deviceDrivers.AgilentE8363C();
    VNA.connect('140.247.189.204');
    VNA.trigger_source='immediate';
    
    VNA_data.freqList=VNA.getX;
    VNA.trigger;
    VNA_data.VNA_trace=VNA.getSingleTrace;
    
    plot(VNA_data.freqList,abs(VNA_data.VNA_trace));
    xlabel('f(Hz)');
    ylabel('|Sij|');
    
    save(fullfile(start_dir, FileName),'VNA_data');
    
end

