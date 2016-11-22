%sweep temp and gate, measure DC johnsn noise

function Francois_T_Vg___R_NACsquarewaveDigital(UniqueName, start_dir, numberOfSamples, numberOfAverages, numberOfCycles, tempWaitTime, temperatureWindow, tempRampRate, fftMask, resistance, leadResistance, range, gateVoltageList, tempList, lockInTimeConstant)
    clear temp StartTime start_dir CoolLogData gate;
    close all;
    fclose all;
    
    figure(1992);
   
    cycleTime=.013;
    
    %resistanceMeasExcitationCurrentACVrms=1e-6; %1 microAmp;
    gateVoltageStep=0.01;
    gateVoltageWaitTime=.3;

    

    StartTime = clock;
    FileName = strcat('JNCal_measure_gain_', datestr(StartTime, 'yyyy-mm-dd_HH-MM-SS'),'_',UniqueName,'.mat');
    
    k_B=1.38064852e-23;
    e=1.60217662e-19;
    
    digitizerCard = deviceDrivers.ATS850DriverPipelined(1,1);
    %digitizerCard.setTriggerDelay(50000); %1ms delay time
    digitizerCard.configureChannel('A', 'AC', range, 50);
    digitizerCard.configureChannel('B', 'DC', 5, 1000000);
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');
    tempController.rampRate1=tempRampRate;
    
    gateController=deviceDrivers.YokoGS200();
    gateController.connect('16');
    assert(strcmp(gateController.mode,'VOLT'),'wrong gate source mode');
    %gateController.value=0;
    %gateController.output=1;
    
    
    topLockIn=deviceDrivers.SRS830(); %measures the first component of 'square wave' AC voltage out of the switch into 10MOhm resistor
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
        'T_noise',0,'tempList',0,'gateVoltageList',0,...
        'resistance',0,'fftMask',0);
    
    %initialize everything to NaN so there aren't any zeros when plotting!
    %data3D=zeros(length(tempList),length(gateVoltageList),length(lowBiasVoltageList))/0;
    data2D=zeros(length(tempList),length(gateVoltageList))/0;
    calData.time=data2D;
    calData.myClock=data2D;
    calData.temp=data2D;
    
    calData.T_noise=data2D;
    calData.resistance=data2D;
    calData.dP_P_by_dT=data2D;
    calData.johnsonNoise=data2D;
    calData.johnsonNoiseErr=data2D;
    
    calData.gateVoltageList=gateVoltageList;
    calData.tempList=tempList;
    calData.fftMask=fftMask;

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
    ylabel('Johnson noise P_P0 (W)');
    grid on;
    
%iterate through the temperatures    
for i=1:length(tempList)   
    %set the temperature and wait until it stabilizes
    setTemperature(tempList(i));
  
    %iterate through the gate voltages
    for j=1:length(gateVoltageList)
        fprintf('setting gate voltage to %g, at %g Kelvin\n',gateVoltageList(j),tempList(i));
        rampToGateVoltage(gateVoltageList(j));
        
        startTime2=clock;
        
        %measure the johnson noise now
        calData.johnsonNoise(i,j)=-1;
        %if the digitizer crashes, i.e. starts returning all 0's, reload the library and redo the measurement
        %measureJohnsonNoise will return -1 if the first 100 raw samples are all 0x0
        while(calData.johnsonNoise(i,j)==-1)
            [calData.johnsonNoise(i,j), calData.johnsonNoiseErr(i,j)]=measureJohnsonNoise(numberOfSamples,numberOfAverages,numberOfCycles);
            if(calData.johnsonNoise(i,j)==-1) %fixed, should work now?
                digitizerCard.reloadLibrary();
                digitizerCard.configureChannel('A', 'AC', range, 50);
                digitizerCard.configureChannel('B', 'DC', 5, 1000000);
            end
        end
        calData.time=etime(clock,startTime);
        
        %wait for lock-in values to stabilize if needed
        time2=etime(clock,startTime2);
        if(time2<10*lockInTimeConstant)
            pause(10*lockInTimeConstant-time2);
        end
        
        %measure resistance, record it
        myResistance=measureLockInResistance();
        calData.resistance(i,j)=myResistance;
        
        change_to_figure(4);
        plot(gateVoltageList,calData.resistance','.-');
        
        
        change_to_figure(2);
        plot(tempList(1:i),calData.johnsonNoise(1:i,:),'.-');

        save(fullfile(start_dir, FileName),'calData');

    %goto next gate voltage
    end 
    %goto next temp, end gate voltage for loop
end %end temp for loop
%end experiment

   
    function [noisePower, noisePowerErr] = measureJohnsonNoise(numSamples,numAvg,numCycles)
        digitizerCard.setSizeSpectralVoltagePower(numSamples,numAvg);
        digitizerCard.setTriggerDelay(0);
        digitizerCard.setTriggerTimeout(1); %collect data with no delay
        digitizerCard.pipeline_startSpectralPipeline();
        
        noiseData=zeros(1,numCycles);
        
         [~,~,aDataForHist,~]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');
        change_to_figure(1992);
        hist(aDataForHist/range*127.5+127.5,(1:256));
        xlabel('bit bins');
        ylabel('counts');
        
        tic
        for n=1:numCycles
            [noiseData(n),~,aData,~]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');
            if(aData(1:100)/range*127.5+127.5==zeros(1,100))
                noisePower=-1;
                noisePowerErr=-1;
                disp('error: alazartech is spitting out zeros!');
                return;
            end
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