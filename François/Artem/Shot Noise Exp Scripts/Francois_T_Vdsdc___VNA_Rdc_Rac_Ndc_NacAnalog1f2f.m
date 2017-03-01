%sweep temp and gate, measure DC johnsn noise

function Francois_T_Vdsdc___VNA_Rdc_Rac_Ndc_NacAnalog1f2f(UniqueName, start_dir, numberOfCycles, tempWaitTime,...
        temperatureTolerance, tempRampRate, gateRampRate, VsdControllerRampRate, R_externalAC, R_externalDC, leadResistance, tempList,...
        VdsDCList, VdsACrms_lockIn, lockIn_1f_R_TC, lockIn_1f_Nac_TC, lockIn_2f_Nac_TC,...
        resistanceMeasDCExcitationCurrent, VDCLimit, measWaitTime,vnaWaitTime, VsdOffsetMeasTimeSeconds, voltageMeter_Rdc_waitTimeSeconds,voltageToleranceVolts,hysteresisPresent)
    clear temp StartTime CoolLogData gate;
    close all;
    fclose all;

    %resistanceMeasExcitationCurrentACVrms=1e-6; %1 microAmp;
    
    VsdZeroIndex=find(VdsDCList==0);

    StartTime = clock;
    FileName = strcat('Francois_T_Vg___R_NDCAnalog_', datestr(StartTime, 'yyyy-mm-dd_HH-MM-SS'),'_',UniqueName,'.mat');
    
    dmm=deviceDrivers.Keysight34401A();
    dmm.connect('6');
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');
    tempController.rampRate1=tempRampRate;
    
    switchController=deviceDrivers.YokoGS200();
    switchController.connect('16');
    assert(strcmp(switchController.mode,'VOLT'),'wrong gate source mode');
    %gateController.value=0;
    %gateController.output=1;
    
    biasController_Vdc=deviceDrivers.YokoGS200();
    biasController_Vdc.connect('18');
    assert(strcmp(biasController_Vdc.mode,'VOLT'),'wrong bias source mode');
    
    %drive current through fake resistor
    %measure the voltage drop aross the device
    voltageMeter_Rdc=deviceDrivers.Keithley2000();
    voltageMeter_Rdc.connect('17');
   % assert(strcmp(voltageMeter_Rdc.sense_mode,'VOLT:DC'),'wrong sense mode on Keithley')
    
    TC_1fR=lockIn_1f_R_TC;
    TC_1fN=lockIn_1f_Nac_TC;
    TC_2fN=lockIn_2f_Nac_TC;
    
    lockIn_1f_R=deviceDrivers.SRS830();
    lockIn_1f_R.connect('1');
    lockIn_1f_R.timeConstant=lockIn_1f_R_TC;
    lockIn_1f_R.sineAmp=VdsACrms_lockIn;
    
    %VNA=deviceDrivers.AgilentE8363C;
    %VNA.connect('140.247.189.204');
    %VNA.trigger_source='immediate';
    
    %freqList=VNA.getX;
    %fLength=length(freqList);
    
    lockIn_1f_N=deviceDrivers.SRS830();
    lockIn_1f_N.connect('2');
    lockIn_1f_N.timeConstant=lockIn_1f_Nac_TC;
    
    lockIn_2f_N=deviceDrivers.SRS830();
    lockIn_2f_N.connect('3');
    lockIn_2f_N.timeConstant=lockIn_2f_Nac_TC;

    %estTime=length(tempList)*length(gateVoltageList)*numberOfCycles*cycleTime/60/60+length(tempList)*tempWaitTime/60/60+(max(tempList)-min(tempList))/tempRampRate/60
    
    %initialize everything to NaN so there aren't any zeros when plotting!
    blank2D=zeros(length(tempList),length(VdsDCList))/0;
    %blank3D=zeros(length(tempList),length(VdsDCList),fLength)/0;
    
    %save the experiment settings
    data.settings.VdsDCList=VdsDCList;
    data.settings.leadResistance=leadResistance;
    data.settings.VdsACrms_lockIn=VdsACrms_lockIn;
    data.settings.resistanceMeasExcitationCurrent=resistanceMeasDCExcitationCurrent;
    %data.settings.gateVoltageList=gateVoltageList;
    data.settings.tempList=tempList;
    data.settings.lockIn_1f_R_TC=lockIn_1f_R_TC;
    data.settings.lockIn_1f_Nac_TC=lockIn_1f_Nac_TC;
    data.settings.lockIn_2f_Nac_TC=lockIn_2f_Nac_TC;
    data.settings.numberOfCycles=numberOfCycles;
    data.settings.tempWaitTime=tempWaitTime;
    data.settings.temperatureTolerance=temperatureTolerance;
    data.settings.tempRampRate=tempRampRate;
    data.settings.gateRampRate=gateRampRate;
    data.settings.VsdControllerRampRate=VsdControllerRampRate;
    data.settings.R_externalDC=R_externalDC;
    data.settings.R_externalAC=R_externalAC;
    data.settings.leadResistance=leadResistance;
    %data.settings.gateIndexList_for_T_plot=gateIndexList_for_T_plot;
    data.settings.vnaWaitTime=vnaWaitTime;
    
    %data.freqList=freqList;

    %initialize standard error of the mean arrays
    data.stdErr.Rac1f_X=blank2D;
    data.stdErr.Rac1f_Y=blank2D;
    data.stdErr.Ndc=blank2D;
    data.stdErr.Nac_1f_X=blank2D;
    data.stdErr.Nac_1f_Y=blank2D;
    data.stdErr.Nac_2f_X=blank2D;
    data.stdErr.Nac_2f_Y=blank2D;
    data.stdErr.VsdDC=blank2D;
    data.stdErr.VsdAC_1f_X=blank2D;
    data.stdErr.VsdAC_1f_Y=blank2D;
    data.stdErr.VsdOffset=zeros(1,length(tempList))/0;
    
    %initialize the data arrays
    data.Rdc=blank2D;
    data.Rac1f_X=blank2D;
    data.Rac1f_Y=blank2D;
    data.VsdAC_1f_X=blank2D;
    data.VsdAC_1f_Y=blank2D;
    data.Ndc=blank2D;
    data.Nac_1f_X=blank2D;
    data.Nac_1f_Y=blank2D;
    data.Nac_2f_X=blank2D;
    data.Nac_2f_Y=blank2D;
    data.VsdDC=blank2D;
    %data.vnaTrace=blank3D;
    
    data.time=blank2D;
    data.myClock=zeros(length(tempList),length(VdsDCList),6)/0;
    data.temp=blank2D;
    
    data.VsdOffset=zeros(1,length(tempList))/0;
    
