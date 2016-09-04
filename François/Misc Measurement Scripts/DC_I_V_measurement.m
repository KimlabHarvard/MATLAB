%take DC measurements of IV 

%take DC measurementss

function DC_I_V_measurement()
    clear temp StartTime start_dir CoolLogData;
    close all;
    fclose all;

    numberOfMeasurements=1; %number of measurements at each point in parameter space
    measTime=0.04;
    tempWaitTime=0;%60*10; %10 mins

    
    UniqueName='Al Tunnel Junction DC double ended IV measurement test';
    %UniqueName = input('Enter uniquie file identifier: ','s');
    start_dir = 'C:\Users\Artem\My Documents\Data\AL Tunnel Junction\';
    StartTime = clock;
    FileName = strcat('Tlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

    resistance=10530000;
    
    currentSource=deviceDrivers.Keithley2450();
    currentSource.connect('26');
    currentSource.sense_mode='voltage';
    currentSource.source_mode='current'; %SOURCE CURRENT DIRECTLY HELL YEAH
    currentSource.setFourWireVoltSense(1); %use 4 wire sensing
    currentSource.NPLC=10;
    currentSource.source_limit=1e-5; %limit current to 1 microamp
    currentSource.readback=1;
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');

    %currentList=[5 5; 5 10; 10 15; 15 20; 20 30; 30 40; 40 50; 50 60; 60 70; 70 80; 80 90; 90 100; 110 120; 130 150; 170 190; 210 240; 270 300; 330 360; 400 450]*1e-9;
    %currentList=[5 30; 30 60; 60 100; 100 150; 150 200; 250 300; 300 350; 350 400]*1e-9;
    tempList=[3];
    %currentList=1e-9*[0 0; 5 20; 20 40; 40 60; 60 80; 80 100; 100 120; 120 140; 140 160; 160 180; 180 200; 200 225; 225 250; 250 275; 275 300; 300 350; 350 400; 400 450; 450 500; 550 600];
    %currentList=1e-9*[0 0; 5 20; 20 40; 40 70; 70 100; 100 140; 140 180; 180 230; 230 280; 280 340; 340 400; 400 475; 475 550; 550 650; 650 750; 750 850; 850 1000]
    %currentList=1e-9*[0 0; 0 0; 0 0; 0 0; 0 0; 0 0;]
    currentList=1e-9*[-740:10:740];
    
    resistance=10530000;
    sampleResistance=15059;
    
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
    data=struct('time',0,'temp',0,'gateVoltage',0,'sourceCurrent',0,'sampleVoltage',0,'sampleVoltageErr',0);
    
    figure(2);    
    myPlot2=errorbar(data.sourceCurrent,data.sampleVoltage,data.sampleVoltageErr);
    %axes = gca;
    %set(axes,'XScale','log','YScale','log');
    xlabel('source Current (A)');
    ylabel('sample Voltage(V)');
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
            [~, ~]=measure2(currentList(1),numberOfMeasurements);
    %for every current value
        for currentIndex=1:length(currentList)
            [data.sampleVoltage(tempIndex,gateVoltageIndex,currentIndex), data.sampleVoltageErr(tempIndex,gateVoltageIndex,currentIndex)]=measure2(currentList(currentIndex),numberOfMeasurements);
            data.time(tempIndex,gateVoltageIndex,currentIndex)=etime(clock,startTime);
            data.temp(tempIndex,gateVoltageIndex,currentIndex)=tempController.temperatureA;
            data.gateVoltage(tempIndex,gateVoltageIndex,currentIndex)=gateVoltageList(gateVoltageIndex);
            data.sourceCurrent(tempIndex,gateVoltageIndex,currentIndex)=currentList(currentIndex);

            %set(myPlot2,'XData',data.sourceCurrent(tempIndex,gateVoltageIndex,:),'YData',setZerosToNaN(data.sampleVoltage(tempIndex,gateVoltageIndex,:)),'UData',setZerosToNaN(data.sampleVoltageErr(tempIndex,gateVoltageIndex,:)),'LData',setZerosToNaN(data.sampleVoltage(tempIndex,gateVoltageIndex,:)));
            set(myPlot2,'XData',data.sourceCurrent(tempIndex,gateVoltageIndex,:),'YData',data.sampleVoltage(tempIndex,gateVoltageIndex,:),'UData',data.sampleVoltageErr(tempIndex,gateVoltageIndex,:),'LData',data.sampleVoltageErr(tempIndex,gateVoltageIndex,:));
            drawnow;
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
    function [volt, voltErr] = measure2(current,numMeasurements)             
        %current comes throuhg the 10 MOhm resistor maybe
        currentSource.current=current; %SOURCE CURRENT DIRECTLY HELL YEAH

        voltArray=zeros(1,numMeasurements);
        for j=1:numMeasurements 
            voltArray(j)=currentSource.voltage;           
        end
 
        %calculate the mean power and standard error
        volt=mean(voltArray);
        voltErr=std(voltArray)/sqrt(numMeasurements);
    end

end