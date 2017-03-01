%sweep temp and gate, measure DC johnsn noise

function Francois_T_Vg_Vdsdc___Rdc_Rac_Ndc_NacAnalog(UniqueName, start_dir, numberOfCycles, tempWaitTime,...
        temperatureTolerance, tempRampRate, gateRampRate, VsdControllerRampRate, R_externalAC, R_externalDC, leadResistance, gateVoltageList, tempList,...
        VdsDCList, VdsACrms_lockIn, lockIn_1f_R_TC, lockIn_1f_Nac_TC, lockIn_2f_Nac_TC,...
        resistanceMeasExcitationCurrent, VDCLimit, gateIndexList_for_T_plot, measWaitTime)
    clear temp StartTime CoolLogData gate;
    close all;
    fclose all;

    %resistanceMeasExcitationCurrentACVrms=1e-6; %1 microAmp;

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
    voltageMeter_Rdc=deviceDrivers.Keithley2000();
    voltageMeter_Rdc.connect('217');
   % assert(strcmp(voltageMeter_Rdc.sense_mode,'VOLT:DC'),'wrong sense mode on Keithley')
    
    TC_1fR=lockIn_1f_R_TC;
    TC_1fN=lockIn_1f_Nac_TC;
    TC_2fN=lockIn_2f_Nac_TC;
    
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
    
    %initialize everything to NaN so there aren't any zeros when plotting!
    blank3D=zeros(length(tempList),length(gateVoltageList),length(VdsDCList))/0;
    
    %save the experiment settings
    data.settings.VdsDCList=VdsDCList;
    data.settings.leadResistance=leadResistance;
    data.settings.VdsAC=VdsACrms_lockIn;
    data.settings.resistanceMeasExcitationCurrent=resistanceMeasExcitationCurrent;
    data.settings.gateVoltageList=gateVoltageList;
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
    data.settings.gateIndexList_for_T_plot=gateIndexList_for_T_plot;

    %initialize standard error of the mean arrays
    data.stdErr.Rac1fR=blank3D;
    data.stdErr.Rac1fTheta=blank3D;
    data.stdErr.Ndc=blank3D;
    data.stdErr.Nac_1f_R=blank3D;
    data.stdErr.Nac_1f_theta=blank3D;
    data.stdErr.Nac_2f_R=blank3D;
    data.stdErr.Nac_2f_theta=blank3D;
    data.stdErr.VsdDC=blank3D;
    
    %initialize the data arrays
    data.Rdc=blank3D;
    data.Rac1fR=blank3D;
    data.Rac1fTheta=blank3D;
    data.Ndc=blank3D;
    data.Nac_1f_R=blank3D;
    data.Nac_1f_theta=blank3D;
    data.Nac_2f_R=blank3D;
    data.Nac_2f_theta=blank3D;
    data.VsdDC=blank3D;
    
    data.time=blank3D;
    data.myClock=zeros(length(tempList),length(gateVoltageList),length(VdsDCList),6)/0;
    data.temp=blank3D;
    
    figure(1); clf;
    figure(2); clf;
    figure(3); clf;
    figure(4); clf;
    figure(5); clf;
    
%iterate through the temperatures    
for i=1:length(tempList)   
    %set the temperature and wait until it stabilizes
    FrancoisSetTemperature(tc, tempList(i), temperatureTolerance);
    pause(tempWaitTime);
  
    %iterate through the gate voltages
    for j=1:length(gateVoltageList)
        fprintf('setting gate voltage to %g, at %g Kelvin...',gateVoltageList(j),tempList(i));
        gateController.ramp2V(gateVoltageList(j),gateRampRate);
        fprintf('done setting gate voltage\n');
        
        %iterate through the bias voltages
        for k=1:length(VdsDCList)
            
            %set AC to zero
            %set correct current through device to get correct Vds
            %measure resistance
            %set Vac back to what it should be
            lockIn_1f_R.sineAmp=0;
            myResistanceDC=rampVdsdcAndGetR(VdsDCList(k),VsdControllerRampRate);
            data.Rdc(i,j,k)=myResistanceDC;
            data.Vdsdc(i,j,k)=voltageMeter_Rdc.read;
            lockIn_1f_R.sineAmp=VdsACrms_lockIn;
            
            pause(measWaitTime);
            
            
            %average the DC noise and the AC noise simultaneously for numberOfCycles
            %the AC noise is on the lock-ins, and the DC noise is on the voltmeter
            %for every cycle, query the dmm (takes the most time), 1fR lock-in, 1fNAClock-in,2fNAClock-in
            
            while(measureData(i,j,k)==-1)
            end
            
            %make plots
            
            %plot stuff vs Vds for all gate voltages at this temperature
            xnam='V_{sd DC} (V)';
            plot_stuff_vs_Vdsdc(1,i,data.Rdc,xnam,'R_{DC} (Ohms)');
            plot_stuff_vs_Vdsdc(2,i,data.Rac,xnam,'R_{AC} (Ohms)');
            plot_stuff_vs_Vdsdc(3,i,data.Ndc,xnam,'DC Noise Power');
            plot_stuff_vs_Vdsdc(4,i,data.Nac1f,xnam,'1f AC Noise Power rms');
            plot_stuff_vs_Vdsdc(5,i,data.Nac2f,xnam,'2f AC Noise Power rms');
                        
            xnam3='V_g (V)';
            for(mmk=1:length(gateVoltageList))
                plot_stuff_vs_Vg(200+mmk,i,data.Rdc,xnam3,'R_{DC} (Ohms)')
            end
            
            xnam2='T(K)';
            for(mmk=1:length(gateIndexList_for_T_plot))
                plot_stuff_vs_T(100+mmk,j,data.Rdc,xnam2,'R_{DC} (Ohms)')
            end

            
            
        %goto next bias voltage
        end

        save(fullfile(start_dir, FileName),'data');

    %goto next gate voltage
    end 
    
    %goto next temp, end gate voltage for loop
