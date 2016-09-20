%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% designed for calibration of johnson noise in oxford
% Created in Sep 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Oxford_Nac_Ndc_R_T__T_B_Vg(T_list, B_list,Vg_list, Vg_limit, Vg_rampRate,...
    Nmeasurements, VWaitTime1, VWaitTime2, measurementWaitTime, SD_Rex, ...
    SD_Vex, TvaporRampRate, TprobeRampRate, PID, UniqueName)
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%     Internal convenience functions    %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot1Dconductance(i,j)
        change_to_figure(991); clf;
        plot(data.Vg, squeeze(25813./data.R(i,j,:)),'.','MarkerSize',15);
        xlabel('Vg (Volts)');ylabel('Conductance (h/e^2)');
        box on; grid on;
    end
    function plot1Dnoise(T_n,B_n)
        change_to_figure(992); clf; hold all;
        for i=1:T_n
            VNdc = squeeze(data.VNdc(i,B_n,:));
            mask = find(VNdc ~= 0);
            plot(data.Vg(mask), VNdc(mask),'.','MarkerSize',15);
        end
        xlabel('Vg (Volts)');ylabel('V_{noise}');
        box on; grid on;
    end
    function plot2Dresistance(i)
        change_to_figure(993); clf;
        surf(data.Vg,data.B,squeeze(data.R(i,:,:)));
        xlabel('Vg (Volts)');ylabel('Field (T)');
        view(2);shading flat; colorbar; box on; colormap(flipud(cmap));
    end
    function plotLog()
        change_to_figure(994); clf; grid on; hold on; xlabel('time (hr)');
        
        [ax,h1,h2] = plotyy(data.log.time/3600,data.log.field,data.log.time/3600,data.log.Tprobe);
        set(h1,'LineStyle','--','Marker','o');
        set(h2,'LineStyle','--','Marker','o');
        
        axes(ax(1));hold on;h4=plot(data.log.time/3600,data.log.persistfield,'--oc');ylim(ax(1),'auto');
        axes(ax(1));hold on;h5=plot(data.log.time/3600,data.log.B_set,'-c');ylim(ax(1),'auto');
        
        axes(ax(2));hold on;h3=plot(data.log.time/3600,data.log.Tvapor,'--or');ylim(ax(2),'auto');
        axes(ax(2));hold on;h6=plot(data.log.time/3600,data.log.T_set,'-y');ylim(ax(2),'auto');
        
        ylabel(ax(1),'Field (Tesla)');
        ylabel(ax(2),'Temperature (K)');
        legend([h1 h4 h5 h2 h3 h6],'Field','Persistent Field','B setpoint','T Probe','T Vapor','T setpoint','Location','NorthWest');
    end

%measures the data
    function measure_data(i,j,k)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(i,j,k,n) = etime(clock, StartTime);
            data.raw.Tvapor(i,j,k,n) = TC.temperatureA();
            data.raw.Tprobe(i,j,k,n) = TC.temperatureB();
            [data.raw.Vsd_X(i,j,k,n), data.raw.Vsd_Y(i,j,k,n)] = SD.snapXY();
            Vsd = sqrt(data.raw.Vsd_X(i,j,k,n)^2+data.raw.Vsd_Y(i,j,k,n)^2);
            data.raw.R(i,j,k,n) = Vsd*SD_Rex/(SD_Vex-Vsd);
            data.raw.VNdc(i,j,k,n) = Ndc.senseVoltage();
            
            
            %check if we are between 5% and 95% of the range, if not autoSens
            high = max(data.raw.Vsd_X(i,j,k,n),data.raw.Vsd_Y(i,j,k,n));
            if high > SD_sens*0.95 || high < SD_sens*0.05
                SD.autoSens(0.25,0.75);
                SD_sens = SD.sens();
            else
                %if the measurement was good, increment.
                n = n+1;
            end
        end
        data.time(i,j,k) = mean(data.raw.time(i,j,k,:));
        data.Vsd_X(i,j,k) = mean(data.raw.Vsd_X(i,j,k,:));
        data.Vsd_Y(i,j,k) = mean(data.raw.Vsd_Y(i,j,k,:));
        data.R(i,j,k) = mean(data.raw.R(i,j,k,:));
        data.Tvapor(i,j,k) = mean(data.raw.Tvapor(i,j,k,:));
        data.Tprobe(i,j,k) = mean(data.raw.Tprobe(i,j,k,:));
        data.VNdc(i,j,k) = mean(data.raw.VNdc(i,j,k,:));
        data.std.Vsd_X(i,j,k) = std(data.raw.Vsd_X(i,j,k,:));
        data.std.Vsd_Y(i,j,k) = std(data.raw.Vsd_Y(i,j,k,:));
        data.std.R(i,j,k) = std(data.raw.R(i,j,k,:));
        data.Tvapor(i,j,k) = mean(data.raw.Tvapor(i,j,k,:));
        data.Tprobe(i,j,k) = mean(data.raw.Tprobe(i,j,k,:));
        data.std.VNdc(i,j,k) = std(data.raw.VNdc(i,j,k,:));
    end

    function save_data()
        save(fullfile(start_dir, [FileName, '.mat']),'data');
    end