%iterate through the temperatures    
for i=1:length(tempList)   
    %set the temperature and wait until it stabilizes
    FrancoisSetTemperature(tempController, tempList(i), temperatureTolerance);
    biasController_Vdc.ramp2V(0,VsdControllerRampRate);
    pause(tempWaitTime);
    
    %determine the Vsd offset voltage with no bias applied through the DC external resistor
    %i.e. this will come from thermoelectric effects or instrument DC offset
    numCounts=0;
    offsetListCount=[];
    t1=clock;
    lockIn_1f_R.sineAmp=0.004;
    pause(voltageMeter_Rdc_waitTimeSeconds);
    while(etime(clock,t1)<VsdOffsetMeasTimeSeconds)
        numCounts=numCounts+1;
        offsetListCount(numCounts)=voltageMeter_Rdc.fetch;
    end
    
    data.VsdOffset(i)=mean(offsetListCount);
    data.stdErr.VsdOffset(i)=std(offsetListCount)/sqrt(numCounts);
    
        
        %iterate through the bias voltages
        for k=1:length(VdsDCList)
            
            
            if(VdsDCList(k)~=0)
                %set AC to zero
                %set correct current through device to get correct Vds
                %measure resistance
                %set Vac back to what it should be
                lockIn_1f_R.sineAmp=0.004;
                myResistanceDC=rampVdsdcAndGetR_binSearch(VdsDCList(k),VsdControllerRampRate,data.VsdOffset(i));
                data.Rdc(i,k)=myResistanceDC;
                pause(voltageMeter_Rdc_waitTimeSeconds);
                data.VsdDC(i,k)=voltageMeter_Rdc.fetch;
                lockIn_1f_R.sineAmp=VdsACrms_lockIn;
            else
                biasController_Vdc.ramp2V(0,VsdControllerRampRate);
                lockIn_1f_R.sineAmp=0.004;
                data.Rdc(i,k)=NaN;
                pause(voltageMeter_Rdc_waitTimeSeconds);
                data.VsdDC(i,k)=voltageMeter_Rdc.fetch;
                lockIn_1f_R.sineAmp=VdsACrms_lockIn;
            end
            
            
            
            %setSwitch('VNA');
            %VNA.reaverage;
            %pause(vnaWaitTime);
            
            %data.vnaTrace(i,k,:)=measureVNA();
            %setSwitch('amp');
            
            %plot_VNA_vs_T(400);

            pause(measWaitTime);
            
            %average the DC noise and the AC noise simultaneously for numberOfCycles
            %the AC noise is on the lock-ins, and the DC noise is on the voltmeter
            %for every cycle, query the dmm (takes the most time), 1fR lock-in, 1fNAClock-in, 2fNAClock-in
            
            while(measureNoiseData(i,k)==-1)
            end
            
            %make plots
            
            %plot stuff vs Vds for all gate voltages at this temperature
            xnam='V_{sd DC} (V)';
            %plot_stuff_vs_Vdsdc(1,i,data.Rdc,xnam,'R_{DC} (Ohms)');
            plot_stuff_vs_Vdsdc(2,i,data.Rac1f_X,xnam,'R_{AC} (Ohms)');
            plot_stuff_vs_Vdsdc(3,i,data.Ndc,xnam,'DC Noise Power');
            plot_stuff_vs_Vdsdc(4,i,data.Nac_1f_X,xnam,'1f AC Noise Power rms');
            %plot_stuff_vs_Vdsdc(5,i,data.Nac_2f_R,xnam,'2f AC Noise Power rms');
                        
            %xnam3='V_g (V)';
            %for(mmk=1:length(gateVoltageList))
            %    plot_stuff_vs_Vg(200+mmk,i,data.Rdc,xnam3,'R_{DC} (Ohms)')
            %end
            
            xnam2='T(K)';
            plot_stuff_vs_T(100,data.Rdc,xnam2,'R_{DC} (Ohms)')
            plot_stuff_vs_T(101,data.Ndc,xnam2,'Noise Power DC (V)')
            plot_stuff_vs_T(102,data.Rac1f_X,xnam2,'R ac (Ohms)')
            

            
            
        %goto next bias voltage
        end

        save(fullfile(start_dir, FileName),'data');
    
    %goto next temp, end gate voltage for loop
