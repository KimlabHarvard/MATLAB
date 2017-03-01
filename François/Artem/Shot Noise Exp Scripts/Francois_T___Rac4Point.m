%sweep temp and gate, measure DC johnsn noise

%%device

%contact 1 --- lockin 1 input --- resistor ---lockin 1 AC voltage source
%contact 2 --- lockin 2 A
%contact 3 --- lockin 2 B
%contact 4 --- warm ground

function Francois_T___Rac4Point(UniqueName, start_dir, numberOfCycles, tempWaitTime,...
        temperatureTolerance, tempRampRate, R_externalAC, tempList,...
        VdsACrms_lockIn, lockIn_1f_R_TC,...
        measWaitTime)
    clear temp StartTime CoolLogData gate;
    close all;
    fclose all;

    
    StartTime = clock;
    FileName = strcat('Francois_T_Vg___R_NDCAnalog_', datestr(StartTime, 'yyyy-mm-dd_HH-MM-SS'),'_',UniqueName,'.mat');
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');
    tempController.rampRate1=tempRampRate;
    
    TC_1fR=lockIn_1f_R_TC;
    
    lockIn_1f_I=deviceDrivers.SRS830();
    lockIn_1f_I.connect('1');
    lockIn_1f_I.timeConstant=lockIn_1f_R_TC;
    lockIn_1f_I.sineAmp=VdsACrms_lockIn;
    
    lockIn_1f_V=deviceDrivers.SRS830();
    lockIn_1f_V.connect('2');
    lockIn_1f_V.timeConstant=lockIn_1f_R_TC;
    
    %VNA=deviceDrivers.AgilentE8363C;
    %VNA.connect('140.247.189.204');
    %VNA.trigger_source='immediate';
    
    %freqList=VNA.getX;
    %fLength=length(freqList);
    
    %estTime=length(tempList)*length(gateVoltageList)*numberOfCycles*cycleTime/60/60+length(tempList)*tempWaitTime/60/60+(max(tempList)-min(tempList))/tempRampRate/60
    
    %initialize everything to NaN so there aren't any zeros when plotting!
    blank1D=zeros(1,length(tempList))/0;
    %blank3D=zeros(length(tempList),length(VdsDCList),fLength)/0;
    
    %save the experiment settings
    data.settings.VdsACrms_lockIn=VdsACrms_lockIn;
    %data.settings.gateVoltageList=gateVoltageList;
    data.settings.tempList=tempList;
    data.settings.lockIn_1f_R_TC=lockIn_1f_R_TC;
    data.settings.numberOfCycles=numberOfCycles;
    data.settings.tempWaitTime=tempWaitTime;
    data.settings.temperatureTolerance=temperatureTolerance;
    data.settings.tempRampRate=tempRampRate;
    data.settings.R_externalAC=R_externalAC;
    data.settings.Iac=VdsACrms_lockIn/R_externalAC;
    %data.settings.gateIndexList_for_T_plot=gateIndexList_for_T_plot;
    
    %data.freqList=freqList;
    
    %initialize standard error of the mean arrays
    data.stdErr.Rac1f_2pt_X=blank1D;
    data.stdErr.Rac1f_2pt_Y=blank1D;
    data.stdErr.Rac1f_4pt_X=blank1D;
    data.stdErr.Rac1f_4pt_Y=blank1D;
    data.stdErr.VsdACV_1f_X=blank1D;
    data.stdErr.VsdACV_1f_Y=blank1D;
    data.stdErr.VsdACI_1f_X=blank1D;
    data.stdErr.VsdACI_1f_Y=blank1D;
    
    %initialize the data arrays
    data.Rac1f_2pt_X=blank1D;
    data.Rac1f_2pt_Y=blank1D;
    data.Rac1f_4pt_X=blank1D;
    data.Rac1f_4pt_Y=blank1D;
    data.VsdACV_1f_X=blank1D;
    data.VsdACV_1f_Y=blank1D;
    data.VsdACI_1f_X=blank1D;
    data.VsdACI_1f_Y=blank1D;
    %data.vnaTrace=blank3D;
    
    data.time=blank1D;
    data.myClock=zeros(length(tempList),6)/0;
    data.temp=blank1D;
    
    %iterate through the temperatures
    for i=1:length(tempList)
        %set the temperature and wait until it stabilizes
        FrancoisSetTemperature(tempController, tempList(i), temperatureTolerance);
        pause(tempWaitTime);
        
        
        pause(measWaitTime);
        
        
        while(measureRData(i)==-1)
        end
        
        %make plots
        xnam2='T(K)';
        plot_stuff_vs_T(102,data.Rac1f_2pt_X,xnam2,'R ac 2 point (Ohms)')
        plot_stuff_vs_T(103,data.Rac1f_4pt_X,xnam2,'R ac 4 point (Ohms)')
        
        
        save(fullfile(start_dir, FileName),'data');
        
        %goto next temp, end gate voltage for loop
    end
    %end temp for loop
    %end experiment
    
    function status=measureRData(ii)
        
        lockIn_1f_I.autoSens(0.2,0.9);
        lockIn_1f_V.autoSens(0.2,0.9);
        
        status=1;
        
        lockin_1fI_voltagesX=zeros(1,numberOfCycles);
        lockin_1fI_voltagesY=zeros(1,numberOfCycles);
        
        lockin_1fV_voltagesX=zeros(1,numberOfCycles);
        lockin_1fV_voltagesY=zeros(1,numberOfCycles);
        
        c2=clock;
        
        for(l=1:numberOfCycles)
            lockIn_1f_I.autoSens(0.2,0.9);
            [lockin_1fI_voltagesX(l), lockin_1fI_voltagesY(l)]=lockIn_1f_I.snapXY();
            
            lockIn_1f_V.autoSens(0.2,0.9);
            [lockin_1fV_voltagesX(l), lockin_1fV_voltagesY(l)]=lockIn_1f_V.snapXY();
            
            pause(lockIn_1f_R_TC);
        end
        
        eMeasTime=etime(clock,c2);
        
        %number of lock-in time constants elapsed during the measurment
        %this is effectively the number of independent measurements
        nTC_1fR=eMeasTime/TC_1fR;
        
        
        
        %means and errors for resistance
        
        %src voltage is the lockin ouput voltage
        srcVoltage=lockIn_1f_I.sineAmp;
        
        %top voltage is the voltage at contact 1, so doing a 2-pt R measurement at contacts 1 and 4
        topVoltageX=mean(lockin_1fI_voltagesX);
        topVoltageXErr=std(lockin_1fI_voltagesX)/sqrt(nTC_1fR);
        topVoltageY=mean(lockin_1fI_voltagesY);
        topVoltageYErr=std(lockin_1fI_voltagesY)/sqrt(nTC_1fR);
        
        myCurrentX=(srcVoltage-topVoltageX)/R_externalAC
        myCurrentY=(srcVoltage-topVoltageY)/R_externalAC;
        
        %dVotlage is the voltage difference (A-B) of contacts 2 and 3
        dVoltageX=mean(lockin_1fV_voltagesX);
        dVoltageXErr=std(lockin_1fV_voltagesX)/sqrt(nTC_1fR);
        dVoltageY=mean(lockin_1fV_voltagesY);
        dVoltageYErr=std(lockin_1fV_voltagesY)/sqrt(nTC_1fR);
        
        data.Rac1f_2pt_X(ii)=R_externalAC*topVoltageX/(srcVoltage-topVoltageX);
        data.Rac1f_2pt_Y(ii)=R_externalAC*topVoltageY/(srcVoltage-topVoltageY);
        
        data.Rac1f_4pt_X(ii)=dVoltageX/myCurrentX;
        data.Rac1f_4pt_Y(ii)=dVoltageY/myCurrentY;
        
        
        data.VsdACI_1f_X(ii)=topVoltageX;
        data.VsdACI_1f_Y(ii)=topVoltageY;
        data.VsdACV_1f_X(ii)=dVoltageX;
        data.VsdACV_1f_Y(ii)=dVoltageY;
        
        data.stdErr.VsdACI_1f_X(ii)=topVoltageXErr;
        data.stdErr.VsdACI_1f_Y(ii)=topVoltageYErr;
        data.stdErr.VsdACV_1f_X(ii)=dVoltageXErr;
        data.stdErr.VsdACV_1f_Y(ii)=dVoltageYErr;
        
        
        data.time(ii)=etime(clock,StartTime);
        data.myClock(ii,:)=clock;
        data.temp(ii)=tempController.temperatureA;
    end
    
    
    %plots things vs. T
    %each line on this plot will be for a certain Vsd voltage
    %only one gate voltage is in this plot
    function plot_stuff_vs_T(figNumber,plotStuff, xL, yL)
        change_to_figure(figNumber); clf; hold on;
        h=plot(tempList,plotStuff,'-',...
            'LineWidth',2,...
            'MarkerSize',15,...
            'DisplayName',sprintf('.'));
        xlabel(xL);
        ylabel(yL);
        title('.');
        l = legend('show','Location','best');
    end
    
    
end