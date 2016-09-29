%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% designed for thermal conductance via johnson noise in oxford
% Created in Sep 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Oxford_Ndc_Nac_R_T__T_B_Vg(T_list, B_list,Vg_list, Tac_list, ...
    Vex_list, Vg_limit, Vg_rampRate, gain_curve, Nmeasurements, VWaitTime1, VWaitTime2, ...
    measurementWaitTime, SD_Rex, TvaporRampRate, TprobeRampRate, PID, ...
    UniqueName)
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%     Internal convenience functions    %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot1Dconductance(T_n,B_n)
        change_to_figure(997); clf; hold all;
        R = mean(data.R,4);
        for i=1:T_n
            y = squeeze(25813./R(i,B_n,:));
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K and B = %.3f T',...
            T_list(T_n),B_list(B_n)));
        xlabel('Vg (Volts)');ylabel('V_{noise}');
        xlabel('Vg (Volts)');ylabel('Conductance (h/e^2)');
        box on; grid on;
    end
    function plot1DG(T_n,B_n)
        change_to_figure(992); clf; hold all;
        G = mean(data.G,4);
        for i=1:T_n
            y = squeeze(G(i,B_n,:)*1E9);
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K and B = %.3f T',...
            T_list(T_n),B_list(B_n)));
        xlabel('Vg (Volts)');ylabel('G_{th} (nW/K)');
        box on; grid on;
    end
    function plotTvP(T_n,B_n,Vg_n)
        change_to_figure(993); clf;
        mask = find(squeeze(data.Q(T_n,B_n,Vg_n,:)));
        plot(squeeze(data.Q(T_n,B_n,Vg_n,mask))*1E9, 1E3*squeeze(data.Tac(T_n,B_n,Vg_n,mask)),'.','MarkerSize',15);
        hold all; plot(0,0,'.','MarkerSize',15);
        xlabel('Power (nW)');ylabel('\DeltaT (mK)');
        title(sprintf('T_{bath} = %.1f K, Vg = %.3f V, and B = %.3f T',...
            T_list(T_n),Vg_list(Vg_n),B_list(B_n)));
        box on; grid on;
    end
    function plot1Dnoise(T_n,B_n)
        change_to_figure(994); clf; hold all;
        VNdc = mean(data.VNdc,4);
        for i=1:T_n
            y = squeeze(VNdc(i,B_n,:));
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K and B = %.3f T',...
            T_list(T_n),B_list(B_n)));
        xlabel('Vg (Volts)');ylabel('V_{noise}');
        box on; grid on;
    end
    function plotGvVgvB(T_n)
        change_to_figure(995); clf;
        G=mean(data.G,4)*1E9;
        surf(data.Vg,data.B,squeeze(G(T_n,:,:)));
        xlabel('gate voltage (V)');ylabel('Field (T)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'G_{th} (nW/K)');
    end
    function plotGvVgvT(B_n)
        change_to_figure(995); clf;
        G=mean(data.G,4)*1E9;
        surf(data.Vg,data.T,squeeze(G(:,B_n,:)));
        xlabel('gate voltage (V)');ylabel('T_{set} (K)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'G_{th} (nW/K)');
    end
    function plot1DL(T_n,B_n)
        change_to_figure(996); clf; hold all;
        L = mean(data.G,4).*mean(data.R,4)./(12*2.44E-8*mean(data.Tprobe,4));
        for i=1:T_n
            y = squeeze(L(i,B_n,:));
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K and B = %.3f T',...
            T_list(T_n),B_list(B_n)));
        xlabel('Vg (Volts)');ylabel('L (L_0)');
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
    function measure_data(T_n,B_n,Vg_n,Tac_n)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(T_n,B_n,Vg_n,Tac_n,n) = etime(clock, StartTime);
            data.raw.Tvapor(T_n,B_n,Vg_n,Tac_n,n) = TC.temperatureA();
            data.raw.Tprobe(T_n,B_n,Vg_n,Tac_n,n) = TC.temperatureB();
            [data.raw.Vsd_X(T_n,B_n,Vg_n,Tac_n,n), data.raw.Vsd_Y(T_n,B_n,Vg_n,Tac_n,n)] = SD.snapXY();
            Vsd = sqrt(data.raw.Vsd_X(T_n,B_n,Vg_n,Tac_n,n)^2+data.raw.Vsd_Y(T_n,B_n,Vg_n,Tac_n,n)^2);
            data.raw.R(T_n,B_n,Vg_n,Tac_n,n) = Vsd*SD_Rex/(SD_Vex-Vsd);
            data.raw.VNdc(T_n,B_n,Vg_n,Tac_n,n) = Ndc.senseVoltage();
            [data.raw.VNac_X(T_n,B_n,Vg_n,Tac_n,n), data.raw.VNac_Y(T_n,B_n,Vg_n,Tac_n,n)] = Nac.snapXY();
            
            
            %check if we are between 5% and 95% of the range, if not autoSens
            SD_high = max(abs(data.raw.Vsd_X(T_n,B_n,Vg_n,Tac_n,n)),abs(data.raw.Vsd_Y(T_n,B_n,Vg_n,Tac_n,n)));
            Nac_high = max(abs(data.raw.VNac_X(T_n,B_n,Vg_n,Tac_n,n)),abs(data.raw.VNac_Y(T_n,B_n,Vg_n,Tac_n,n)));
            OK = 1;
            if SD_high > SD_sens*0.95 || SD_high < SD_sens*0.05
                SD.autoSens(0.25,0.75);
                SD_sens = SD.sens();
                OK = 0;
            end
            if Nac_high > Nac_sens*0.95 || Nac_high < Nac_sens*0.05
                Nac.autoSens(0.25,0.75);
                Nac_sens = Nac.sens();
                OK = 0;
            end
            if OK == 1
                %if the measurement was good, increment.
                n = n+1;
            end
        end
        data.time(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.time(T_n,B_n,Vg_n,Tac_n,:));
        data.Vsd_X(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.Vsd_X(T_n,B_n,Vg_n,Tac_n,:));
        data.Vsd_Y(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.Vsd_Y(T_n,B_n,Vg_n,Tac_n,:));
        data.R(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.R(T_n,B_n,Vg_n,Tac_n,:));
        data.Tvapor(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.Tvapor(T_n,B_n,Vg_n,Tac_n,:));
        data.Tprobe(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.Tprobe(T_n,B_n,Vg_n,Tac_n,:));
        data.VNdc(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.VNdc(T_n,B_n,Vg_n,Tac_n,:));
        data.VNac_X(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.VNac_X(T_n,B_n,Vg_n,Tac_n,:));
        data.VNac_Y(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.VNac_Y(T_n,B_n,Vg_n,Tac_n,:));
        
        data.std.Vsd_X(T_n,B_n,Vg_n,Tac_n) = std(data.raw.Vsd_X(T_n,B_n,Vg_n,Tac_n,:));
        data.std.Vsd_Y(T_n,B_n,Vg_n,Tac_n) = std(data.raw.Vsd_Y(T_n,B_n,Vg_n,Tac_n,:));
        data.std.R(T_n,B_n,Vg_n,Tac_n) = std(data.raw.R(T_n,B_n,Vg_n,Tac_n,:));
        data.Tvapor(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.Tvapor(T_n,B_n,Vg_n,Tac_n,:));
        data.Tprobe(T_n,B_n,Vg_n,Tac_n) = mean(data.raw.Tprobe(T_n,B_n,Vg_n,Tac_n,:));
        data.std.VNdc(T_n,B_n,Vg_n,Tac_n) = std(data.raw.VNdc(T_n,B_n,Vg_n,Tac_n,:));
        data.std.VNac_X(T_n,B_n,Vg_n,Tac_n) = std(data.raw.VNac_X(T_n,B_n,Vg_n,Tac_n,:));
        data.std.VNac_Y(T_n,B_n,Vg_n,Tac_n) = std(data.raw.VNac_X(T_n,B_n,Vg_n,Tac_n,:));
        
        Vsd = sqrt(data.Vsd_X(T_n,B_n,Vg_n,Tac_n)^2+data.raw.Vsd_Y(T_n,B_n,Vg_n,Tac_n)^2);
        %VNac = sqrt(data.VNac_X(T_n,B_n,Vg_n,Tac_n)^2+data.raw.VNac_Y(T_n,B_n,Vg_n,Tac_n)^2);
        VNac = data.VNac_X(T_n,B_n,Vg_n,Tac_n);
        R = Vsd*SD_Rex/(SD_Vex-Vsd);
        g = gain_curve(log10(R));
        Q = 2*R*(SD_Vex/(SD_Rex+R))^2; %factor of 2 converts between rms and p2p
        Tac = 2*sqrt(2)*VNac/g;
        data.Tac(T_n,B_n,Vg_n,Tac_n) = Tac;
        data.R(T_n,B_n,Vg_n,Tac_n) = R;
        data.Q(T_n,B_n,Vg_n,Tac_n) = Q;
        data.G(T_n,B_n,Vg_n,Tac_n) = Q/Tac;
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
Nac_timeConstant = 1;
Nac_coupling = 'AC';

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
%Connect Nac lockin amplifier
Nac = deviceDrivers.SRS830();
Nac.connect('9')
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

