%take DC measurementss

function DC_noise_vs_biasV(UniqueName, start_dir, numberOfSamples, numberOfAverages, numberOfDCCycles, tempWaitTime, temperatureWindow, tempRampRate, fftMask, resistance, leadResistance, range, gateVoltageList, tempList, lockInTimeConstant,  resistanceMeasExcitationCurrent)

    clear temp StartTime start_dir CoolLogData;
    clear all;
    clear global;
    close all;
    fclose all;


    measTime=0.012;
    
    gateVoltageStep=0.01;
    gateVoltageWaitTime=.3;
    
    
    
    StartTime = clock;
    FileName = strcat('Gr_shot_noise_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

    
    
    digitizerCard = deviceDrivers.ATS850DriverPipelined(1,1);
    %digitizerCard.setTriggerDelay(50000); %1ms delay time
    digitizerCard.setTriggerTimeout(0); %infinite timeout
    digitizerCard.configureChannel('A', 'AC', range, 50);
    digitizerCard.configureChannel('B', 'AC', range, 50);
    
    biasController=deviceDrivers.YokoGS200();
    biasController.connect('17');
    assert(strcmp(biasController.mode,'VOLT'),'wrong bias source mode');
    
    gateController=deviceDrivers.YokoGS200();
    gateController.connect('16');
    assert(strcmp(gateController.mode,'VOLT'),'wrong gate source mode');
    
    %drive current through fake resistor
    %measure the voltage drop aross the device
    voltageMeter=deviceDrivers.Keithley2450();
    voltageMeter.connect('26');
    assert(strcmp(voltageMeter.sense_mode,'VOLT:DC'),'wrong sense mode on Keithley');
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');
    tempController.rampRate1=tempRampRate;


  
    estTime=length(biasVoltageList)*length(gateVoltageList)*length(tempList)*numberOfDCCycles*measTime/60/60
    
    %time in s
    %temp in K
    %power in W
    %poweErr is in W
    %source voltage V
    %biasVoltage is the measured bias voltage
    %resistance is the measured DC sample resistance (sample voltage)/current
    %sample current is measured current through sample (A)
    %gate voltage is the set gate voltage
    fanoData=struct('time',0,'temp',0,'power',0,'powerErr',0,'sourceVoltage',0,'biasVoltage',0,'sampleCurrent',0,'resistance',0,'gateVoltage',0,'tempList',0,'biasVoltageList',0,'gateVoltageList',0,'range',0);
    fanoData.tempList=tempList;
    fanoData.biasVoltageList=biasVoltageList;
    fanoData.gateVoltageList=gateVoltageList;
    fanoData.range=range;
    
    data3D=zeros(length(tempList),length(gateVoltageList),length(biasVoltageList))/0;
    fanoData.time=data3D;
    fanoData.temp=data3D;
    fanoData.power=data3D;
    fanoData.powerErr=data3D;
    fanoData.sourceVoltage=data3D;
    fanoData.biasVoltage=data3D;
    fanoData.sampleCurrent=data3D;
    fanoData.resistance=data3D;
    fanoData.gateVoltage=data3D;
    
    startTime=clock;
    
    figure(1992);
    figure(4);
    clf;
    hold on;
    xlabel('gate voltage (V)');
    ylabel('Resistance (Ohms)');
    grid on;
    
    for i=1:length(tempList)
        setTemperature(tempList(i));

        figure(2);
        clf;
        hold on;
        xlabel('bias voltage (V)');
        ylabel('Total Power (W)');
        grid on;

        figure(3);
        clf;
        hold on;
        xlabel('bias voltage (V)');
        ylabel('Resistance (Ohms)');
        grid on;
        

       

        for j=1:length(gateVoltageList)
            fprintf('setting gate voltage to %g, at %g Kelvin\n',gateVoltageList(j),tempList(i));
            rampToGateVoltage(gateVoltageList(j));

            %for every current value
            for k=1:length(biasVoltageList)
                %set an initial excitation current to measure the resistance
                biasController.value=resistanceMeasExcitationCurrent*resistance;
                pause(0.2);
                myResistance=measureDCResistance();
                if(biasVoltageList(k)~=0)
                    %now that we have an approximate resistance, set the desired voltage for this datapoint and measure resistance again
                    biasController.value=biasVoltageList(k)*(myResistance+resistance+leadResistance)/myResistance;
                    pause(0.2);
                    myResistance=measureDCResistance();
                    %repeat a few times
                    biasController.value=biasVoltageList(k)*(myResistance+resistance+leadResistance)/myResistance;
                    pause(0.2);
                    myResistance=measureDCResistance();
                    biasController.value=biasVoltageList(k)*(myResistance+resistance+leadResistance)/myResistance;
                    pause(0.2);
                    myResistance=measureDCResistance();
                    biasController.value=biasVoltageList(k)*(myResistance+resistance+leadResistance)/myResistance;
                    pause(0.2);
                    myResistance=measureDCResistance();
                    biasController.value=biasVoltageList(k)*(myResistance+resistance+leadResistance)/myResistance;
                    pause(0.2);
                    if(biasVoltageList(k)*(myResistance+resistance+leadResistance)/myResistance>32)
                        biasController.value=32;
                        pause(0.2);
                    elseif(biasVoltageList(k)*(myResistance+resistance+leadResistance)/myResistance<-32)
                        biasController.value=-32;
                        pause(0.2);
                    end
                    
                    myResistance=measureDCResistance();
                else
                    biasController.value=0;
                    pause(0.3);
                end

                %measure the DC noise and then compute/store the data
                [fanoData.power(i,j,k), fanoData.powerErr(i,j,k)]=measureDC(numberOfSamples,numberOfAverages,numberOfDCCycles);
                fanoData.time(i,j,k)=etime(clock,startTime);
                fanoData.temp(i,j,k)=tempController.temperatureA;
                fanoData.sourceVoltage(i,j,k)=biasController.value;
                vs=voltageMeter.senseVoltage;
                fanoData.biasVoltage(i,j,k)=vs-leadResistance/resistance*(fanoData.sourceVoltage(i,j,k)-vs); %subtract the voltage across the leads
                fanoData.sampleCurrent(i,j,k)=(fanoData.sourceVoltage(i,j,k)-fanoData.biasVoltage(i,j,k))/resistance;
                fanoData.resistance(i,j,k)=myResistance;
                fanoData.gateVoltage(i,j,k)=gateVoltageList(j); 
                
                change_to_figure(2); %noise power vs bias voltage, for all gate voltages for this temp
                plot(squeeze(fanoData.biasVoltage(i,j,1:k)),squeeze(fanoData.power(i,j,1:k)),'.-');
                drawnow;
                

                
                change_to_figure(3); %resistance vs bias voltage, for all gate voltages for this temp
                plot(squeeze(fanoData.biasVoltage(i,j,1:k)),squeeze(fanoData.resistance(i,j,1:k)),'.-');
                drawnow;

                save(fullfile(start_dir, FileName),'fanoData');

             end %next gate voltage, end current for loop
             
                change_to_figure(4); %resistance vs gate voltage, for all temps
                %size(data.resistance)
                %length(gateVoltageList)
                plot(gateVoltageList,fanoData.resistance(i,:,1),'.-');
                drawnow;
             
        end %next temp, end gate voltage for loop
    end %end temp for loop
    
    function [noisePower, noisePowerErr] = measureDC(numSamples,numAvg,numCycles)
        digitizerCard.setSizeSpectralVoltagePower(numSamples,numAvg);
        digitizerCard.setTriggerDelay(0);
        digitizerCard.setTriggerTimeout(1); %collect data with no delay
        digitizerCard.pipeline_startSpectralPipeline();
        
        [a,~,aDataForHist,~]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');
        change_to_figure(1992);
        hist(aDataForHist/range*127.5+127.5,(1:256));
        xlabel('bit bins');
        ylabel('counts');
        
        noiseData=zeros(1,numCycles);
        
        for n=1:numCycles
            noiseData(n)=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');
        end
        noisePower=mean(noiseData);
        noisePowerErr=std(noiseData)/numCycles;
    end
    
    %measure the resistance based on the current current flowing and the votlage drop across sample, subtract lead resistance
    function res=measureDCResistance()
        topVoltage=biasController.value;
        bottomVoltage=voltageMeter.senseVoltage;
        res=resistance*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
    end
    
    %set temperature and wait for thermal stabilitzation
    function setTemperature(finalTemp)
        keeplooping=true;%can pause program and set this to true if needed
        startingTemp=tempController.temperatureA;
        tempController.setPoint1=finalTemp; 
        if(finalTemp>startingTemp)%we are warming
            fprintf('warming to %f K\n', finalTemp)
            while(keeplooping && tempController.temperatureA<finalTemp-temperatureWindow)
                fprintf('current temp is %f K\n', tempController.temperatureA);
                pause(5);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        else%we are cooling
            fprintf('cooling to %f K\n', finalTemp)
            while(keeplooping && tempController.temperatureA>finalTemp+temperatureWindow)
                fprintf('current temp is %f K\n', tempController.temperatureA);
                pause(5);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        end

        pause(tempWaitTime);
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