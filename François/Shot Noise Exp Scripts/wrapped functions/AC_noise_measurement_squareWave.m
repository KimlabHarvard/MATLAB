%take square wave AC measurementss by varying the current between two
%nearby values

function AC_noise_measurement_squareWave()
    clear temp StartTime start_dir CoolLogData;
    close all;
    fclose all;

    numberOfSamples=2^16;
    numberOfAverages=2^2-1;
    numberOfCycles=1000; %each cycle will be approx 82-83 msec
    cycleTime=0.047;
    tempWaitTime=0;%60*2; %2 mins

    
    UniqueName='Graphene_baseTemp_shotNoise_3K_to_60K_0Vg';
    %UniqueName = input('Enter uniquie file identifier: ','s');
    start_dir = 'C:\Users\Artem\My Documents\Data\Graphene Shot Noise\';
    StartTime = clock;
    FileName = strcat('Tlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

    resistance=10530000;
    sampleResistance=1590;
    range=0.04;
    
    digitizerCard = deviceDrivers.ATS850DriverPipelined(1,1);
    %digitizerCard.setTriggerDelay(50000); %1ms delay time
    digitizerCard.setTriggerTimeout(0); %infinite timeout
    digitizerCard.configureChannel('A', 'AC', range, 50);
    digitizerCard.configureChannel('B', 'DC', 5, 1000000);
    
    %sg386=deviceDrivers.SG382();
    %sg386.connect('27');
    
    lowBiasController=deviceDrivers.YokoGS200();
    highBiasController=deviceDrivers.YokoGS200();
    lowBiasController.connect('17');
    highBiasController.connect('18');
    lowBiasController.mode='voltage';
    highBiasController.mode='voltage';
    lowBiasController.value=0;
    highBiasController.value=0;
    lowBiasController.output=1;
    highBiasController.output=1;
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');

    %mask for the FFT, square bandpass filter
    fftMask=[0 1.81e7; 2.13e7 3e7];
    %currentList=[5 5; 5 10; 10 15; 15 20; 20 30; 30 40; 40 50; 50 60; 60 70; 70 80; 80 90; 90 100; 110 120; 130 150; 170 190; 210 240; 270 300; 330 360; 400 450]*1e-9;
    currentList=[0 0; 100 200; 300 400; 500 600; 700 800; 900 1000; 1100 1200; 1300 1400; 1500 1600; 1700 1800; 1900 2000; 2100 2200; 2300 2400; 2500 2600]*1e-9;
    tempList=[60];
    %currentList=1e-9*[0 0; 5 20; 20 40; 40 60; 60 80; 80 100; 100 120; 120 140; 140 160; 160 180; 180 200; 200 225; 225 250; 250 275; 275 300; 300 350; 350 400; 400 450; 450 500; 550 600];
    %currentList=1e-9*[0 0; 5 20; 20 40; 40 70; 70 100; 100 140; 140 180; 180 230; 230 280; 280 340; 340 400; 400 475; 475 550; 550 650; 650 750; 750 850; 850 1000]
    %currentList=1e-9*[0 0; 0 0; 0 0; 0 0; 0 0; 0 0;]
    [s1, ~]=size(currentList);
    
    gateVoltageList=[0];
  
    estTimePerTemp=s1*numberOfCycles*length(tempList)*cycleTime/60/60+tempWaitTime*length(tempList)/60/60
    
    %time in s
    %temp in K
    %power in V^2
    %powerErr is std error of the mean for power
    %currents in A, the midpoint current for the deriv
    %derivs in V^2/A
    %derivErr is std err of mean for derivs
    %currents2 is for plotting the power vs. current
    %voltage2 is the measured voltage for the given current 
    %votlages2 is the x data for plotting the power data
    %voltages is for plotting the derivative data
    data=struct('time',0,'temp',0,'power',0,'powerErr',0,'voltages',0,'derivs',0,'derivErr',0,'voltages2',0,'voltage2',0,'gateVoltage',0);
    
    figure(5);    
    myPlot1=errorbar(data.voltages,data.derivs,data.powerErr);
    %axes = gca;
    %set(axes,'XScale','log','YScale','log');
    xlabel('voltage across sample (V)');
    ylabel('derivative (W/V)');
    grid on;
    
    figure(2);    
    myPlot2=errorbar(data.voltages2,data.power,data.powerErr);
    %axes = gca;
    %set(axes,'XScale','log','YScale','log');
    xlabel('voltage across sample (V)');
    ylabel('Total Power (W)');
    grid on;
    
    figure(3);
    temperaturePlot=plot(data.time,data.temp);
    xlabel('time');
    ylabel('Temp (K)');
    grid on;
    
    drawnow;
    startTime=clock;
    
for tempIndex=1:length(tempList)
    keeplooping=true;%can pause program and set this to true if needed
    startingTemp=tempController.temperatureA;
    finalTemp=tempList(tempIndex);
    tempController.setPoint1=tempList(tempIndex);
    tempDiff=0.01;
    if(finalTemp>startingTemp)%we are warming
        fprintf('warming to %f K\n', finalTemp)
        while(keeplooping && tempController.temperatureA<finalTemp-tempDiff)
            fprintf('current temp is %f K\n', tempController.temperatureA);
            pause(5);
        end
        fprintf('temp of %f K reached\n', finalTemp)
    else%we are cooling
        fprintf('cooling to %f K\n', finalTemp)
        while(keeplooping && tempController.temperatureA>finalTemp+tempDiff)
            fprintf('current temp is %f K\n', tempController.temperatureA);
            pause(5);
        end
        fprintf('temp of %f K reached\n', finalTemp)
    end
    
    pause(tempWaitTime);
    
    for gateVoltageIndex=1:length(gateVoltageList)
    
        %set the gate voltage
        %wait some amount of time
        fprintf('setting gate voltage to %f, at %f Kelvin',gateVoltageList(gateVoltageIndex),tempList(tempIndex));
    
    
    %for every pair of currents
    for currentIndex=1:s1
 
        %measure the AC difference in noise power, then compute the
        %derivative and store all the data
        

        
        [diff, diffErr, data.power(tempIndex,gateVoltageIndex,2*currentIndex-1), data.powerErr(tempIndex,gateVoltageIndex,2*currentIndex-1), data.power(tempIndex,gateVoltageIndex,2*currentIndex), data.powerErr(tempIndex,gateVoltageIndex,2*currentIndex)]=measure2(currentList(currentIndex,1),currentList(currentIndex,2),numberOfSamples,numberOfAverages,numberOfCycles);
        data.time(tempIndex,gateVoltageIndex,currentIndex)=etime(clock,startTime);
        data.temp(tempIndex,gateVoltageIndex,currentIndex)=tempController.temperatureA;
        data.gateVoltage(tempIndex,gateVoltageIndex,currentIndex)=gateVoltageList(gateVoltageIndex);
        data.derivErr(tempIndex,gateVoltageIndex,currentIndex)=diffErr/(currentList(currentIndex,2)-currentList(currentIndex,1))/sampleResistance;
        data.derivs(tempIndex,gateVoltageIndex,currentIndex)=diff/(currentList(currentIndex,2)-currentList(currentIndex,1))/sampleResistance;
        data.voltages(tempIndex,gateVoltageIndex,currentIndex)=(currentList(currentIndex,1)+currentList(currentIndex,2))/2*sampleResistance;
        data.voltages2(tempIndex,gateVoltageIndex,2*currentIndex-1)=currentList(currentIndex,1)*sampleResistance;
        data.voltages2(tempIndex,gateVoltageIndex,2*currentIndex)=currentList(currentIndex,2)*sampleResistance;
        
        %note in use right now
        data.voltage2(tempIndex,gateVoltageIndex,2*currentIndex-1)=0;%currentSource.voltage;
        %currentSource.current=currentList(i,2);
        %pause(0.5);
        data.voltage2(tempIndex,gateVoltageIndex,2*currentIndex)=0;%currentSource.voltage;
        
                
        %if the data is equal to infinity, set it to zero so the plots will work
        if(data.derivs(tempIndex,gateVoltageIndex,currentIndex)==Inf || data.derivs(tempIndex,gateVoltageIndex,currentIndex)==-Inf)
            data.derivs(tempIndex,gateVoltageIndex,currentIndex)=0;
        end
        if(data.derivErr(tempIndex,gateVoltageIndex,currentIndex)==Inf || data.derivErr(tempIndex,gateVoltageIndex,currentIndex)==-Inf)
            data.derivErr(tempIndex,gateVoltageIndex,currentIndex)=0;
        end
        
        set(myPlot1,'XData',data.voltages(tempIndex,gateVoltageIndex,:),'YData',data.derivs(tempIndex,gateVoltageIndex,:),'UData',data.derivErr(tempIndex,gateVoltageIndex,:),'LData',data.derivErr(tempIndex,gateVoltageIndex,:));
        set(myPlot2,'XData',data.voltages2(tempIndex,gateVoltageIndex,:),'YData',data.power(tempIndex,gateVoltageIndex,:),'UData',data.powerErr(tempIndex,gateVoltageIndex,:),'LData',data.powerErr(tempIndex,gateVoltageIndex,:));
        set(temperaturePlot,'XData',data.time(tempIndex,gateVoltageIndex,:),'YData',data.temp(tempIndex,gateVoltageIndex,:));
       
        
        save(fullfile(start_dir, FileName),'data');

    end %next gate voltage, end current for loop
    end %next temp, end gate voltage for loop
end %end temp for loop

    %this function switches between two currents many times to take an AC
    %measurement of the derivative of noise power vs. current
    %low/high current are the two currents
    %numSamples number of samples in FFT
    %numAvg number of FFTs to average at each current before switching
    %numCycles number of up/down cycles to measure for
    function [avgDiff, stdDiffErr, lowNoise, lowErr, highNoise, highErr] = measure2(lowCurrent,highCurrent,numSamples,numAvg,numCycles)             
        lowNoiseArray=zeros(1,numCycles+1);
        highNoiseArray=zeros(1,numCycles);
        
        lowBiasController.value=lowCurrent*(sampleResistance+resistance);
        highBiasController.value=highCurrent*(sampleResistance+resistance);
        
        pause(.05);
        
        
        %set current to low, measure, then to high, and measure, and repeat

        %set the trigger to proper levels; this should be custom calibrated based on the trigger wave
        triggerLevelVoltsTop=2.5;
        triggerLevelVoltsBottom=2.5;
        triggerRangeVolts=5;
        triggerLevelCodeTop=128+127*triggerLevelVoltsTop/triggerRangeVolts;
        triggerLevelCodeBottom=128+127*triggerLevelVoltsBottom/triggerRangeVolts;
        digitizerCard.setTriggerOperation('J_or_K','B','positive',triggerLevelCodeTop,'B','negative',triggerLevelCodeBottom);
        digitizerCard.setSizeSpectralVoltagePower(numSamples,numAvg);
        digitizerCard.setTriggerDelay(50000);
        digitizerCard.setTriggerTimeout(0);
        
        digitizerCard.pipeline_startSpectralPipeline();
        
        [lowNoiseArray(1),~,aDataForHist,rawSamples]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
        %if the data is the incorrect type (wrong polarity) take it again to get the right polarity
        while(rawSamples(1000)<1)
            [lowNoiseArray(1),~,aDataForHist,rawSamples]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
        end
        figure(1992);
        hist(aDataForHist/range*127.5+127.5,(1:256));
        xlabel('bit bins');
        ylabel('counts');
        
        drawnow;        
        for j=1:numCycles   %can get this down to about 83 msec for A and B
            %if(rem(j,100)==0)
                %tic
            %end
            
            [highNoiseArray(j),~,~,rawSamples]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
            %if the data is the incorrect type (wrong polarity) take it again to get the right polarity 
            while(rawSamples(1000)>4)
                fprintf('freq too high %d\n',j);
                [highNoiseArray(j),~,~,rawSamples]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
            end

            [lowNoiseArray(j+1),~,~,rawSamples]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
            %if the data is the incorrect type (wrong polarity) take it again to get the right polarity
            while(rawSamples(1000)<1)
                [lowNoiseArray(j+1),~,~,rawSamples]=digitizerCard.pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
            end
            
            %if(rem(j,100)==0)
                %toc
            %fprintf('measuring %e to %e nanoAmps, iteration %d of %d\n, at %f gate voltage, at %f Kelvin',currentList(currentIndex,1),currentList(currentIndex,2),j,numCycles,gateVoltageList(gateVoltageIndex),tempList(tempIndex));
            %end
        %toc
        end
        
        
        %calcuate the differences going up in current and going down in
        %current
        upDiffs=highNoiseArray-lowNoiseArray(1:numCycles);
        downDiffs(1:numCycles)=highNoiseArray(1:numCycles)-lowNoiseArray(2:numCycles+1);
 
        %calculate all the means and standard errors
        stdDiffErr=std([upDiffs downDiffs])/sqrt(numCycles);
        avgDiff=mean([upDiffs downDiffs]);
        lowNoise=mean(lowNoiseArray);
        lowErr=std(lowNoiseArray)/sqrt(numCycles+1);
        highNoise=mean(highNoiseArray);
        highErr=std(highNoiseArray)/sqrt(numCycles);

    end

end