end
%end temp for loop
%end experiment

    function status=measureData(ii,jj,kk)
        dmm.initiate;
        
        status=1;
        dmmVoltages=zeros(1,numberOfCycles);
        VsdDCVoltages=zeros(1,numberOfCycles);
            lockin_1fR_voltagesR=zeros(1,numberOfCycles);
            lockin_1fR_voltagesTheta=zeros(1,numberOfCycles);
            lockin_1fNAC_voltagesR=zeros(1,numberOfCycles);
            lockin_1fNAC_voltagesTheta=zeros(1,numberOfCycles);
            lockin_2fNAC_voltagesR=zeros(1,numberOfCycles);
            lockin_2fNAC_voltagesTheta=zeros(1,numberOfCycles);
            
            c2=clock;
            
            lockIn_1f_R_sens=lockIn_1f_R.sens();
            lockIn_1f_NAC_sens=lockIn_1f_N.sens();
            lockIn_2f_NAC_sens=lockIn_2f_N.sens();
            
            for(l=1:numberOfCycles)
                
                lockin_1fR_voltagesR(l)=lockIn_1f_R.R;
                lockin_1fR_voltagesTheta(l)=lockIn_1f_R.theta;
                lockin_1fNAC_voltagesR(l)=lockIn_1f_N.R;
                lockin_1fNAC_voltagesTheta(l)=lockIn_1f_N.theta;
                lockin_2fNAC_voltagesR(l)=lockIn_2f_N.R;
                lockin_2fNAC_voltagesTheta(l)=lockIn_2f_N.theta;
                
                %check in range; if out of range return -1 and take measurement series again
                if (lockin_1fR_voltagesR(l) > lockIn_1f_R_sens*0.95 || lockin_1fR_voltagesR(l) < lockIn_1f_R_sens*0.15)
                    disp('Lock-in 1fR out of range. Autoranging.');
                    lockIn_1f_R.autoSens(0.25,0.75);
                    status=-1;
                    return;
                end
                
                %check in range
                if (lockin_1fNAC_voltagesR(l) > lockIn_1f_NAC_sens*0.95 || lockin_1fNAC_voltagesR(l) < lockIn_1f_NAC_sens*0.15)
                    disp('Lock-in 1fNAC out of range. Autoranging.');
                    lockIn_1f_N.autoSens(0.25,0.75);
                    status=-1;
                    return;
                end
                
                %check in range
                if (lockin_2fNAC_voltagesR(l) > lockIn_2f_NAC_sens*0.95 || lockin_2fNAC_voltagesR(l) < lockIn_2f_NAC_sens*0.15)
                    disp('Lock-in 2fNAC out of range. Autoranging.');
                    lockIn_2f_N.autoSens(0.25,0.75);
                    status=-1;
                    return;
                end
                dmmVoltages(l)=dmm.fetch;
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
            data.Ndc(ii,jj,kk)=mean(dmmVoltages);
            data.Nac_1f_R(ii,jj,kk)=mean(lockin_1fNAC_voltagesR);
            data.Nac_1f_theta(ii,jj,kk)=mean(lockin_1fNAC_voltagestheta);
            data.Nac_2f_R(ii,jj,kk)=mean(lockin_2fNAC_voltagesR);
            data.Nac_2f_theta(ii,jj,kk)=mean(lockin_2fNAC_voltagestheta);
            data.VsdDC(ii,jj,kk)=mean(VsdDCVoltages);
            
            %calculate the std err of the mean by (st dev)/sqrt(n)
            data.stdErr.Ndc(ii,jj,kk)=mean(dmmVoltages)/sqrt(numberOfCycles);
            data.stdErr.Nac_1f_R(ii,jj,kk)=std(lockin_1fNAC_voltagesR)/sqrt(nTC_1fN);
            data.stdErr.Nac_1f_theta(ii,jj,kk)=std(lockin_1fNAC_voltagestheta)/sqrt(nTC_1fN);
            data.stdErr.Nac_2f_R(ii,jj,kk)=std(lockin_2fNAC_voltagesR)/sqrt(nTC_2fN);
            data.stdErr.Nac_2f_theta(ii,jj,kk)=std(lockin_2fNAC_voltagestheta)/sqrt(nTC_2fN);
            data.stdErr.VsdDC(ii,jj,kk)=std(VsdDCVoltages)/sqrt(numberOfCycles);
            
            %means and errors for resistance
            topVoltage=lockIn_1f_R.sineAmp;
            bottomVoltage=mean(lockin_1fR_voltagesR);
            bottomVoltageErr=std(lockin_1fR_voltagesR)/sqrt(nTC_1fR);
            %data.Rac1fR(ii,jj,kk)=R_externalAC*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
            
            %this takes into account that the DC resistor is quite small, and not much larger than the device resistance
            %and that it affects the current that goes through the device
            data.Rac1fR(ii,jj,kk)=1/((topVoltage/bottomVoltage-1)/R_externalAC-1/(R_externalDC+50))-leadResistance;             
            
            data.Rac1fTheta(ii,jj,kk)=mean(lockin_1fR_voltagesTheta);
            data.stdErr.Rac1fR(ii,jj,kk)=bottomVoltageErr*data.Rac1fR/bottomVoltage; %this formula is approx and hopefully correst
            data.stdErr.Rac1fTheta(ii,jj,kk)=std(lockin_1fR_voltagesTheta)/sqrt(nTC_1fR);
            
            data.time(ii,jj,kk)=etime(clock,StartTime); 
            data.myClock(ii,jj,kk,:)=clock;
            data.temp(ii,jj,kk)=tempController.temperatureA;
    end
    
    function myResistance=rampVdsdcAndGetR(v,speed)
        %set an initial excitation current to measure the resistance
        biasController_Vdc.value=resistanceMeasExcitationCurrent*R_externalDC;
        pause(0.2);
        
        if(v~=0)
            for(asdf=1:6)
                myResistance=measureDCResistance();
                %now that we have an approximate resistance, set the desired voltage for this datapoint and measure resistance again
                v2=v*(myResistance+R_externalDC+leadResistance)/myResistance;
                if(v2>VDCLimit)
                    v2=VDCLimit;
                end
                if(v2<-VDCLimit)
                    v2=-VDCLimit;
                end
                biasController_Vdc.ramp2V(v2,speed);
                pause(0.2);
            end
            
            myResistance=measureDCResistance();
        else
            biasController_Vdc.ramp2V(0,speed);
            pause(0.3);
        end
    end

    function res=measureDCResistance()
        topVoltage=biasController_Vdc.value;
        bottomVoltage=voltageMeter_Rdc.read;
        res=resistance*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
    end