%keep a running track of all parameters vs time
    function timeLog()
        data.log.time = [data.log.time etime(clock, StartTime)];
        data.log.Tvapor = [data.log.Tvapor TC.temperatureA];
        data.log.Tprobe = [data.log.Tprobe TC.temperatureB];
        [X,Y] = SD.snapXY();
        data.log.SD_X = [data.log.SD_X X];
        data.log.SD_Y = [data.log.SD_Y Y];
        data.log.R = [data.log.R sqrt(X^2+Y^2)*SD_Rex/SD_Vex];
        data.log.T_set=[data.log.T_set T_set];
        data.log.B_set=[data.log.B_set target_field];
        data.log.field = [data.log.field MS.measuredField()];
        data.log.persistfield = [data.log.persistfield MS.persistentField()];
    end
    function updateProgressMonitor()
        pm_handles.Tvapor.String = sprintf('%.1f K',TC.temperatureA);
        pm_handles.Tprobe.String = sprintf('%.1f K',TC.temperatureB);
        pm_handles.Field.String = sprintf('%.1f T',MS.measuredField);
        pm_handles.Vgate.String = sprintf('%.3f V',VG.value);
    end

%run until temperature is stable around setpoint
    function stabilizeTemperature(setPoint,time,tolerance)
        %temperature should be with +- tolerance in K for time seconds
        Tmonitor = 999*ones(1,time*10);
        n_mon = 0;
        t1 = clock;
        t2 = t1;
        while max(Tmonitor)>tolerance
            Tmonitor(1,mod(n_mon,time*10)+1)=abs(TC.temperatureB()-setPoint);
            n_mon=n_mon+1;
            if etime(clock,t2) >= timeLogInterval
                t2 = clock;
                timeLog();
                plotLog();
                pause(0.01);
            end
            while etime(clock,t1) < 0.1
            end
            t1 = clock; %pause which accounts for measurement/plotting time
        end
    end


% emergency Fill results in an immediate ramp down to 0 T and then a pause
% Once helium has been refilled, press F5 to ramp back up and resume
% This will retake the current gate sweep
    function emergencyFill()
        target_field = 0;
        MS.switchHeater = 1;
        MS.targetField = target_field;
        MS.goToTargetField();
        while MS.sweepStatus() ~= 0
            pause(timeLogInterval);
            timeLog();
            plotLog();
        end
        MS.switchHeater = 0;
        VG.ramp2V(0,Vg_rampRate);
        %pause for filling, then reset the button
        emFill.String = 'F5 to resume';
        eval('keyboard'); %pause command
        emFill.String = 'Emergency Fill';
        emFill.Value = 0;
    end
%saftey checks (more checks below)
assert(max(abs(Vg_list)) <= Vg_limit,'Gate voltage set above 32 V');
assert(max(abs(B_list)) <= 13, 'field set above 13 T');
pause on;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%     Configurable parameters     %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%set constants
timeLogInterval = 5;    %seconds between logging field and Temp
sweepRate = 0.45;       %T/min magnet sweep rate
SD_phase = 0;           %Phase to use on LA sine output
SD_freq = 17.777;
SD_timeConstant = 0.3;  %time constant to use on LA
SD_coupling = 'AC';     %only use DC when measureing below 160mHz
tolProbe=0.5;           %temperatre tolerance for the probe

