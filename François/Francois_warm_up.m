function [ output_args ] = Francois_warm_up( input_args )
    %FRANCOIS_WARM_UP warm up the fridge at 2K/min and log heater and temperature
    
    setpointList=[2 5 10:10:60 80:20:300 315];
    rampRate=2; %K/min
    
    clear temp time heater;
    close all;
    fclose all;
    
    TC = FrancoisLakeShore335();
    TC.connect('12');
    
    startingTemp=TC.temperatureA;
    TC.rampRate1=rampRate;
    
    startTime=clock;
    
    %find where we are in the setpoint list
    for(i=1:length(setpointList))
        if(setpointList(i)>startingTemp)
            setpointCount=i;
            TC.setPoint1=setpointList(setpointCount);
            break;
        end
    end
    
    figure(1);
    clf;
    plot(0,0);
    xlabel('time');
    ylabel('temp (K)');
    
    figure(2);
    clf;
    plot(0,0);
    xlabel('time');
    ylabel('heater');
    
    drawnow;
    
    pause on;
    
    count=1;
    
    while(true)
        temp(count)=TC.temperatureA;
        time(count)=etime(clock, startTime);
        heater(count)=TC.heater1;
        
        %once we reach a temp setpoint, go to the next temp setpoint
        if(temp(count)>setpointList(setpointCount) && setpointCount<length(setpointList))
            setpointCount=setpointCount+1;
            TC.setPoint1=setpointList(setpointCount);
        end
        
        change_to_figure(1);
        plot(time,temp);
        xlabel('time');
    ylabel('temp (K)');
        
        change_to_figure(2);
        plot(time,heater);
           xlabel('time');
    ylabel('heater');
        
        count=count+1;
        
        pause(1);
    end
    
end

