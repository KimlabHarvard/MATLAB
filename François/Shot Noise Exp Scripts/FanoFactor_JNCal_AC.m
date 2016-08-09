%take square wave AC measurementss by varying the current between two
%nearby values

function FanoFactor_JNCal_AC()
    clear temp StartTime start_dir CoolLogData gate;
    close all;
    fclose all;
    
    figure(1992);
    
    numberOfSamples=2^15;
    numberOfAverages=2^3-1;
    numberOfACCycles=400; %each cycle will be approx 60 msec
    numberOfDCCycles=400;
    cycleTime=1/21.11;
    tempWaitTime=60*0; %3 mins
    temperatureWindow=0.008; %difference to setpoint when temperature is considered reached
    lowBiasVoltageList = 1e-3*[1 4 9  14 19 24 29 34 39];
    highBiasVoltageList =1e-3*[3 6 11 16 21 26 31 36 41];
    %gateVoltageList=[-1:.05:-.65   -.6:.02:-.4   -.39:.01:-.3   -.28:.02:-.2 -.15:.05:.2 .3:.1:1];
    gateVoltageList=0;
    tempList=[60 100 150 200 250 300];
    lockInTimeConstant=0.3;
    
    resistanceMeasExcitationCurrentACVpp=1e-6; %1 microAmp;
    gateVoltageStep=0.01;
    gateVoltageWaitTime=1;

    
    %UniqueName='Graphene SquareWaveAC Fano Factor measurement';
    UniqueName='nothing';
    %UniqueName = input('Enter uniquie file identifier: ','s');
    start_dir = 'C:\Users\Artem\My Documents\Data\Graphene Shot Noise\';
    StartTime = clock;
    FileName = strcat('FanoFactor_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

    resistance=1004000;
    %sampleResistance=16000;
    leadResistance=40;
    range=0.04;
    
    k_B=1.38064852e-23;
    e=1.60217662e-19;
    
    digitizerCard = deviceDrivers.ATS850Driver(1,1);
    %digitizerCard.setTriggerDelay(50000); %1ms delay time
    digitizerCard.setTriggerTimeout(0); %infinite timeout
    digitizerCard.configureChannel('A', 'AC', range, 50);
    digitizerCard.configureChannel('B', 'DC', 5, 1000000);
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');
    
    gateController=deviceDrivers.Keithley2450();
    gateController.connect('26');
    gateController.source_mode='voltage';
    %gateController.value=0;
    %gateController.output=1;
    
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
    
    %measure AC differential resistance of the sample with these two things
    topLockIn=deviceDrivers.SRS830(); %measures the first component of 'square wave' AC voltage out of the switch into 10MOhm resistor
    bottomLockIn=deviceDrivers.SRS830(); %measures the first component of 'square wave' AC voltage on the sample
    topLockIn.connect('1');
    bottomLockIn.connect('2');
    topLockIn.timeConstant=lockInTimeConstant;
    bottomLockIn.timeConstant=lockInTimeConstant;

    %mask for the FFT, square bandpass filter
    fftMask=[0 1.81e7; 2.13e7 3e7];
    
    
  
    estTime=length(tempList)*length(gateVoltageList)*(length(lowBiasVoltageList)*numberOfACCycles+numberOfDCCycles/2)*cycleTime/60/60+length(tempList)*tempWaitTime/60/60
    
    %3D data, (i,j,k) = temp, gate, bias indices
    %time (s)-elapsed time since starting the script
    %myClock is an 6-element array of clock
    %temp (K)-the temperature
    %
    %lowBiasVoltage (V)-the lower of the sample bias voltage pair
    %lowBiasCurrent (A)-the above but in units of current
    %highBiasVoltage (V)-the higher of the sample bias voltage pair
    %highBiasCurrent (A)-the above but in units of current
    %
    %noisePowerLow (W) noise power at the lower of the sample bias voltage pair
    %noisePowerHigh (W) noise power at the higher of the sample bias voltage pair
    %noisePowerLowErr (W)
    %noisePowerHighErr (W)
    %
    %noiseDerivative (W/V) noise power derivative based on the sample bias voltage pair
    %noiseDerivativeErr (W/V) noise power derivative based on the sample bias voltage pair
    %midBiasVoltage (V)-the midpoint of the sample bias voltage pair, which is the point of the numerical derivative above
    %midBiasCurrent (A)-the above but in units of current
    %
    %
    %tempList
    %gateVoltageList
    %lowBiasVoltageList
    %highBiasVoltageList
    
    %2D Data
    % resistance (Ohms) the sample resistance
    % dP_P_by_dT the quasi gain, or gain to zeroth order
    %johnsonNoise the DC-measured noise at zero current
    %johnsonNoiseErr
    %T_noise (K)-the calculated noise temperature for this temperature/gateVoltage combination
    
    

    data=struct('time',0,'myClock',0,'temp',0,'lowBiasVoltage',0,'lowBiasCurrent',0,'highBiasVoltage',0,'highBiasCurrent',0,...
        'noisePowerLow',0,'noisePowerHigh',0,'noisePowerLowErr',0,'noisePowerHighErr',0,'noiseDerivative',0,'noiseDerivativeErr',0,...
        'midBiasVoltage',0,'midBiasCurrent',0,'T_noise',0,'tempList',0,'gateVoltageList',0,'lowBiasVoltageList',0,'highBiasVoltageList',0,...
        'resistance',0,'dP_P_by_dT',0,'johnsonNoise',0,'johnsonNoiseErr',0);
    
    %initialize everything to NaN so there aren't any zeros when plotting!
    data3D=zeros(length(tempList),length(gateVoltageList),length(lowBiasVoltageList))/0;
    data2D=zeros(length(tempList),length(gateVoltageList))/0;
    data.time=data3D;
    data.myClock=data3D;
    data.temp=data3D;
    data.lowBiasVoltage=data3D;
    data.lowBiasCurrent=data3D;
    data.highBiasVoltage=data3D;
    data.highBiasCurrent=data3D;
    data.noisePowerLow=data3D;
    data.noisePowerHigh=data3D;
    data.nosiePowerLowErr=data3D;
    data.noisePowerHighErr=data3D;
    data.noiseDerivative=data3D;
    data.noiseDerivativeErr=data3D;
    data.midBiasVoltage=data3D;
    data.midBiasCurrent=data3D;
    
    data.T_noise=data2D;
    data.resistance=data2D;
    data.dP_P_by_dT=data2D;
    data.johnsonNoise=data2D;
    data.johnsonNoiseErr=data2D;
    
    
    %unused for now;
    gainFitData=struct('temp',0,'slope',0,'fit',0,'tempListForFit',0,'noiseListForFit',0);
    
%     figure(1);    
%     %myPlot1=errorbar(data.midBiasVoltage,data.noiseDerivative,data.noiseDerivativeErr);
%     %axes = gca;
%     %set(axes,'XScale','log','YScale','log');
%     xlabel('bias voltage (V)');
%     ylabel('derivative (W/V)');
%     grid on;
%     hold on;
%     
%     figure(2);    
%     %myPlot2=plot(data.lowBiasVoltage,data.noisePowerLow,'.',data.highBiasVoltage,data.noisePowerHigh,'.');
%     %axes = gca;
%     %set(axes,'XScale','log','YScale','log');
%     xlabel('bias voltage (V)');
%     ylabel('Total Power (V^2)');
%     grid on;
%     hold on;
    
    figure(3);
    myPlot3=plot(0,0);
    xlabel('time');
    ylabel('Temp (K)');
    grid on;
    hold on;
    fig3XData=[];
    fig3YData=[];
    
    drawnow;
    startTime=clock;
   totalIndex=1;
    
%iterate through the temperatures    
for i=1:length(tempList)
    %measure the gain at this temperature by ramping temp up and down a bit
    %also measures the noise temp but we don't care about this
    %the sample bias is zero
    %TODO: decide if measuring as a function of gate voltage or as a function of resistance
    %the gain is the real gain G times the effective bandwidth
    %gainList is a vector of gains that corresponds to the list of gatevoltages
    %gainList=measureGain(tempList(i),tempListForGain,gateVoltageList);
    
    %set the temperature and wait until it stabilized
    setTemperature(tempList(i));

    
    %now that we have the current gain for this temperature, we measure the shot noise at all gateVoltages
    %by differentially measuring at various sample bias voltages using the square wave method
    %this gives us the derivative of noise power with respect to sample bias
    %whose value in the high sample bias limit is the fano factor
    figure(1);
    clf;
    hold on;
    xlabel('bias voltage (V)');
    ylabel('derivative (W/V)');
    grid on;
    
    figure(2);
    clf;
    hold on;
    xlabel('bias voltage (V)');
    ylabel('Total Power (W)');
    grid on;
    
    figure(4);
    clf;
    hold on;
    xlabel('gate voltage (V)');
    ylabel('Resistance (Ohms)');
    grid on;

    
    
    %iterate through the gate voltages
    for j=1:length(gateVoltageList)
        fprintf('setting gate voltage to %g, at %g Kelvin',gateVoltageList(j),tempList(i));
        rampToGateVoltage(gateVoltageList(j));

        
        
        %measure resistance, record it
        highBiasController.value=resistanceMeasExcitationCurrentACVpp*resistance/2;
        lowBiasController.value=-resistanceMeasExcitationCurrentACVpp*resistance/2;
        myResistance=measureACResistance();
        data.resistance(i,j)=myResistance;
        
        %measure the johnson noise now
        disp('start measruing johnson noise');
        [data.johnsonNoise(i,j), data.johnsonNoiseErr(i,j)]=measureDC(0,numberOfSamples,numberOfAverages,numberOfDCCycles,myResistance);
        disp('done meas johnson noise');
        xdata=[0];
        ydata=[data.johnsonNoise(i,j)];
        ydataErr=[data.johnsonNoiseErr(i,j)];
        
        for k=1:length(lowBiasVoltageList)

            %measure the AC difference in noise power, then compute the
            %derivative and store all the data

            
            fprintf('start meauring AC noise at V_bias=%g\n',(lowBiasVoltageList(k)+lowBiasVoltageList(k))/2);

            [diff, diffErr, data.noisePowerLow(i,j,k), data.noisePowerLowErr(i,j,k), data.noisePowerHigh(i,j,k), data.noisePowerHighErr(i,j,k)]=...
                measureAC(lowBiasVoltageList(k),highBiasVoltageList(k),numberOfSamples,numberOfAverages,numberOfACCycles,myResistance);
            data.noiseDerivative(i,j,k)=diff/(highBiasVoltageList(k)-lowBiasVoltageList(k));
            data.noiseDerivativeErr(i,j,k)=diffErr/(highBiasVoltageList(k)-lowBiasVoltageList(k));
            data.midBiasVoltage(i,j,k)=(lowBiasVoltageList(k)+highBiasVoltageList(k))/2;
            data.midBiasCurrent(i,j,k)=(lowBiasVoltageList(k)+highBiasVoltageList(k))/2/myResistance;
            
            data.lowBiasVoltage(i,j,k)=lowBiasVoltageList(k);
            data.highBiasVoltage(i,j,k)=highBiasVoltageList(k);
            data.lowBiasCurrent(i,j,k)=lowBiasVoltageList(k)/myResistance;
            data.highBiasCurrent(i,j,k)=highBiasVoltageList(k)/myResistance;
            
            data.temp(i,j,k)=tempController.temperatureA;
            data.time(i,j,k)=etime(clock,startTime);
            %data.myClock(i,j,k,:)=clock;
            
            fig3XData=[fig3XData data.time(i,j,k)];
            fig3YData=[fig3YData data.temp(i,j,k)];

            %if the data is eqaul to infinity, set it to zero so the plots will work
            data.noiseDerivative=setZerosToNaN(data.noiseDerivative);
            data.noiseDerivativeErr=setZerosToNaN(data.noiseDerivativeErr);
            data.noisePowerLow=setZerosToNaN(data.noisePowerLow);
            data.noisePowerLowErr=setZerosToNaN(data.noisePowerLowErr);
            data.noisePowerHigh=setZerosToNaN(data.noisePowerHigh);
            data.noisePowerHighErr=setZerosToNaN(data.noisePowerHighErr);
        
            %plot derivatives vs bias voltage
            change_to_figure(1);
            plot(squeeze(data.midBiasVoltage(i,j,:))',squeeze(data.noiseDerivative(i,j,:))','.-');
            

            
            %plot noise power vs. bias votlage
            xdata=[xdata data.lowBiasVoltage(i,j,k) data.highBiasVoltage(i,j,k)];
            ydata=[ydata data.noisePowerLow(i,j,k) data.noisePowerHigh(i,j,k)];
            ydataErr=[ydataErr data.noisePowerLowErr(i,j,k) data.noisePowerHighErr(i,j,k)];
            change_to_figure(2);
            plot(xdata,ydata,'.-');
            
            change_to_figure(4);
            plot(gateVoltageList,data.resistance','.-');
            
            %plot resistance vs bias voltage
            
%             set(myPlot1,'XData',data.midBiasVoltage(i,j,:),...
%                 'YData',data.noiseDerivative(i,j,:),...
%                 'UData',data.noiseDerivativeErr(i,j,:),...
%                 'LData',data.noiseDerivativeErr(i,j,:));
%             set(myPlot2,'XData',[0 data.lowBiasVoltage(i,j,:) data.highBiasVoltage(i,j,:)],...
%                 'YData',[data.johnsonNoise(i,j) data.noisePowerLow(i,j,:) data.noisePowerHigh(i,j,:)],...
%                 'UData',[data.johnsonNoiseErr(i,j) data.noisePowerLowErr(i,j,:) data.noisePowerHighErr(i,j,:)],...
%                 'LData',[data.johnsonNoiseErr(i,j) data.noisePowerLowErr(i,j,:) data.noisePowerHighErr(i,j,:)]);

            %plot total temp vs. total time
            set(myPlot3,'XData',fig3XData,'YData',fig3YData);

            save(fullfile(start_dir, FileName),'data');
        totalIndex=totalIndex+1;
        end 
        %goto next gate voltage, end current for loop
    end 
    %calcuate the gain to zeroth order by fitting through three points
    if(i>2)
        %for each gate voltage calculate the 0th order gain at the prev temp
        %and then fit the functional form of the derivative at the previous temperature using the 0th order gain just calculated

        xFitData(1:length(gateVoltageList),1:length(lowBiasVoltageList))=squeeze(data.midBiasVoltage(i,1:length(gateVoltageList),1:length(lowBiasVoltageList)));
        yFitData(1:length(gateVoltageList),1:length(lowBiasVoltageList))=squeeze(data.noiseDerivative(i,1:length(gateVoltageList),1:length(lowBiasVoltageList)));

        figure(4);
        clf;
        %xlim([0,max(xFitData));
        grid on;
        hold on;
        xlabel('sample bias voltage (V)');
        yabel('dP_P/dV_B');
        
        fanoFactor=zeros(1,length(gateVoltageList))/0;
        for j=1:length(gateVoltageList)
            myGainFit=fit(tempList(i-2:i)',johnsonNoise(i-2:i,j),'poly1');
            data.dP_P_by_dT(i,j)=myGainFit.p1;
            
            myfittype = fittype(sprintf('F*%e*2*%e*v*coth(%e*v/(4*%e*%e))',myGainFit.p1/(4*k_B),e,e,k_B,tempList(i)),'dependent',{'y'},'independent',{'v'},'coefficients',{'F'});
            fitOptions=fitoptions('Method','NonLinearLeastSquares','StartPoint',1/3);
            myDerivFit=fit(xFitData(j,:)',yFitData(j,:)',myfittype,fitOptions);
            plot(myDerivFit,xFitData,yFitData,'.');
            
            fanoFactor(j)=myDerivFit.F;
        end
        
        figure(5);
        hold on;
        grid on;
        xlabel('gate voltage (V)');
        ylabel('zeroth order Fano Factor');
        plot(gateVoltageList,fanoFactor);
        
        
        
    end
    %goto next temp, end gate voltage for loop
end %end temp for loop
%end experiment

    %this function switches between two currents many times to take an AC
    %measurement of the derivative of noise power vs. current
    %low/high current are the two currents
    %numSamples number of samples in FFT
    %numAvg number of FFTs to average at each current before switching
    %numCycles number of up/down cycles to measure for
    function [avgDiff, stdDiffErr, lowNoise, lowErr, highNoise, highErr] = measureAC(lowBiasV,highBiasV,numSamples,numAvg,numCycles,sampleResistance)
        lowNoiseArray=zeros(1,numCycles+1);
        highNoiseArray=zeros(1,numCycles);
        
        %set up the square wave current source to correct amplitudes
        lowBiasController.value=lowBiasV*(sampleResistance+resistance)/sampleResistance;
        highBiasController.value=highBiasV*(sampleResistance+resistance)/sampleResistance;
        
        %set current to low, measure, then to high, and measure, and repeat

        %TODO: calibrate the trigger level
        %set the trigger to proper levels; this should be custom calibrated based on the trigger wave
        triggerLevelVoltsTop=2.5;
        triggerLevelVoltsBottom=2.5;
        triggerRangeVolts=5;
        triggerLevelCodeTop=128+127*triggerLevelVoltsTop/triggerRangeVolts;
        triggerLevelCodeBottom=128+127*triggerLevelVoltsBottom/triggerRangeVolts;
        digitizerCard.setTriggerOperation('J_or_K','B','positive',triggerLevelCodeTop,'B','negative',triggerLevelCodeBottom); %160 works for range of 1, so does 130
        digitizerCard.setSizeSpectralVoltagePower(numSamples,numAvg);
        digitizerCard.setTriggerDelay(50000); %1 ms delay
        digitizerCard.setTriggerTimeout(0);
        
        %digitizerCard.pipeline_startSpectralPipeline();
        
        [lowNoiseArray(1),~,aDataForHist,rawSamples]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
%         change_to_figure(17);
%             plot(rawSamples);
%             drawnow;
        %if the data is the incorrect type (wrong polarity) take it again to get the right polarity
        while(rawSamples(1000)<1)
            [lowNoiseArray(1),~,aDataForHist,rawSamples]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
%             change_to_figure(17);
%             plot(rawSamples);
%             drawnow;
        end
        change_to_figure(1992);
        hist(aDataForHist/range*127.5+127.5,(1:256));
        xlabel('bit bins');
        ylabel('counts');
        
        %missed=0;
        
        drawnow;        
        for m=1:numCycles   %can get this down to about 83 msec for A and B
            %if(rem(m,1000)==0)
            %tic
            %end
            
            [highNoiseArray(m),~,~,rawSamples]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
%             change_to_figure(17);
%             plot(rawSamples);
%             drawnow;
            %if the data is the incorrect type (wrong polarity) take it again to get the right polarity 
            while(rawSamples(1000)>4) %TODO: find the right value here
                fprintf('freq too high %g\n',m);
                [highNoiseArray(m),~,~,rawSamples]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
%                 change_to_figure(17);
%             plot(rawSamples);
%             drawnow;
            %    missed=1;
            end

            [lowNoiseArray(m+1),~,~,rawSamples]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
%             change_to_figure(17);
%             plot(rawSamples);
%             drawnow;
            %if the data is the incorrect type (wrong polarity) take it again to get the right polarity
            while(rawSamples(1000)<1) %TODO: find the right value here
                fprintf('freq too high %g\n',m);
                [lowNoiseArray(m+1),~,~,rawSamples]=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A'+'B');
%                 change_to_figure(17);
%             plot(rawSamples);
%             drawnow;
            %    missed=1;
            end
            
            %if(rem(m,5000)==0)
            %toc
            %fprintf('measuring %e to %e nanoAmps, iteration %d of %d\n, at %f gate voltage, at %f Kelvin',currentList(k,1),currentList(k,2),m,numCycles,gateVoltageList(m),tempList(i));
            %end
            
            %if(missed)
            %    decreasefrequency(.01);
            %end
            
        %toc
        end
                
        %calcuate the differences going up in current and going down in current
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

    function [noisePower, noisePowerErr] = measureDC(biasV,numSamples,numAvg,numCycles,sampleResistance)
        lowBiasController.value=biasV*(sampleResistance+resistance)/sampleResistance;
        highBiasController.value=biasV*(sampleResistance+resistance)/sampleResistance;
        digitizerCard.setSizeSpectralVoltagePower(numSamples,numAvg);
        digitizerCard.setTriggerDelay(0);
        digitizerCard.setTriggerTimeout(1); %collect data with no delay
        %digitizerCard.pipeline_startSpectralPipeline();
        
        noiseData=zeros(1,numCycles);
        
        for n=1:numCycles
            noiseData(n)=digitizerCard.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');
        end
        noisePower=mean(noiseData);
        noisePowerErr=std(noiseData)/numCycles;
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

    %measure the gain at this temperature by ramping temp up and down a bit
    %also measures the noise temp but we don't care about this
    %the sample bias is zero
    %the gain is the real gain G times the effective bandwidth
    %gainList is a vector of gains that corresponds to the list of gatevoltages
    %temo is the current setpoint
    %deltaT a list of temp differences from the current setpoint over which to measure the gain, i.e. deltaT=[-0.5, -0.3, -0.1, 0.1, 0.3, 0.5]
    function gainList=measureGain(temp,deltaT,myGateVoltageList)
        gainList=zeros(1,length(myGateVoltageList));
        myR=measureResistance();
        lowBiasController.voltage=0;
        highBiasController.voltage=0;
        noise=zeros(length(deltaT),length(myGateVoltageList));
        noiseErr=noise;
        for l=1:length(deltaT)
            setTemperature(temp+delta(l));
            for m=1:length(myGateVoltageList)
                gateController.value=myGateVoltageList(m);
                pause(someNumber);
                [noise(l,m), noiseErr(l,m)]=measureDC(numberOfSamples,numberOfAverages,numberOfGainMeasCycles,myR,gateVoltegeList);
            end
        end
        
        %gainFitData=struct('temp',0,''slope',0,'fit',0,'tempListForFit',0,'noiseListForFit',0);
        %get the linear fit for each gate voltage
        %the slope of the linear fit will give us the gain
        %then make plots for each gate voltage
        for m=1:length(gateVoltageList)
            fitObject=fit(deltaT',noise(:,m),'poly1');
            gainList(m)=fitObject.p1; %p1 is the slope of the fit
            figure(m+100);
            plot(fitObject,deltaT,noise(:,m)');
            gainFitData.temp(i)=temp;
            gainFitData.slope(i,m)=fitObject.p1;
            gainFitData.fit(i,m)=fitObject;
            gainFitData.tempListForFit(i,m,:)=deltaT;
            gainFitData.noiseListForFit(i,m,:)=noise(:,m)';
            gainFitData.noiseListForFitErr(i,m,:)=noiseErr(:,m)';
            title(sprintf('gain linear fit for gate voltage of %f, temp %f',gateVoltageList(m),temp));
            xlabel('delta T(K)');
            ylabel('noise power (W)');
        end
    end

    function res=measureACResistance()
        pause(30*lockInTimeConstant);
        topLockIn.autoSens();
        bottomLockIn.autoSens();
        topVoltage=topLockIn.R;
        bottomVoltage=bottomLockIn.R;
        res=resistance*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
    end

    function rampToGateVoltage(v)
        currentVoltage=gateController.voltage;
        if(v>currentVoltage) %going up in voltage
            currentVoltage=currentVoltage+gateVoltageStep;
            while(currentVoltage<v)
                gateController.voltage=currentVoltage;
                pause(gateVoltageWaitTime);
                currentVoltage=currentVoltage+gateVoltageStep;
            end
            gateController.voltage=v;
            pause(gateVoltageWaitTime);
        else %going down in voltage
            currentVoltage=currentVoltage-gateVoltageStep;
            while(currentVoltage>v)
                gateController.voltage=currentVoltage;
                pause(gateVoltageWaitTime);
                currentVoltage=currentVoltage-gateVoltageStep;
            end
            gateController.voltage=v;
            pause(gateVoltageWaitTime);
        end
    end

end