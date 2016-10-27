%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% designed for thermal conductance via DC johnson noise in oxford
% Created in Sep 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Oxford_Ndc_T_R__T_B_Vg_Idc(T_list, B_list,Vg_list, Idc_list, ...
    Idc_rampRate, Idc_limit, Vg_limit, Vg_rampRate, Nmeasurements, VWaitTime1, VWaitTime2, ...
    measurementWaitTime, TvaporRampRate, TprobeRampRate, PID, ...
    UniqueName)
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%     Internal convenience functions    %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot2Dconductance(T_n,B_n)
        change_to_figure(992); clf; hold all;
        R = squeeze(data.R(T_n,B_n,:,:));
        surf(data.Vg,data.Idc,R');
        title('Resistance');
        xlabel('gate voltage (V)');ylabel('Source-Drain Current (A)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'R (/Omega)');
    end
    function plot2Dnoise(T_n,B_n)
        change_to_figure(993); clf; hold all;
        VNdc = 1E3*squeeze(data.VNdc(T_n,B_n,:,:));
        surf(data.Vg,data.Idc,VNdc');
        title('DC noise');
        xlabel('gate voltage (V)');ylabel('Source-Drain Current (A)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'Noise (mV)');
    end
    function plotNvI(T_n,B_n,Vg_n)
        change_to_figure(994); clf;
        mask = find(squeeze(data.VNdc(T_n,B_n,Vg_n,:)));
        plot(squeeze(1E6*data.Idc(mask)), 1E3*squeeze(data.VNdc(T_n,B_n,Vg_n,mask)),'.-','MarkerSize',15);
        hold all;
        xlabel('Current (\muA)');ylabel('Noise (mV)');
        title(sprintf('T_{bath} = %.1f K, Vg = %.3f V, and B = %.3f T',...
            T_list(T_n),Vg_list(Vg_n),B_list(B_n)));
        box on; grid on;
    end
    function plotVvI(T_n,B_n,Vg_n)
        change_to_figure(995); clf;
        mask = find(squeeze(data.Vsd(T_n,B_n,Vg_n,:)));
        plot(squeeze(1E6*data.Idc(mask)), 1E3*squeeze(data.Vsd(T_n,B_n,Vg_n,mask)),'.-','MarkerSize',15);
        hold all;
        xlabel('Current (\muA)');ylabel('Voltage (mV)');
        title(sprintf('T_{bath} = %.1f K, Vg = %.3f V, and B = %.3f T',...
            T_list(T_n),Vg_list(Vg_n),B_list(B_n)));
        box on; grid on;
    end
    function plotLog()
        change_to_figure(991); clf; grid on; hold on; xlabel('time (hr)');
        
        [ax,h1,h2] = plotyy(data.log.time/3600,data.log.field,data.log.time/3600,data.log.Tprobe);
        set(h1,'LineStyle','--','Marker','.','MarkerSize',15);
        set(h2,'LineStyle','--','Marker','.','MarkerSize',15);
        axes(ax(2));hold on;h3=plot(data.log.time/3600,data.log.Tvapor,'--or');ylim(ax(2),'auto');
        
        ylabel(ax(1),'Field (Tesla)');
        ylabel(ax(2),'Temperature (K)');
        legend([h1 h2 h3],'Field','T Probe','T Vapor','Location','NorthWest');
    end

%measures the data
    function measure_data(T_n,B_n,Vg_n,Idc_n)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(T_n,B_n,Vg_n,Idc_n,n) = etime(clock, StartTime);
            data.raw.Tvapor(T_n,B_n,Vg_n,Idc_n,n) = TC.temperatureA();
            data.raw.Tprobe(T_n,B_n,Vg_n,Idc_n,n) = TC.temperatureB();
            data.raw.Vsd(T_n,B_n,Vg_n,Idc_n,n) = DC.value();
            data.raw.R(T_n,B_n,Vg_n,Idc_n,n) = data.raw.Vsd(T_n,B_n,Vg_n,Idc_n,n)/currentIdc;
            data.raw.VNdc(T_n,B_n,Vg_n,Idc_n,n) = Ndc.senseVoltage();

            n = n+1;
            
        end
        data.time(T_n,B_n,Vg_n,Idc_n) = mean(data.raw.time(T_n,B_n,Vg_n,Idc_n,:));
        data.Vsd(T_n,B_n,Vg_n,Idc_n) = mean(data.raw.Vsd(T_n,B_n,Vg_n,Idc_n,:));
        data.R(T_n,B_n,Vg_n,Idc_n) = mean(data.raw.R(T_n,B_n,Vg_n,Idc_n,:));
        data.Tvapor(T_n,B_n,Vg_n,Idc_n) = mean(data.raw.Tvapor(T_n,B_n,Vg_n,Idc_n,:));
        data.Tprobe(T_n,B_n,Vg_n,Idc_n) = mean(data.raw.Tprobe(T_n,B_n,Vg_n,Idc_n,:));
        data.VNdc(T_n,B_n,Vg_n,Idc_n) = mean(data.raw.VNdc(T_n,B_n,Vg_n,Idc_n,:));
        
        data.std.Vsd(T_n,B_n,Vg_n,Idc_n) = std(data.raw.Vsd(T_n,B_n,Vg_n,Idc_n,:));
        data.std.R(T_n,B_n,Vg_n,Idc_n) = std(data.raw.R(T_n,B_n,Vg_n,Idc_n,:));
        data.Tvapor(T_n,B_n,Vg_n,Idc_n) = mean(data.raw.Tvapor(T_n,B_n,Vg_n,Idc_n,:));
        data.Tprobe(T_n,B_n,Vg_n,Idc_n) = mean(data.raw.Tprobe(T_n,B_n,Vg_n,Idc_n,:));
        data.std.VNdc(T_n,B_n,Vg_n,Idc_n) = std(data.raw.VNdc(T_n,B_n,Vg_n,Idc_n,:));
    end

    function save_data()
        save(fullfile(start_dir, [FileName, '.mat']),'data');
    end

%keep a running track of all parameters vs time
    function timeLog()
        data.log.time = [data.log.time etime(clock, StartTime)];
        data.log.Tvapor = [data.log.Tvapor TC.temperatureA];
        data.log.Tprobe = [data.log.Tprobe TC.temperatureB];
        data.log.T_set=[data.log.T_set T_set];
        data.log.B_set=[data.log.B_set target_field];
        data.log.field = [data.log.field MS.measuredField()];
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
assert(max(abs(Vg_list)) <= Vg_limit,sprintf('Gate voltage set above %.1f V',Vg_limit));
assert(max(abs(Idc_list)) <= Idc_limit,sprintf('Current set above %.1f A',Idc_limit));
assert(max(abs(B_list)) <= 13, 'field set above 13 T');
pause on;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%     Configurable parameters     %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%set constants
timeLogInterval = 5;    %seconds between logging field and Temp
sweepRate = 0.45;       %T/min magnet sweep rate
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
DC = deviceDrivers.Keithley2400();
DC.connect('24')
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

% initialize dc current source. for safety, user must place unit in current
% mode and turn on output.
assert(strcmp(DC.mode, 'CURR'), 'safely place Idc in current mode and try again')
assert(DC.output == 1, 'safely turn on Idc output and try again')
DC.DisableAllMeasure();
DC.EnableVoltageMeasure();

% Initialize data structure
blank = zeros(length(T_list),length(B_list),length(Vg_list),length(Idc_list));
blank_raw = zeros(length(T_list),length(B_list),length(Vg_list),length(Idc_list),Nmeasurements);

data.time = blank;
data.Tvapor = blank;
data.Tprobe = blank;
data.Vsd = blank;
data.R = blank;
data.VNdc = blank;

data.raw.time = blank_raw;
data.raw.Tvapor = blank;
data.raw.Tprobe = blank;
data.raw.Vsd = blank_raw;
data.raw.R = blank_raw;
data.raw.VNdc = blank_raw;

data.T = T_list;
data.B = B_list;
data.Vg = Vg_list;
data.Idc = Idc_list;


data.log = struct('time',[],'Tvapor',[],'Tprobe',[],'R',[],'field',[],...
    'T_set',[],'B_set',[]);

%record all the unsed settings
data.settings.SR560.gain = 100;
data.settings.SR560.LP = 100;
data.settings.MS.ramp_rate = MS.sweepRate;
data.settings.TC.rampRate1 = TvaporRampRate;
data.settings.TC.rampRate2 = TprobeRampRate;
data.settings.TC.PID1 = PID;
data.settings.TC.PID2 = PID;
data.settings.TC.tolProbe = tolProbe;

%initialize plots and GUIs
cmap = cbrewer('div','RdYlBu',64,'linear');
scrsz = get(groot,'ScreenSize');
figure(995);set(gcf,'Position',[10+2*scrsz(3)/3, 2*scrsz(4)/3, scrsz(3)/3-10, 0.84*scrsz(4)/3]);
figure(994);set(gcf,'Position',[10, scrsz(4)/3, scrsz(3)/3-10, 0.84*scrsz(4)/3]);
figure(993);set(gcf,'Position',[10+scrsz(3)/3, scrsz(4)/3, scrsz(3)/3-10, 0.84*scrsz(4)/3]);
figure(992);set(gcf,'Position',[10+2*scrsz(3)/3, scrsz(4)/3, scrsz(3)/3-10, 0.84*scrsz(4)/3]);
figure(991);set(gcf,'Position',[scrsz(3)/3, 50, 2*scrsz(3)/3, scrsz(4)/3-130]);
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
            
            %first measurment G is unknown, so you can set a target T
            %second measurment uses G from first to estimate Q for target T
            for Idc_n=1:length(Idc_list)
                currentIdc = Idc_list(Idc_n);
                DC.ramp2value(currentIdc,Idc_rampRate)
                pause(VWaitTime2)
                measure_data(T_n,B_n,Vg_n,Idc_n)
                
                plotNvI(T_n,B_n,Vg_n);
                plotVvI(T_n,B_n,Vg_n);pause(0.01);
                if pm_handles.query.Value == 1
                    updateProgressMonitor();
                end
                
                %check for emergency Helium fill
                if emFill.Value == 1
                    emergencyFill();
                    B_n = B_n-1;
                    break
                end
            end
            save_data();
            if mod(Vg_n,1)==0
                %plot2Dconductance(T_n,B_n);
                %plot2Dnoise(T_n,B_n);
            end
        end
        DC.ramp2value(0,Idc_rampRate)
        save_data();
        toc
    end
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pause off
target_field = 0;
MS.switchHeater = 1;
MS.targetField = target_field;
MS.goToTargetField();
timeLog();
VG.ramp2V(0,Vg_rampRate);
DC.ramp2value(0,Idc_rampRate);
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
close(HeCtrl)
close(pmGUI)
TC.disconnect();
DC.disconnect();
MS.disconnect();
VG.disconnect();
end