% Initialize data structure and filename
start_dir = 'C:\Crossno\data\';
start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat(datestr(StartTime, 'yyyymmdd_HHMMSS'),'_R_T__T_B_Vg_',UniqueName);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%     Initialize file structure and equipment     %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TC = deviceDrivers.Lakeshore335();
TC.connect('12');
% Connect to the DC noise multimeter
Ndc = deviceDrivers.Keithley2450();
Ndc.connect('26');
%Connect source-drain lockin amplifier
SD = deviceDrivers.SRS830();
SD.connect('8')
%connect to YOKO gate supply
VG = deviceDrivers.YokoGS200();
VG.connect('18')
%Connect to the Oxford magnet supply
MS = deviceDrivers.Oxford_IPS_120_10();
MS.connect('25');

%initialize magnet supply
MS.remoteMode();
MS.sweepRate = sweepRate;

%initialize the DC noise voltmeter
Ndc.sense_mode = 'volt';
Ndc.NPLC = 4;
Ndc.sense_range = 'auto';
Ndc.source_limit = 10;

%initialize temperature controller
TC.rampRate1 = TvaporRampRate;
TC.rampRate2 = TprobeRampRate;
TC.PID1 = PID;
TC.PID2 = PID;

%initialize the gate
if Vg_limit <= 1.2
    VG.range = 1;
elseif Vg_limit <=12
    VG.range = 10;
else
    VG.range = 30;
end

%initialize Lockin
SD.sineAmp = SD_Vex;
SD.sinePhase = SD_phase;
SD.sineFreq = SD_freq;
SD.timeConstant = SD_timeConstant;
SD.inputCoupling = SD_coupling;
SD_sens = SD.sens;

% Initialize data structure
blank = zeros(length(T_list),length(B_list),length(Vg_list));
blank_raw = zeros(length(T_list),length(B_list),length(Vg_list),Nmeasurements);

data.time = blank;
data.Tvapor = blank;
data.Tprobe = blank;
data.Vsd_X = blank;
data.Vsd_Y = blank;
data.R = blank;
data.VNdc = blank;

data.raw.time = blank_raw;
data.raw.Tvapor = blank;
data.raw.Tprobe = blank;
data.raw.Vsd_X = blank_raw;
data.raw.Vsd_Y = blank_raw;
data.raw.R = blank_raw;
data.raw.VNdc = blank_raw;

data.T = T_list;
data.B = B_list;
data.Vg = Vg_list;

data.log = struct('time',[],'Tvapor',[],'Tprobe',[],'SD_X',[],'SD_Y',[],...
    'R',[],'field',[],'persistfield',[],'T_set',[],'B_set',[]);

%record all the unsed settings
%record all the unsed settings
data.settings.SR560.gain = 100;
data.settings.SR560.LP = 100;
data.settings.SR560.gain_mode = 'High Dynamic Reserve';
data.settings.SD.sineAmp = SD_Vex;
data.settings.SD.sinePhase = SD_phase;
data.settings.SD.sineFreq = SD_freq;
data.settings.SD.timeConstant = SD_timeConstant;
data.settings.SD.inputCoupling = SD_coupling;
data.settings.SD.Rex = SD_Rex;
data.settings.MS.ramp_rate = MS.sweepRate;
data.settings.TC.rampRate1 = TvaporRampRate;
data.settings.TC.rampRate2 = TprobeRampRate;
data.settings.TC.PID1 = PID;
data.settings.TC.PID2 = PID;
data.settings.TC.tolProbe = tolProbe;

