%sweep temp and gate, measure DC johnsn noise

function Francois_T_Vg_Vdsdc___Rdc_Rac_Ndc_NacAnalog(UniqueName, start_dir, numberOfCycles, tempWaitTime, temperatureWindow, tempRampRate, bigResistor, leadResistance, gateVoltageList, tempList, VdsDCList, VdsACrms, lockIn_1f_R_TC, lockIn_1f_Nac_TC, lockIn_2f_Nac_TC, resistanceMeasExcitationCurrent, VDCLimit)
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
    
    biasController_Vdc=deviceDrivers.YokoGS200();
    biasController_Vdc.connect('17');
    assert(strcmp(biasController_Vdc.mode,'VOLT'),'wrong bias source mode');
    
    %drive current through fake resistor
    %measure the voltage drop aross the device
    voltageMeter_Rdc=deviceDrivers.Keithley2450();
    voltageMeter_Rdc.connect('26');
    assert(strcmp(voltageMeter_Rdc.sense_mode,'VOLT:DC'),'wrong sense mode on Keithley')
    
    TC_1fR
    TC_1fN
    TC_2fN
    
    lockIn_1f_R=deviceDrivers.SRS830();
    lockIn_1f_R.connect('1');
    lockIn_1f_R.timeConstant=lockIn_1f_R_TC;
    
    lockIn_1f_N=deviceDrivers.SRS830();
    lockIn_1f_N.connect('2');
    lockIn_1f_N.timeConstant=lockIn_1f_Nac_TC;
    
    lockIn_2f_N=deviceDrivers.SRS830();
    lockIn_2f_N.connect('2');
    lockIn_2f_N.timeConstant=lockIn_2f_Nac_TC;

    
  
    estTime=length(tempList)*length(gateVoltageList)*numberOfCycles*cycleTime/60/60+length(tempList)*tempWaitTime/60/60+(max(tempList)-min(tempList))/tempRampRate/60
    
    

    data=struct('time',0,'myClock',0,'temp',0,'johnsonNoiseDC',0,'johnsonNoiseDCErr',0,'johnsonNoiseAC',0,'johnsonNoiseACErr',0,...
        'tempList',0,'gateVoltageList',0,'VdsdcList',0,'Vdsac',0,...
        'resistanceDC',0,'excitationCurrent',0,'leadResistance',0);
    
    %initialize everything to NaN so there aren't any zeros when plotting!
    %data3D=zeros(length(tempList),length(gateVoltageList),length(lowBiasVoltageList))/0;
    data2D=zeros(length(tempList),length(gateVoltageList))/0;
    data.time=data2D;
    data.VdsDCList=VdsDCList;
    data.myClock=zeros(length(tempList),length(gateVoltageList),6)/0;
    data.temp=data2D;
    
    %todo: initalize data to 3D arrays as needed
    
    data.Rdc=data3D;
    
    data.Rac1fR=data3D;
    data.Rac1fRErr=data3D;
    data.Rac1fTheta=data3D;
    data.Rac1fThetaErr=data3D;
    
    data.Ndc;
    data.NdcErr;
    
    data.Nac_1f_R;
    data.Nac_1f_theta
    data.Nac_1f_RErr;
    data.Nac_1f_thetaErr;
    
    data.Nac_2f_R;
    data.Nac_2f_theta
    data.Nac_2f_RErr;
    data.Nac_2f_thetaErr;
    

    
    data.excitationCurrent=data2D;
    data.dP_P_by_dT=data2D;
    data.johnsonNoise=data2D;
    data.johnsonNoiseErr=data2D;
    data.leadResistance=leadResistance;
    data.VdsAC=VdsACrms;
    
    data.gateVoltageList=gateVoltageList;
    data.tempList=tempList;
    
    figure(1); clf;
    figure(2); clf;
    figure(3); clf;
    figure(4); clf;
    figure(5); clf;
    
