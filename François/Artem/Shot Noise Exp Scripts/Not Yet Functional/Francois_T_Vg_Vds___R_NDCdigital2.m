%take DC measurementss

function DC_noise_measurement()
    clear temp StartTime start_dir CoolLogData;
    clear all;
    clear global;
    close all;
    fclose all;

    numberOfSamples=2^10;
    numberOfAverages=255;
    numberOfMeasurements=10000; %each measurement will be approx 40 msec
    measTime=0.017;
    tempWaitTime=600;%60*10; %10 mins

    
    UniqueName='Al Tunnel Junction DC double ended measurement 2_6 to 50K 0 to 900 nanoamps';
    %UniqueName = input('Enter uniquie file identifier: ','s');
    start_dir = 'C:\Users\Artem\My Documents\Data\AL Tunnel Junction\';
    StartTime = clock;
    FileName = strcat('Tlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

    resistance=1004000;
    %sampleResistance=15059;
    range=0.2;
    
    digitizerCard = deviceDrivers.ATS850DriverPipelined(1,1);
    %digitizerCard.setTriggerDelay(50000); %1ms delay time
    digitizerCard.setTriggerTimeout(0); %infinite timeout
    digitizerCard.configureChannel('A', 'AC', range, 50);
    digitizerCard.configureChannel('B', 'AC', range, 50);
    
    %sg386=deviceDrivers.SG382();
    %sg386.connect('27');
    
    currentSource=deviceDrivers.YokoGS200();
    currentSource.connect('17');
    currentSource.mode='voltage';
    
    
    tempController=FrancoisLakeShore335();
    %tempController=deviceDrivers.Lakeshore335();
    tempController.connect('12');

    %mask for the FFT, square bandpass filter
    fftMask=[0 1.627e7; 1.807e7 3e7];
    %tempList=[2.6 3 5 8 12 15];
    tempList=[2.6 5 10 15 20 25 30 35 40 45 50];
    currentList=1e-9*[0,10,20,30,40,50,60,70,80,90,100,120,140,160,180,200,220,240,260,280,300,330,360,400,450,500,550,600,650,700,750,800,850,900]; %34 points, 1.6 hrs at 10k meas/point
    %currentList=1e-9*[0,10,20,30,50,80,130,210,340];
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
    if(tempIndex>1)
        pause(tempWaitTime); %pause 10 mins between temperatures
    end
    
    for gateVoltageIndex=1:length(gateVoltageList)
        %set the gate voltage
        %wait some amount of time
        fprintf('setting gate voltage to %f, at %f Kelvin',gateVoltageList(gateVoltageIndex),tempList(tempIndex));

    %for every current value
    for currentIndex=1:length(currentList)
        %measure the DC noise and then compute/store the data
        [data.power(tempIndex,gateVoltageIndex,currentIndex), data.powerErr(tempIndex,gateVoltageIndex,currentIndex)]=measure2(currentList(currentIndex),numberOfSamples,numberOfAverages,numberOfMeasurements);
        data.time(tempIndex,gateVoltageIndex,currentIndex)=etime(clock,startTime);
        data.temp(tempIndex,gateVoltageIndex,currentIndex)=tempController.temperatureA;
        data.gateVoltage(tempIndex,gateVoltageIndex,currentIndex)=gateVoltageList(gateVoltageIndex);
        data.sourceVoltage(tempIndex,gateVoltageIndex,currentIndex)=currentList(currentIndex)*(resistance+sampleResistance);
        data.sampleVoltage(tempIndex,gateVoltageIndex,currentIndex)=currentList(currentIndex)*sampleResistance;
        
        %TODO: change all 0's in data to NaN for better plots       
        
        set(myPlot2,'XData',data.sampleVoltage(tempIndex,gateVoltageIndex,:),'YData',setZerosToNaN(data.power(tempIndex,gateVoltageIndex,:)),'UData',setZerosToNaN(data.powerErr(tempIndex,gateVoltageIndex,:)),'LData',setZerosToNaN(data.powerErr(tempIndex,gateVoltageIndex,:)));
        set(temperaturePlot,'XData',data.time(tempIndex,gateVoltageIndex,:),'YData',setZerosToNaN(data.temp(tempIndex,gateVoltageIndex,:)));
             
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
        
        
        digitizerCard.setTriggerOperation('J_or_K','A','positive',128,'A','negative',128);
        digitizerCard.setSizeSpectralVoltagePower(numSamples,numAvg);
        digitizerCard.setTriggerDelay(0);
        digitizerCard.setTriggerTimeout(1);
  
        %take the first noiseArray dataset and make a histogram to make sure the range on the card is set correctly
        noiseArray=zeros(1,numMeasurements);
        [noiseArray(1),~,aDataForHist,~]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');           
        figure(1992);
        hist(aDataForHist/range*127.5+127.5,(1:256));
        xlabel('bit bins');
        ylabel('counts');
        drawnow;   
        
        for j=2:numMeasurements   %can get this down to about 83 msec for A and B
            %if(rem(j,1000)==0)
            %tic
            %end
            [noiseArray(j),~,~,~]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');           
            %if(rem(j,5000)==0)
            %toc
            
            
            %fprintf('measuring %e to %e nanoAmps, iteration %d of %d\n, at %f gate voltage, at %f Kelvin',currentList(currentIndex,1),currentList(currentIndex,2),j,numMeasurements,gateVoltageList(gateVoltageIndex),tempList(tempIndex));
            %end
        %toc
        end
 
        %calculate the mean power and standard error
        power=mean(noiseArray);
        powerErr=std(noiseArray)/sqrt(numMeasurements+1);
    end

end