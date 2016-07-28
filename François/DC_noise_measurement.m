%take DC measurementss

function DC_noise_measurement()
    clear temp StartTime start_dir CoolLogData;
    close all;
    fclose all;

    numberOfSamples=2^10;
    numberOfAverages=255;
    numberOfMeasurements=1000; %each measurement will be approx 40 msec
    measTime=0.04;
    tempWaitTime=0;%60*10; %10 mins

    
    UniqueName='Al Tunnel Junction DC double ended measurement base temp';
    %UniqueName = input('Enter uniquie file identifier: ','s');
    start_dir = 'C:\Users\Artem\My Documents\Data\AL Tunnel Junction\';
    StartTime = clock;
    FileName = strcat('Tlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

    resistance=10530000;
    sampleResistance=15059;
    range=0.1;
    
    digitizerCard = deviceDrivers.ATS850Driver(1,1);
    %digitizerCard.setTriggerDelay(50000); %1ms delay time
    digitizerCard.setTriggerTimeout(0); %infinite timeout
    digitizerCard.configureChannel('A', 'AC', range, 50);
    digitizerCard.configureChannel('B', 'AC', range, 50);
    
    %sg386=deviceDrivers.SG382();
    %sg386.connect('27');
    
    currentSource=deviceDrivers.YokoGS200();
    currentSource.connect('18');
    currentSource.mode='voltage';
    
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');

    %mask for the FFT, square bandpass filter
    fftMask=[0 1.31e7; 1.56e7 3e7];
    %currentList=[5 5; 5 10; 10 15; 15 20; 20 30; 30 40; 40 50; 50 60; 60 70; 70 80; 80 90; 90 100; 110 120; 130 150; 170 190; 210 240; 270 300; 330 360; 400 450]*1e-9;
    %currentList=[5 30; 30 60; 60 100; 100 150; 150 200; 250 300; 300 350; 350 400]*1e-9;
    tempList=[0];
    %currentList=1e-9*[0 0; 5 20; 20 40; 40 60; 60 80; 80 100; 100 120; 120 140; 140 160; 160 180; 180 200; 200 225; 225 250; 250 275; 275 300; 300 350; 350 400; 400 450; 450 500; 550 600];
    %currentList=1e-9*[0 0; 5 20; 20 40; 40 70; 70 100; 100 140; 140 180; 180 230; 230 280; 280 340; 340 400; 400 475; 475 550; 550 650; 650 750; 750 850; 850 1000]
    %currentList=1e-9*[0 0; 0 0; 0 0; 0 0; 0 0; 0 0;]
    currentList=1e-9*[0,10,20,30,50,80,130,210,340,550,890];
    
    gateVoltageList=[0];
  
    estTimePerTemp=length(currentList)*length(gateVoltageList)*length(tempList)*numberOfMeasurements*measTime/60/60
    
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
    data=struct('time',0,'temp',0,'power',0,'powerErr',0,'sourceVoltage',0,'sampleVoltage',0,'gateVoltage',0);
    
    figure(2);    
    myPlot2=errorbar(data.sampleVoltage,data.power,data.powerErr);
    %axes = gca;
    %set(axes,'XScale','log','YScale','log');
    xlabel('voltage across sample (V)');
    ylabel('Total Power (V^2)');
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
    if(finalTemp>startingTemp)%we are warming
        fprintf('warming to %f K\n', finalTemp)
        while(keeplooping && tempController.temperatureA<finalTemp-0.1)
            fprintf('current temp is %f K\n', tempController.temperatureA);
            pause(5);
        end
        fprintf('temp of %f K reached\n', finalTemp)
    else%we are cooling
        fprintf('cooling to %f K\n', finalTemp)
        while(keeplooping && tempController.temperatureA>finalTemp+0.1)
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

    %for every current value
    for currentIndex=1:length(currentList)
        %measure the AC difference in noise power, then compute the
        %derivative and store all the data
        [data.power(tempIndex,gateVoltageIndex,currentIndex), data.powerErr(tempIndex,gateVoltageIndex,currentIndex)]=measure2(currentList(currentIndex),numberOfSamples,numberOfAverages,numberOfMeasurements);
        data.time(tempIndex,gateVoltageIndex,currentIndex)=etime(clock,startTime);
        data.temp(tempIndex,gateVoltageIndex,currentIndex)=tempController.temperatureA;
        data.gateVoltage(tempIndex,gateVoltageIndex,currentIndex)=gateVoltageList(gateVoltageIndex);
        data.sourceVoltage(tempIndex,gateVoltageIndex,currentIndex)=currentList(currentIndex)*(resistance+sampleResistance);
        data.sampleVoltage(tempIndex,gateVoltageIndex,currentIndex)=currentList(currentIndex)*sampleResistance;
        
        %note in use right now
        data.voltage2(tempIndex,gateVoltageIndex,2*currentIndex-1)=0;%currentSource.voltage;
        %currentSource.current=currentList(i,2);
        %pause(0.5);
        data.voltage2(tempIndex,gateVoltageIndex,2*currentIndex)=0;%currentSource.voltage;
        
                
        %if the data is eqaul to infinity, set it to zero so the plots will work
        if(data.derivs(tempIndex,gateVoltageIndex,currentIndex)==Inf || data.derivs(tempIndex,gateVoltageIndex,currentIndex)==-Inf)
            data.derivs(tempIndex,gateVoltageIndex,currentIndex)=0;
        end
        if(data.derivErr(tempIndex,gateVoltageIndex,currentIndex)==Inf || data.deriv(ErrtempIndex,gateVoltageIndex,currentIndex)==-Inf)
            data.derivErr(tempIndex,gateVoltageIndex,currentIndex)=0;
        end
        
        set(myPlot2,'XData',data.sampleVoltage(tempIndex,gateVoltageIndex,:),'YData',data.power(tempIndex,gateVoltageIndex,:),'UData',data.powerErr(tempIndex,gateVoltageIndex,:),'LData',data.powerErr(tempIndex,gateVoltageIndex,:));
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
    function [power, powerErr] = measure2(current,numSamples,numAvg,numMeasurements)             
        %current comes throuhg the 10 MOhm resistor
        currentSource.value=(current)*(resistance+sampleResistance); %set to a voltage, not a current
        
        
        digitizerCard.setTriggerOperation('J_or_K','B','positive',triggerLevelCodeTop,'B','negative',triggerLevelCodeBottom); %160 works for range of 1, so does 130
        digitizerCard.setSizeSpectralVoltagePower(numSamples,numAvg);
        digitizerCard.setTriggerDelay(350000);
        digitizerCard.setTriggerTimeout(0);
  
        %take the first noiseArray dataset and make a histogram to make sure the range on the card is set correctly
        noiseArray=zeros(1,numMeasurements);
        [noiseArray(1),~,aDataForHist,~]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');           
        figure(1992);
        hist(aDataForHist/range*127.5+127.5,(1:256));
        xlabel('bit bins');
        ylabel('counts');
        drawnow;   
        
        for j=1:numMeasurements-1   %can get this down to about 83 msec for A and B
            %if(rem(j,1000)==0)
            tic
            %end
            [noiseArray(j+1),~,~,~]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');           
            %if(rem(j,5000)==0)
            toc
            
            
            %fprintf('measuring %e to %e nanoAmps, iteration %d of %d\n, at %f gate voltage, at %f Kelvin',currentList(currentIndex,1),currentList(currentIndex,2),j,numMeasurements,gateVoltageList(gateVoltageIndex),tempList(tempIndex));
            %end
        %toc
        end
 
        %calculate the mean power and standard error
        power=mean(lowNoiseArray);
        powerErr=std(lowNoiseArray)/sqrt(numMeasurements+1);
    end

end