%initialize plots and GUIs
cmap = cbrewer('div','RdYlBu',64,'linear');
scrsz = get(groot,'ScreenSize');
figure(994);set(gcf,'Position',[10, scrsz(4)/2, scrsz(3)/3-10, 0.84*scrsz(4)/2]);
figure(993);set(gcf,'Position',[10+scrsz(3)/3, scrsz(4)/2, scrsz(3)/3-10, 0.84*scrsz(4)/2]);
figure(992);set(gcf,'Position',[10+2*scrsz(3)/3, scrsz(4)/2, scrsz(3)/3-10, 0.84*scrsz(4)/2]);
figure(991);set(gcf,'Position',[scrsz(3)/3, 50, 2*scrsz(3)/3, scrsz(4)/2-130]);
HeCtrl = HeFillControl();
emFill = findobj(HeCtrl,'tag','emergencyFill'); %emergencyFill handle
pauseAtZero = findobj(HeCtrl,'tag','pauseAtZero'); %fill at 0T handle
pmGUI = ProgressMonitor();
pm_handles.Tvapor = findobj(pmGUI,'tag','Tvapor');
pm_handles.Tprobe = findobj(pmGUI,'tag','Tprobe');
pm_handles.Field = findobj(pmGUI,'tag','Field');
pm_handles.Vgate = findobj(pmGUI,'tag','Vgate');
pm_handles.query = findobj(pmGUI,'tag','query');
pause(0.01);
tic
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       main loop    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for T_n=1:length(T_list)
    T_set = T_list(T_n);
    if T_set <= 2
        TC.range1 = 0; %OFF
        TC.range2 = 0;
    elseif T_set <= 4
        TC.range1 = 1; %LOW
        TC.range2 = 1;
    elseif T_set <= 20
        TC.range1 = 2; %MED
        TC.range2 = 2;
    else
        TC.range1 = 3; %HIGH
        TC.range2 = 3;
    end
    TC.setPoint1 = max(T_set-1,0);
    TC.setPoint2 = T_set;
    pm_handles.Tvapor.String = sprintf('%.1f K',T_set-1);
    pm_handles.Tprobe.String = sprintf('%.1f K',T_set);
    
    %whle waiting for temperature, initialize the field and gate
    target_field = B_list(1);
    MS.switchHeater = 1;
    MS.targetField = target_field;
    MS.goToTargetField();
    currentVg = Vg_list(1);
    VG.ramp2V(currentVg,Vg_rampRate);
    
    %only stabilize if T is above 2, otherwise dont bother.
    if T_set > 2
        stabilizeTemperature(T_set,5,tolProbe)
    end
    
    B_n = 0;
    while B_n < length(B_list)
        B_n = B_n+1;
        %set field
        MS.switchHeater = 0;
        MS.targetField = MS.persistentField;  
        target_field = B_list(B_n);
        MS.switchHeater = 1;
        MS.targetField = target_field;
        MS.goToTargetField();
        pm_handles.Field.String = sprintf('%.1f T',target_field);
        currentVg = Vg_list(1);
        VG.ramp2V(currentVg,Vg_rampRate);
        
        pause(timeLogInterval);
        timeLog();
        plotLog();
        
        %state 0 is 'HOLDING at the target field/current'
        while MS.sweepStatus() ~= 0
            pause(timeLogInterval);
            timeLog();
            plotLog();
        end
        MS.switchHeater = 0;
        
        %stop at 0 T, only works if 0T is in B_list for now
%TODO think about best way to pause if 0T is not in B_list
        if target_field == 0;
            if pauseAtZero.Value == 1;
                pauseAtZero.String = 'F5 to resume';
                eval('keyboard'); %pause command
                pauseAtZero.String = 'Pause @ 0T';
                pauseAtZero.Value = 0;
            end
        end
        
        for Vg_n=1:length(Vg_list)
            %set Vg
            currentVg = Vg_list(Vg_n);
            pm_handles.Vgate.String = sprintf('%.2f V',currentVg);
            VG.ramp2V(currentVg,Vg_rampRate);
            if Vg_n==1
                pause(VWaitTime1);
            else
                pause(VWaitTime2);
            end
            
            %try to measure, if it fails try again up to 10 times then move
            %on.
            attempts = 0;
            while true
                try
                    measure_data(T_n,B_n,Vg_n)
                    break
                catch
                    attempts = attempts+1;
                    if attempts < 10
                        warning('failed to collect data at %.1f K, %.1f T, %.3f V. retrying.',...
                            T_set, target_field, currentVg);
                    else
                        warning('failed 10 times. moving on')
                        break
                    end
                end
            end
            if pm_handles.query.Value == 1
                updateProgressMonitor();
            end
            
            plot1Dconductance(T_n,B_n);
            plot1Dnoise(T_n,B_n);
            if mod(Vg_n,25) == 1
                plot2Dresistance(T_n);
            end
            
            %check for emergency Helium fill
            if emFill.Value == 1
                emergencyFill();
                B_n = B_n-1;
                break
            end
        end
        save_data();
        toc
    end
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pause off
close(HeCtrl)
target_field = 0;
MS.switchHeater = 1;
MS.targetField = target_field;
MS.goToTargetField();
timeLog();
VG.ramp2V(0,Vg_rampRate);
while MS.sweepStatus() ~= 0
    pause(timeLogInterval);
    timeLog();
    plotLog();
end
MS.switchHeater = 0;
TC.range1 = 0;
TC.range2 = 0;
TC.setPoint1 = 0;
TC.setPoint2 = 0;

updateProgressMonitor();
TC.disconnect();
SD.disconnect();
MS.disconnect();
VG.disconnect();
end