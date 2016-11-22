%sweep temp and gate, measure DC johnsn noise

function Francois_T_Vg___R_NDCAnalog(UniqueName, start_dir, numberOfCycles, tempWaitTime, temperatureWindow, tempRampRate, bigResistor, leadResistance, gateVoltageList, tempList, lockInTimeConstant)
    clear temp StartTime CoolLogData gate;
    close all;
    fclose all;
    
    figure(1992);
   
    cycleTime=3.36;
    
    %resistanceMeasExcitationCurrentACVrms=1e-6; %1 microAmp;
    gateVoltageStep=0.01;
    gateVoltageWaitTime=.3;

    

    StartTime = clock;
    FileName = strcat('Francois_T_Vg___R_NDCAnalog_', datestr(StartTime, 'yyyy-mm-dd_HH-MM-SS'),'_',UniqueName,'.mat');
    
    dmm=deviceDrivers.Keysight34401A();
    dmm.connect('6');
    
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
    
  
    estTime=length(tempList)*length(gateVoltageList)*numberOfCycles*cycleTime/60/60+length(tempList)*tempWaitTime/60/60+(max(tempList)-min(tempList))/tempRampRate/60
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
    
    

    calData=struct('time',0,'myClock',0,'temp',0,'johnsonNoise',0,'johnsonNoiseErr',0,...
        'tempList',0,'gateVoltageList',0,...
        'resistance',0,'excitationCurrent',0,'leadResistance',0);
    
    %initialize everything to NaN so there aren't any zeros when plotting!
    %data3D=zeros(length(tempList),length(gateVoltageList),length(lowBiasVoltageList))/0;
    data2D=zeros(length(tempList),length(gateVoltageList))/0;
    calData.time=data2D;
    calData.myClock=zeros(length(tempList),length(gateVoltageList),6)/0;
    calData.temp=data2D;
    
    calData.resistance=data2D;
    calData.excitationCurrent=data2D;
    calData.dP_P_by_dT=data2D;
    calData.johnsonNoise=data2D;
    calData.johnsonNoiseErr=data2D;
    calData.leadResistance=leadResistance;
    
    calData.gateVoltageList=gateVoltageList;
    calData.tempList=tempList;

    startTime=clock;
    
    figure(4);
    clf;
    hold on;
    xlabel('gate voltage (V)');
    ylabel('Resistance (Ohms)');
    grid on;
    
    figure(2);
    clf;
    hold on;
    xlabel('T (K)');
    ylabel('Johnson noise on power diode (V)');
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
        
        %measure the johnson noise now
        [calData.johnsonNoise(i,j), calData.johnsonNoiseErr(i,j)]=measureJohnsonNoise(numberOfCycles);
        calData.time=etime(clock,startTime);
        calData.myClock(i,j,:)=clock;
        
        
        
        %wait for lock-in values to stabilize if needed
        time2=etime(clock,startTime2);
        if(time2<10*lockInTimeConstant)
            pause(10*lockInTimeConstant-time2);
        end
        
        %measure resistance, record it
        myResistance=measureLockInResistance();
        calData.resistance(i,j)=myResistance;
        calData.excitationCurrent(i,j)=topLockIn.sineAmp/(myResistance+bigResistor)
        
        change_to_figure(4);
        plot(gateVoltageList,calData.resistance','.-');
        
        
        change_to_figure(2);
        clf
        errorbar(tempList(1:i),calData.johnsonNoise(1:i,:),calData.johnsonNoiseErr(1:i,:));

        save(fullfile(start_dir, FileName),'calData');

    %goto next gate voltage
    end 
    %goto next temp, end gate voltage for loop
end %end temp for loop
%end experiment

   
    function [noisePower, noisePowerErr] = measureJohnsonNoise(numCycles)
        
        noiseData=zeros(1,numCycles);
        
        tic
        for n=1:numCycles
            noiseData(n)=dmm.value;
        end
        toc
        noisePower=mean(noiseData);
        noisePowerErr=std(noiseData)/numCycles;
    end

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
        topLockIn.autoSens();
        topVoltage=topLockIn.sineAmp;
        bottomVoltage=topLockIn.R;
        res=bigResistor*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
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