end
%end temp for loop
%end experiment

biasController_Vdc.ramp2V(0,VsdControllerRampRate);

    %amp or Vna
    function setSwitch(instr)
        if(strcmp(instr,'VNA'))
            switchController.value=5;
        elseif(strcmp(instr,'amp'))
            switchController.value=0;
        end
    end

    function trace=measureVNA()
        success=false;
        while(~success)
            try
                VNA.trigger;
                trace=VNA.getSingleTrace;
                success=true;
            catch
                disp('VNA trace failed, trying again');
            end
        end
    end
    
    function status=measureNoiseData(ii,kk)
        dmm.initiate;
        
        status=1;
        dmmVoltages=zeros(1,numberOfCycles);
        VsdDCVoltages=zeros(1,numberOfCycles);
            lockin_1fR_voltagesX=zeros(1,numberOfCycles);
            lockin_1fR_voltagesY=zeros(1,numberOfCycles);
            lockin_1fNAC_voltagesX=zeros(1,numberOfCycles);
            lockin_1fNAC_voltagesY=zeros(1,numberOfCycles);
            lockin_2fNAC_voltagesX=zeros(1,numberOfCycles);
            lockin_2fNAC_voltagesY=zeros(1,numberOfCycles);
            
            c2=clock;

            for(l=1:numberOfCycles)
                lockIn_1f_R.autoSens(0.15,0.95);
                [lockin_1fR_voltagesX(l), lockin_1fR_voltagesY(l)]=lockIn_1f_R.snapXY();
                
                lockIn_1f_N.autoSens(0.001,0.99);
                [lockin_1fNAC_voltagesX(l), lockin_1fNAC_voltagesY(l)]=lockIn_1f_N.snapXY();
                
                lockIn_2f_N.autoSens(0.001,0.99);
                [lockin_2fNAC_voltagesX(l), lockin_2fNAC_voltagesY(l)]=lockIn_2f_N.snapXY();

                dmmVoltages(l)=dmm.fetch; %fetch the DC noise measurement
                dmm.initiate; %start acquiring the next measurement
                VsdDCVoltages(l)=voltageMeter_Rdc.fetch;
            end
            
            eMeasTime=etime(clock,c2);
            
            %number of lock-in time constants elapsed during the measurment
            %this is effectively the number of independent measurements
            nTC_1fR=eMeasTime/TC_1fR;
            nTC_1fN=eMeasTime/TC_1fN;
            nTC_2fN=eMeasTime/TC_2fN;
            
            %calculated the means
            data.Ndc(ii,kk)=mean(dmmVoltages);
            data.Nac_1f_X(ii,kk)=mean(lockin_1fNAC_voltagesX);
            data.Nac_1f_Y(ii,kk)=mean(lockin_1fNAC_voltagesY);

            data.Nac_2f_X(ii,kk)=mean(lockin_2fNAC_voltagesX);
            data.Nac_2f_Y(ii,kk)=mean(lockin_2fNAC_voltagesY);
            data.VsdDC(ii,kk)=mean(VsdDCVoltages);
            
            %calculate the std err of the mean by (st dev)/sqrt(n)
            data.stdErr.Ndc(ii,kk)=mean(dmmVoltages)/sqrt(numberOfCycles);
            data.stdErr.Nac_1f_X(ii,kk)=std(lockin_1fNAC_voltagesX)/sqrt(nTC_1fN);
            data.stdErr.Nac_1f_Y(ii,kk)=std(lockin_1fNAC_voltagesY)/sqrt(nTC_1fN);

            data.stdErr.Nac_2f_X(ii,kk)=std(lockin_2fNAC_voltagesX)/sqrt(nTC_2fN);
            data.stdErr.Nac_2f_Y(ii,kk)=std(lockin_2fNAC_voltagesY)/sqrt(nTC_2fN);
            data.stdErr.VsdDC(ii,kk)=std(VsdDCVoltages)/sqrt(numberOfCycles);
            
            %means and errors for resistance
            topVoltage=lockIn_1f_R.sineAmp;
            bottomVoltageX=mean(lockin_1fR_voltagesX);
            bottomVoltageXErr=std(lockin_1fR_voltagesX)/sqrt(nTC_1fR);
            bottomVoltageY=mean(lockin_1fR_voltagesY);
            bottomVoltageYErr=std(lockin_1fR_voltagesY)/sqrt(nTC_1fR);
            %data.Rac1fR(ii,kk)=R_externalAC*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
            
            data.VsdAC_1f_X(ii,kk)=bottomVoltageX;
            data.VsdAC_1f_Y(ii,kk)=bottomVoltageY;
            data.stdErr.VsdAC_1f_X(ii,kk)=bottomVoltageXErr;
            data.stdErr.VsdAC_1f_Y(ii,kk)=bottomVoltageYErr;
            
            %this takes into account that the DC resistor is quite small, and not much larger than the device resistance
            %and that it affects the current that goes through the device
            data.Rac1f_X(ii,kk)=1/((topVoltage/bottomVoltageX-1)/R_externalAC-1/(R_externalDC+50))-leadResistance;             
            
            data.Rac1f_Y(ii,kk)=1/((topVoltage/bottomVoltageY-1)/R_externalAC-1/(R_externalDC+50))-leadResistance;
            data.stdErr.Rac1f_X(ii,kk)=bottomVoltageXErr*data.Rac1f_X(ii,kk)/bottomVoltageX; %this formula is approx and hopefully correst
            data.stdErr.Rac1f_Y(ii,kk)=bottomVoltageYErr*data.Rac1f_Y(ii,kk)/bottomVoltageY;
            
            data.time(ii,kk)=etime(clock,StartTime); 
            data.myClock(ii,kk,:)=clock;
            data.temp(ii,kk)=tempController.temperatureA;
    end
    
    
    function myResistance=rampVdsdcAndGetR_binSearch(v,speed,offsetVoltage)
        %set an initial excitation current to measure the resistance
        if(v==0)
            biasController_Vdc.ramp2V(resistanceMeasDCExcitationCurrent*R_externalDC,speed);
            pause(0.5);
            myResistance=measureDCResistance(offsetVoltage);
            biasController_Vdc.ramp2V(0,speed);
            return;
        end
        
        condition=true;
        topLim=VDCLimit;
        bottomLim=-VDCLimit;
        countsss=1;
        while(condition)
            v1=voltageMeter_Rdc.fetch-offsetVoltage;
            
            if(v>v1)
                bottomLim=biasController_Vdc.value;
            else %v<v1
                topLim=biasController_Vdc.value;
            end
            vset=(bottomLim+topLim)/2;
            if(hysteresisPresent)
                biasController_Vdc.ramp2V(0,speed);
                pause(0.2);
            end
            biasController_Vdc.ramp2V(vset,speed);
            pause(1.5);
            condition=(abs(voltageMeter_Rdc.fetch-offsetVoltage-v1)>voltageToleranceVolts);
        end
        myResistance=measureDCResistance(offsetVoltage)
    end
    
    function myResistance=rampVdsdcAndGetR_newtonsMethod(v,speed,offsetVoltage)
        if(v~=0)
            %set an initial excitation current to measure the resistance
            if(biasController_Vdc.value==0)
                biasController_Vdc.ramp2V(resistanceMeasDCExcitationCurrent*R_externalDC,speed);
            end
           
            %for(asdf=1:10)
            %use newton's method to converge on correct voltage
            vold=0;
            v1=1;
            while(abs(v1-vold)/v1>0.02)
                pause(0.8);
                vold=v1;
                v1=voltageMeter_Rdc.fetch-offsetVoltage;
                v1
                i1=(biasController_Vdc.value-v1)/R_externalDC;
                
                if(i1<0)
                    biasController_Vdc.ramp2V((i1+resistanceMeasDCExcitationCurrent)*R_externalDC,speed);
                else
                    biasController_Vdc.ramp2V((i1-resistanceMeasDCExcitationCurrent)*R_externalDC,speed);
                end
                
                pause(0.8);
                v2=voltageMeter_Rdc.fetch-offsetVoltage;
                i2=(biasController_Vdc.value-v2)/R_externalDC;
                
                r_ac=(v2-v1)/(i2-i1);
                
                dv=(v-v1)/r_ac*R_externalDC;
                v3=v1+dv;
                
                %%%%%%%%%%%%%%%%%%%%%%  old code %%%%%%%%%%%%%%%
                %myResistance=measureDCResistance(offsetVoltage);
                %now that we have an approximate resistance, set the desired voltage for this datapoint and measure resistance again
                %v2=v*((1/(1/myResistance+1/(R_externalAC+50)))+R_externalDC+leadResistance)*(1/myResistance+1/(R_externalAC+50));
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end old code %%%%%%%%%%%%%%%%%%%%
                
                if(v3>VDCLimit)
                    v3=VDCLimit;
                end
                if(v3<-VDCLimit)
                    v3=-VDCLimit;
                end
                biasController_Vdc.ramp2V(v3,speed);

            end
            pause(0.5);
            myResistance=measureDCResistance(offsetVoltage);
            disp('done with voltage ramping');
        else
            biasController_Vdc.ramp2V(resistanceMeasDCExcitationCurrent*R_externalDC,speed);
            pause(0.5);
            myResistance=measureDCResistance(offsetVoltage);
            biasController_Vdc.ramp2V(0,speed);
        end
    end

    function res=measureDCResistance(offsetVoltage)
        topVoltage=biasController_Vdc.value;
        pause(voltageMeter_Rdc_waitTimeSeconds);
        bottomVoltage=voltageMeter_Rdc.fetch-offsetVoltage;
        res=1/((topVoltage/bottomVoltage-1)/R_externalDC-1/(R_externalAC+50))-leadResistance;
    end