%initialize Nac Lockin
Nac.timeConstant = Nac_timeConstant;
Nac.inputCoupling = Nac_coupling;
Nac_sens = Nac.sens;


%initialize Lockin
SD_Vex = 0.004;
SD.sineAmp = SD_Vex;
SD.sinePhase = SD_phase;
SD.sineFreq = SD_freq;
SD.timeConstant = SD_timeConstant;
SD.inputCoupling = SD_coupling;
SD_sens = SD.sens;

% Initialize data structure
blank = zeros(length(T_list),length(B_list),length(Vg_list),length(Tac_list));
blank_raw = zeros(length(T_list),length(B_list),length(Vg_list),length(Tac_list),Nmeasurements);

data.time = blank;
data.Tvapor = blank;
data.Tprobe = blank;
data.Vsd_X = blank;
data.Vsd_Y = blank;
data.R = blank;
data.VNdc = blank;
data.VNac_X = blank;
data.VNac_Y = blank;
data.Tac = blank;
data.Q = blank;
data.G = blank;

data.raw.time = blank_raw;
data.raw.Tvapor = blank;
data.raw.Tprobe = blank;
data.raw.Vsd_X = blank_raw;
data.raw.Vsd_Y = blank_raw;
data.raw.R = blank_raw;
data.raw.VNdc = blank_raw;
data.raw.VNac_X = blank_raw;
data.raw.VNac_Y = blank_raw;