%plot Rdc vs Vds for all gate voltages at this temperature
    function plot_stuff_vs_Vdsdc(figNumber, tempIndex, plotStuff, xL, yL)
        change_to_figure(figNumber); clf; hold on;
        for(bob=1:length(gateVoltageList))
            plot(squeeze(data.Vdsdc(tempIndex,bob,:)),squeeze(plotStuff(tempIndex,bob,:)));
        end
        xlabel(xL);
        ylabel(yL);
        title(sprintf('T=%g K',tempList(tempIndex)));
    end
    
    %plots things vs. T
    %each line on this plot will be for a certain Vsd voltage
    %only one gate voltage is in this plot
    function plot_stuff_vs_T(figNumber,gateIndex,plotStuff, xL, yL)
        change_to_figure(figNumber); clf; hold on;
        for(ps=1:length(VdsDCList))
            h=plot(tempList,plotStuff(:,gateIndex,ps),'-','Color','k');
            h.Color(4) = 0.5;
            set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
        end
        len=length(VdsDCList);
        
        for(ps=1:int32(len/8:len):length(VdsDCList))
            h=plot(tempList,plotStuff(:,gateIndex,ps),'-',...
                'LineWidth',2,...
                'MarkerSize',15,...
                'DisplayName',sprintf('V_sd=%g V',VdsDCList(gateIndex)));
        end
        xlabel(xL);
        ylabel(yL);
        title(sprintf('V_g=%g V',gateVoltageList(gateIndex)));
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
        
        for(ps=1:int32(len/8:len):length(VdsDCList))
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