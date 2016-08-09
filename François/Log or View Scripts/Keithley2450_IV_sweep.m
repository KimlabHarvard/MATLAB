function [currentList voltageList] = Keithley2450_IV_sweep(I_min,I_max,Istep,pauseTime)
    %KEITHLEY2450_IV_SWEEP Sweep IV, source I and sense V
    %always ramps the sample current
    
    %turn keithley to 4 point mode, source current and measure voltage
    close all;
    fclose all;
    %clear all;
    
    %curr_min=-3e-6;
    %curr_max=3e-6;
    %stepSize=1e-8;
    %pauseTime=0.1;
    
    %currentList=0;
    
    if(I_min<I_max)
        mystep=abs(Istep);
    else
        mystep=-1*abs(Istep);
    end
    
    currentList=(I_min:mystep:I_max);
    
    voltageList=zeros(1,length(currentList))/0;
    
    thomas=deviceDrivers.Keithley2450();
    thomas.connect('26');
    
    %check to make sure the modes are set properly
    
    senseMode=thomas.sense_mode;
    if(~strcmp(senseMode,'VOLT:DC'))
        disp(strcat('Error: Incorrect sense mode is ',senseMode));
        return
    end
    
    sourceMode=thomas.source_mode;
    if(~strcmp(sourceMode,'CURR'))
        disp(strcat('Error: Incorrect source mode is ',sourceMode));
        return
    end
    
    rampToBiasCurrent(currentList(1));
    
    figure(1);
    
    for(i=1:length(currentList))
        thomas.sourceCurrent=currentList(i);
        pause(pauseTime);
        voltageList(i)=thomas.senseVoltage;
        change_to_figure(1);
        plot(currentList(1:i),voltageList(1:i),'.');
    end
    
    function rampToBiasCurrent(curr)
        currentCurrent=thomas.sourceCurrent;
        if(curr>currentCurrent) %going up in voltage
            currentCurrent=currentCurrent+Istep;
            while(currentCurrent<curr)
                thomas.sourceCurrent=currentCurrent;
                pause(pauseTime);
                currentCurrent=currentCurrent+Istep;
            end
            thomas.current=curr;
            pause(pauseTime);
        else %going down in voltage
            currentCurrent=currentCurrent-Istep;
            while(currentCurrent>curr)
                thomas.sourceCurrent=currentCurrent;
                pause(pauseTime);
                currentCurrent=currentCurrent-Istep;
            end
            thomas.sourceCurrent=curr;
            pause(pauseTime);
        end
    end
    
end