data.T = T_list;
data.B = B_list;
data.Vg = Vg_list;
data.Tac_set = Tac_list;
data.gain_curve = gain_curve;


data.log = struct('time',[],'Tvapor',[],'Tprobe',[],'SD_X',[],'SD_Y',[],...
    'R',[],'field',[],'persistfield',[],'T_set',[],'B_set',[]);

%record all the unsed settings
data.settings.SR560.gain = 100;
data.settings.SR560.LP = 100;
data.settings.SR560.gain_mode = 'High Dynamic Reserve';
data.settings.SD.sinePhase = SD_phase;
data.settings.SD.sineFreq = SD_freq;
data.settings.SD.timeConstant = SD_timeConstant;
data.settings.SD.inputCoupling = SD_coupling;
data.settings.SD.Rex = SD_Rex;
data.settings.Nac.timeConstant = Nac_timeConstant;
data.settings.Nac.inputCoupling = Nac_coupling;
data.settings.Nac.sinePhase = SD_phase;
data.settings.MS.ramp_rate = MS.sweepRate;
data.settings.TC.rampRate1 = TvaporRampRate;
data.settings.TC.rampRate2 = TprobeRampRate;
data.settings.TC.PID1 = PID;
data.settings.TC.PID2 = PID;
data.settings.TC.tolProbe = tolProbe;

%initialize plots and GUIs
cmap = cbrewer('div','RdYlBu',64,'linear');
scrsz = get(groot,'ScreenSize');
figure(997);set(gcf,'Position',[10, 2*scrsz(4)/3, scrsz(3)/3-10, 0.84*scrsz(4)/3]);
figure(996);set(gcf,'Position',[10+scrsz(3)/3, 2*scrsz(4)/3, scrsz(3)/3-10, 0.84*scrsz(4)/3]);
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
        SD.sineAmp = 0.004; %set Vex to a safe value
        
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
            %round Vex to nearest 2mV between 4mV and 5 V
            SD_Vex=min(max(0.004,round(500*Vex_list(Vg_n))/500),5);
            SD.sineAmp=SD_Vex;
            if Vg_n==1
                pause(VWaitTime1);
            else
                pause(VWaitTime2);
            end
            
            %first measurment G is unknown, so you can set a target T
            %second measurment uses G from first to estimate Q for target T
            for Tac_n=1:length(Tac_list)
                %round Vex to nearest 2mV between 4mV and 5 V
                SD_Vex=min(max(0.004,round(500*Vex_list(Vg_n))/500),5);
                SD.sineAmp=SD_Vex;
                pause(VWaitTime2)
                measure_data(T_n,B_n,Vg_n,Tac_n)
                %use the previous G to estimate what Vex is needed next
                Tnext = Tac_list(mod(Tac_n,length(Tac_list))+1);
                G = mean(data.G(T_n,B_n,Vg_n,1:Tac_n));
                R = max(50,mean(data.R(T_n,B_n,Vg_n,1:Tac_n)));
                if G > 0
                    Vex_list(Vg_n) = sqrt(G*Tnext/(2*R))*SD_Rex;
                else
                    Vex_list(Vg_n) = Vex_list(Vg_n)*sqrt(2);
                end
                plotTvP(T_n,B_n,Vg_n);pause(0.01);
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
            if mod(Vg_n,1) == 0
                plotGvVgvB(T_n)
            end
            if mod(Vg_n,1)==0
                plot1Dconductance(T_n,B_n);
                plot1Dnoise(T_n,B_n);
                plot1DG(T_n,B_n);
                plot1DL(T_n,B_n);
            end
        end
        SD_Vex=0.004;
        SD.sineAmp=SD_Vex;
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
SD.disconnect();
MS.disconnect();
VG.disconnect();
end