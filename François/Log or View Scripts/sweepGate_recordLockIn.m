function sweepGate_recordLockIn()

    clear temp StartTime start_dir CoolLogData;
    close all;
    fclose all;

    %UniqueName='Al Tunnel Junction current sweep base';
    UniqueName='gatesweep_300K';
    start_dir = 'C:\Users\Artem\My Documents\Data\Graphene Shot Noise\';
    StartTime = clock;
    FileName = strcat('_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');
   

    sr830=deviceDrivers.SRS830();
    sr830.connect('2');
    
    sr830.timeConstant=1;
    timeConst=sr830.timeConstant;

    gate=deviceDrivers.Keithley2450();
    gate.connect('26');
    gate.source_mode='voltage';
    
    gateVoltageWaitTime=1;
    gateVoltageStep=0.01;
    
    data=struct('gateVoltage',0,'lockIn',0);

    
    myfig=plot(0,0);
    xlabel('gate voltage (v)');
    ylabel('sample resistance (Ohms)');
    %gateList= [-0.9 -0.5 0];
    %gateList=[-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.45 -0.4 -0.35 -0.325 -0.3 -0.275 -0.25 -0.24 -0.23 -0.22 -0.21 -0.20 -0.19 -0.18 -0.17 -0.16 -0.15 -0.125 -0.1 -0.075 -.05 0 .05 .1 .2 .3 .4 .5 .6 .7 .8 .9 1];
    gateList=0;
    %gateList=[1:-.1:-.2, -0.2:-.01:-0.5 -0.5:-0.1:-1];
    
    for i=1:length(gateList)
        rampToGateVoltage(gateList(i));
        pause(3.5*timeConst);
        data.lockIn(i)=sr830.X;
        data.gateVoltage(i)=gateList(i);
        set(myfig,'XData',data.gateVoltage,'YData',data.lockIn*1e8);
        drawnow;
        save(fullfile(start_dir, FileName),'data')
    end

    function rampToGateVoltage(v)
        currentVoltage=gate.voltage;
        if(v>currentVoltage) %going up in voltage
            currentVoltage=currentVoltage+gateVoltageStep;
            while(currentVoltage<v)
                gate.voltage=currentVoltage;
                pause(gateVoltageWaitTime);
                currentVoltage=currentVoltage+gateVoltageStep;
            end
            gate.voltage=v;
            pause(gateVoltageWaitTime);
        else %going down in voltage
            currentVoltage=currentVoltage-gateVoltageStep;
            while(currentVoltage>v)
                gate.voltage=currentVoltage;
                pause(gateVoltageWaitTime);
                currentVoltage=currentVoltage-gateVoltageStep;
            end
            gate.voltage=v;
            pause(gateVoltageWaitTime);
        end
    end
end