%plot Rdc vs Vds for all gate voltages at this temperature
    function plot_stuff_vs_Vdsdc(figNumber, tempIndex, plotStuff, xL, yL)
        change_to_figure(figNumber); clf; hold on;
        plot(squeeze(data.VsdDC(tempIndex,:)),squeeze(plotStuff(tempIndex,:)));
        xlabel(xL);
        ylabel(yL);
        title(sprintf('T=%g K',tempList(tempIndex)));
    end
    
    function plot_VNA_vs_T(figNumber)
        change_to_figure(figNumber); clf;
        for(ps=1:length(tempList))
            h=semilogy(data.freqList,squeeze(abs(data.vnaTrace(ps,VsdZeroIndex,:))),'LineWidth',1,...
                'MarkerSize',15,...
                'DisplayName',sprintf('%g K',tempList(ps)));
             hold on;
        end
        xlabel('f(hz)');
        ylabel('|S_{11}|=\Gamma');
        title('VNA traces for all temps');
        l = legend('show','Location','best');
    end
    
    
    %plots things vs. T
    %each line on this plot will be for a certain Vsd voltage
    %only one gate voltage is in this plot
    function plot_stuff_vs_T(figNumber,plotStuff, xL, yL)
        change_to_figure(figNumber); clf; hold on;
        for(ps=1:length(VdsDCList))
            h=plot(tempList,plotStuff(:,ps),'-','Color','k');
            h.Color(4) = 0.5;
            set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
        end
        len=length(VdsDCList);
        
        for(ps=1:floor(len/8:len):length(VdsDCList))
            h=plot(tempList,plotStuff(:,ps),'-',...
                'LineWidth',2,...
                'MarkerSize',15,...
                'DisplayName',sprintf('Vsd=%g',VdsDCList(ps)));
        end
        xlabel(xL);
        ylabel(yL);
        title('stuff vs T');
        l = legend('show','Location','best');
    end
    
    %plot stuff vs gate voltage, for a given temp
    %each line will be a differnt Vsd
    function plot_stuff_vs_Vg(figNumber, tempIndex, plotStuff, xL, yL)
        change_to_figure(figNumber); clf; hold on;
        for(ps=1:length(VdsDCList))
            h=plot(tempList,plotStuff(tempIndex,:,ps),'-','Color','k');
            h.Color(4) = 0.5;
            set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
        end
        len=length(VdsDCList);
        
        for(ps=1:floor(len/8:len):length(VdsDCList))
            h=plot(tempList,plotStuff(tempIndex,:,ps),'-',...
                'LineWidth',2,...
                'MarkerSize',15,...
                'DisplayName',sprintf('V_sd=%g V',VdsDCList(gateIndex)));
        end
        xlabel(xL);
        ylabel(yL);
        title(sprintf('V_g=%g V',gateVoltageList(gateIndex)));
        l = legend('show','Location','best');
    end

end