%iterate through the temperatures    
for i=1:length(tempList)   
    %set the temperature and wait until it stabilizes
    setTemperature(tempList(i));
  
    %iterate through the gate voltages
    for j=1:length(gateVoltageList)
        fprintf('setting gate voltage to %g, at %g Kelvin...',gateVoltageList(j),tempList(i));
        rampToGateVoltage(gateVoltageList(j));
        fprintf('done setting gate voltage\n');
        
        %iterate through the bias voltages
        for k=1:length(VdsDCList)
            
            %set AC to zero
            %set correct current through device to get correct Vds
            %measure resistance
            %set Vac back to what it should be
            lockIn_1f_R.sineAmp=0;
            myResistanceDC=rampVdsdc(VdsDCList(k));
            data.Rdc(i,j,k)=myResistanceDC;
            data.Vdsdc(i,j,k)=voltageMeter_Rdc.senseVoltage;
            lockIn_1f_R.sineAmp=VdsACrms;
            
            %average the DC noise and the AC noise simultaneously for numberOfCycles
            %the AC noise is on the lock-ins, and the DC noise is on the voltmeter
            %for every cycle, query the dmm (takes the most time), 1fR lock-in, 1fNAClock-in,2fNAClock-in
            
            dmmVoltages=zeros(1,numberOfCycles);
            lockin_1fR_voltagesR=zeros(1,numberOfCycles);
            lockin_1fR_voltagesTheta=zeros(1,numberOfCycles);
            lockin_1fNAC_voltagesR=zeros(1,numberOfCycles);
            lockin_1fNAC_voltagesTheta=zeros(1,numberOfCycles);
            lockin_2fNAC_voltagesR=zeros(1,numberOfCycles);
            lockin_2fNAC_voltagesTheta=zeros(1,numberOfCycles);
            
            c2=clock;
            
            for(l=1:numberOfCycles)
                dmmVoltages(l)=dmm.value;
                lockin_1fR_voltagesR(l)=lockIn_1f_R.R;
                lockin_1fR_voltagesTheta(l)=lockIn_1f_R.theta;
                lockin_1fNAC_voltagesR(l)=lockIn_1f_N.R;
                lockin_1fNAC_voltagesTheta(l)=lockIn_1f_N.theta;
                lockin_2fNAC_voltagesR(l)=lockIn_2f_N.R;
                lockin_2fNAC_voltagesTheta(l)=lockIn_2f_N.theta;
            end
            
            eMeasTime=etime(clock,c2);
            
            %number of lock-in time constants elapsed during the measurment
            %this is effectively the number of independent measurements
            nTC_1fR=eMeasTime/TC_1fR;
            nTC_1fN=eMeasTime/TC_1fN;
            nTC_2fN=eMeasTime/TC_2fN;
            
            %calculated the means
            data.Ndc=mean(dmmVoltages);
            data.Nac_1f_R=mean(lockin_1fNAC_voltagesR);
            data.Nac_1f_theta=mean(lockin_1fNAC_voltagestheta);
            data.Nac_2f_R=mean(lockin_2fNAC_voltagesR);
            data.Nac_2f_theta=mean(lockin_2fNAC_voltagestheta);
            
            %calculate the std err of the mean by (st dev)/sqrt(n)
            data.NdcErr=mean(dmmVoltages)/sqrt(numberOfCycles);
            data.Nac_1f_RErr=std(lockin_1fNAC_voltagesR)/sqrt(nTC_1fN);
            data.Nac_1f_thetaErr=std(lockin_1fNAC_voltagestheta)/sqrt(nTC_1fN);
            data.Nac_2f_RErr=std(lockin_2fNAC_voltagesR)/sqrt(nTC_2fN);
            data.Nac_2f_thetaErr=std(lockin_2fNAC_voltagestheta)/sqrt(nTC_2fN);
            
            %means and errors for resistance
            topVoltage=lockIn_1f_R.sineAmp;
            bottomVoltage=mean(lockin_1fR_voltagesR);
            bottomVoltageErr=std(lockin_1fR_voltagesR)/sqrt(nTC_1fR);
            data.Rac1fR=lockIn_1f_R_resistor*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
            data.Rac1fTheta=mean(lockin_1fR_voltagesTheta);
            data.Rac1fRErr=lockIn_1f_R_resistor*bottomVoltageErr/(topVoltage-bottomVoltageErr)-leadResistance;
            data.Rac1fThetaErr=std(lockin_1fR_voltagesTheta)/sqrt(nTC_1fR);
            
            data.time(i,j,k)=etime(clock,StartTime);
            
            %make plots
            
            %plot Rdc vs Vds for all gate voltages at this temperature
            plot_Rdc_vs_Vdsdc();
            
            %plot Rac vs Vds for all gate voltages at this temperature
            plot_Rac_vs_Vdsdc();
            
            %plot Ndc vs Vds for all gate voltages at this temperature
            plot_Ndc_vs_Vdsdc();
            
            %plot Nac1f vs Vds for all gate voltages at this temperature
            plot_Nac1f_vs_Vdsdc();
            
            %plot Nac2f vs Vds for all gate voltages at this temperature
            plot_Nac2f_vs_Vdsdc();
            
            
        %goto next bias voltage
        end

        change_to_figure(4);
        plot(gateVoltageList,data.resistance','.-');
        
        change_to_figure(2);
        clf
        errorbar(tempList(1:i),data.johnsonNoise(1:i,:),data.johnsonNoiseErr(1:i,:));

        save(fullfile(start_dir, FileName),'data');

    %goto next gate voltage
    end 
    
    %goto next temp, end gate voltage for loop
end
%end temp for loop
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

    function rampToGateVoltage(v, speed)
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

    function myResistance=rampVdsdc(v,speed)
        %set an initial excitation current to measure the resistance
        biasController_Vdc.value=resistanceMeasExcitationCurrent*bigResistor;
        pause(0.2);
        
        if(v~=0)
            for(asdf=1:6)
                myResistance=measureDCResistance();
                %now that we have an approximate resistance, set the desired voltage for this datapoint and measure resistance again
                v2=v*(myResistance+bigResistor+leadResistance)/myResistance;
                if(v2>VDCLimit)
                    v2=VDCLimit;
                end
                if(v2<-VDCLimit)
                    v2=-VDCLimit;
                end
                biasController_Vdc.value=v2;
                pause(0.2);
            end
            
            myResistance=measureDCResistance();
        else
            biasController_Vdc.value=0;
            pause(0.3);
        end
    end

    function res=measureDCResistance()
        topVoltage=biasController_Vdc.value;
        bottomVoltage=voltageMeter_Rdc.senseVoltage;
        res=resistance*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
    end

%plot Rdc vs Vds for all gate voltages at this temperature
    function plot_Rdc_vs_Vdsdc(tempIndex)
        change_to_figure(1);
        hold on;
        for(bob=1:length(gateVoltageList))
            plot(squeeze(data.Vdsdc(tempIndex,bob,:)),squeeze(data.Rdc(tempIndex,bob,:)));
        end
    end

%plot Rac vs Vds for all gate voltages at this temperature
    function plot_Rac_vs_Vdsdc(tempIndex)
        change_to_figure(2);
        hold on;
        for(bob=1:length(gateVoltageList))
            plot(squeeze(data.Vdsdc(tempIndex,bob,:)),squeeze(data.Rac(tempIndex,bob,:)));
        end
    end

%plot Ndc vs Vds for all gate voltages at this temperature
    function plot_Ndc_vs_Vdsdc(tempIndex)
        change_to_figure(3);
        hold on;
        for(bob=1:length(gateVoltageList))
            plot(squeeze(data.Vdsdc(tempIndex,bob,:)),squeeze(data.Ndc(tempIndex,bob,:)));
        end
    end

%plot Nac1f vs Vds for all gate voltages at this temperature
    function plot_Nac1f_vs_Vdsdc(tempIndex)
        change_to_figure(4);
        hold on;
        for(bob=1:length(gateVoltageList))
            plot(squeeze(data.Vdsdc(tempIndex,bob,:)),squeeze(data.Nac1f(tempIndex,bob,:)));
        end
    end

%plot Nac2f vs Vds for all gate voltages at this temperature
    function plot_Nac2f_vs_Vdsdc(tempIndex)
        change_to_figure(5);
        hold on;
        for(bob=1:length(gateVoltageList))
            plot(squeeze(data.Vdsdc(tempIndex,bob,:)),squeeze(data.Nac2f(tempIndex,bob,:)));
        end
    end

end