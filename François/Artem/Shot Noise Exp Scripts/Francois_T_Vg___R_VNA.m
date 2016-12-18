function Francois_T_Vg___R_VNA(UniqueName, start_dir, tempWaitTime, temperatureWindow, tempRampRate, resistance, leadResistance, gateVoltageList, tempList, lockInTimeConstant)
    clear temp StartTime CoolLogData gate;
    close all;
    fclose all;
   
    cycleTime=3.3;
    
    %resistanceMeasExcitationCurrentACVrms=1e-6; %1 microAmp;
    gateVoltageStep=0.01;
    gateVoltageWaitTime=.3;

    

    StartTime = clock;
    FileName = strcat('JNCal_measure_gain_', datestr(StartTime, 'yyyy-mm-dd_HH-MM-SS'),'_',UniqueName,'.mat');
    
    VNA = deviceDrivers.AgilentE8363C();
    VNA.connect('140.247.189.204');
    VNA.trigger_source='manual';
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');
    tempController.rampRate1=tempRampRate;
    
    gateController=deviceDrivers.YokoGS200();
    gateController.connect('16');
    assert(strcmp(gateController.mode,'VOLT'),'wrong gate source mode');
    %gateController.value=0;
    %gateController.output=1;
    
    
    topLockIn=deviceDrivers.SRS830();
    topLockIn.connect('1');
    topLockIn.timeConstant=lockInTimeConstant;
    %topLockIn.sineAmp=resistanceMeasExcitationCurrentACVrms;

    
    
    
  
    %estTime=length(tempList)*length(gateVoltageList)*numberOfCycles*cycleTime/60/60+length(tempList)*tempWaitTime/60/60+(max(tempList)-min(tempList))/tempRampRate/60
    %time (s)-elapsed time since starting the script
    %myClock is an 6-element array of clock
    %temp (K)-the temperature
    %
    %
    %tempList
    %gateVoltageList
    % resistance (Ohms) the sample resistance
    %johnsonNoise the DC-measured noise at zero current
    %johnsonNoiseErr
    
    

    VNA_data=struct('time',0,'myClock',0,'temp',0,'freqList',0,'VNA_trace',0,...
        'tempList',0,'gateVoltageList',0,...
        'resistance',0);
    
    %initialize everything to NaN so there aren't any zeros when plotting!
    %data3D=zeros(length(tempList),length(gateVoltageList),length(lowBiasVoltageList))/0;
    data2D=zeros(length(tempList),length(gateVoltageList))/0;
    VNA_data.time=data2D;
    VNA_data.myClock=data2D;
    VNA_data.temp=data2D;
    VNA_data.freqList=VNA.getX;
    VNA_data.VNA_trace=zeros(length(tempList),length(gateVoltageList),length(VNA_data.freqList))/0;
    
    VNA_data.resistance=data2D;
    
    VNA_data.gateVoltageList=gateVoltageList;
    VNA_data.tempList=tempList;
    
    

    
    figure(4);
    clf;
    hold on;
    xlabel('gate voltage (V)');
    ylabel('Resistance (Ohms)');
    grid on;
    
    figure(2);
    clf;
    hold on;
    xlabel('f (Hz)');
    ylabel('S22');
    grid on;
    
%iterate through the temperatures    
for i=1:length(tempList)   
    %set the temperature and wait until it stabilizes
    setTemperature(tempList(i));
  
    %iterate through the gate voltages
    for j=1:length(gateVoltageList)
        fprintf('setting gate voltage to %g, at %g Kelvin...',gateVoltageList(j),tempList(i));
        rampToGateVoltage(gateVoltageList(j));
        fprintf('done setting gate voltage\n');
        
        startTime2=clock;
        
        %measure the VNA
        VNA.trigger;
        VNA_data.VNA_trace(i,j,:)=VNA.getSingleTrace;
        
        
        
        
        %wait for lock-in values to stabilize if needed
        time2=etime(clock,startTime2);
        if(time2<10*lockInTimeConstant)
            pause(10*lockInTimeConstant-time2);
        end
        
        %measure resistance, record it
        myResistance=measureLockInResistance();
        VNA_data.resistance(i,j)=myResistance;
        
        change_to_figure(4);
        plot(gateVoltageList,VNA_data.resistance','.-');
        
        
        change_to_figure(2);
        plot(VNA_data.freqList,abs(squeeze(VNA_data.VNA_trace(i,j,:))))
        grid on;
        title(sprintf('VNA Trace at %g K, and %g gate',tempList(i),gateVoltageList(j)));

        save(fullfile(start_dir, FileName),'VNA_data');

    %goto next gate voltage
    end 
    %goto next temp, end gate voltage for loop
end %end temp for loop
%end experiment

    %set temperature and wait for thermal stabilitzation
    function setTemperature(finalTemp)
        keeplooping=true;%can pause program and set this to true if needed
        startingTemp=tempController.temperatureA;
        tempController.setPoint1=finalTemp; 
        count=0;
        if(finalTemp>startingTemp)%we are warming
            fprintf('warming to %f K\n', finalTemp)
            while(keeplooping && tempController.temperatureA<finalTemp-temperatureWindow)
                if(mod(count,10)==0)
                    fprintf('current temp is %f K\n', tempController.temperatureA);
                end
                count=count+1;
                pause(1);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        else%we are cooling
            fprintf('cooling to %f K\n', finalTemp)
            while(keeplooping && tempController.temperatureA>finalTemp+temperatureWindow)
                if(mod(count,10)==0)
                    fprintf('current temp is %f K\n', tempController.temperatureA);
                end
                count=count+1;
                pause(1);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        end
        %if(i>1)
            pause(tempWaitTime);
        %end
    end

    function res=measureLockInResistance()
        %topLockIn.autoSens();
        topVoltage=topLockIn.sineAmp;
        bottomVoltage=topLockIn.R;
        res=resistance*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
    end

    function rampToGateVoltage(v)
        currentVoltage=gateController.value;
        if(v>currentVoltage) %going up in voltage
            currentVoltage=currentVoltage+gateVoltageStep;
            while(currentVoltage<v)
                gateController.value=currentVoltage;
                pause(gateVoltageWaitTime);
                currentVoltage=currentVoltage+gateVoltageStep;
            end
            gateController.value=v;
            pause(gateVoltageWaitTime);
        else %going down in voltage
            currentVoltage=currentVoltage-gateVoltageStep;
            while(currentVoltage>v)
                gateController.value=currentVoltage;
                pause(gateVoltageWaitTime);
                currentVoltage=currentVoltage-gateVoltageStep;
            end
            gateController.value=v;
            pause(gateVoltageWaitTime);
        end
    end

end

