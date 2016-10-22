%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% designed for calibration of johnson noise in Francois
% Created in Sep 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Francois_Ndc_R_T__T_Vg(T_list, Vg_list, Vg_limit, Vg_rampRate,...
        Nmeasurements, VWaitTime1, VWaitTime2, measurementWaitTime, SD_Rex, ...
        SD_Vex, UniqueName)
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%     Internal convenience functions    %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot1Dconductance(T_n)
        change_to_figure(991); clf;
        for i=1:T_n
            R = squeeze(data.R(i,:));
            mask = find(R ~= 0);
            plot(data.Vg(mask), 25813./R(mask),'.','MarkerSize',15);
        end
        xlabel('Vg (Volts)');ylabel('Conductance (h/e^2)');
        box on; grid on;
    end
    function plot1Dnoise(T_n)
        change_to_figure(992); clf; hold all;
        for i=1:T_n
            VNdc = squeeze(data.VNdc(i,:));
            mask = find(VNdc ~= 0);
            plot(data.Vg(mask), VNdc(mask),'.','MarkerSize',15);
        end
        xlabel('Vg (Volts)');ylabel('V_{noise}');
        box on; grid on;
    end
    function plot2Dresistance()
        change_to_figure(993); clf;
        surf(data.Vg,data.T,data.R');
        xlabel('Vg (Volts)'); ylabel('Temperature (K)');
        view(2);shading flat; colorbar; box on; colormap(flipud(cmap));
    end
    function plot2Dnoise()
        change_to_figure(994); clf;
        surf(data.Vg,data.T,data.VNdc');
        xlabel('Vg (Volts)'); ylabel('Temperature (K)');
        view(2);shading flat; colorbar; box on; colormap(flipud(cmap));
    end
    %measures the data
    function measure_data(T_n,Vg_n)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(T_n,Vg_n,n) = etime(clock, StartTime);
            data.raw.T(T_n,Vg_n,n) = TC.temperatureA();
            [data.raw.Vsd_X(T_n,Vg_n,n), data.raw.Vsd_Y(T_n,Vg_n,n)] = SD.snapXY();
            Vsd = sqrt(data.raw.Vsd_X(T_n,Vg_n,n)^2+data.raw.Vsd_Y(T_n,Vg_n,n)^2);
            data.raw.R(T_n,Vg_n,n) = Vsd*SD_Rex/(SD_Vex-Vsd);
            data.raw.VNdc(T_n,Vg_n,n) = Ndc.value();
            
            
            %check if we are between 5% and 95% of the range, if not autoSens
            high = max(data.raw.Vsd_X(T_n,Vg_n,n),data.raw.Vsd_Y(T_n,Vg_n,n));
            if high > SD_sens*0.95 || high < SD_sens*0.05
                SD.autoSens(0.25,0.75);
                SD_sens = SD.sens();
            else
                %if the measurement was good, increment.
                n = n+1;
            end
        end
        data.time(T_n,Vg_n) = mean(data.raw.time(T_n,Vg_n,:));
        data.Vsd_X(T_n,Vg_n) = mean(data.raw.Vsd_X(T_n,Vg_n,:));
        data.Vsd_Y(T_n,Vg_n) = mean(data.raw.Vsd_Y(T_n,Vg_n,:));
        data.R(T_n,Vg_n) = mean(data.raw.R(T_n,Vg_n,:));
        data.T(T_n,Vg_n) = mean(data.raw.T(T_n,Vg_n,:));
        data.VNdc(T_n,Vg_n) = mean(data.raw.VNdc(T_n,Vg_n,:));
        
        data.std.Vsd_X(T_n,Vg_n) = std(data.raw.Vsd_X(T_n,Vg_n,:));
        data.std.Vsd_Y(T_n,Vg_n) = std(data.raw.Vsd_Y(T_n,Vg_n,:));
        data.std.R(T_n,Vg_n) = std(data.raw.R(T_n,Vg_n,:));
        data.T(T_n,Vg_n) = mean(data.raw.T(T_n,Vg_n,:));
        data.std.VNdc(T_n,Vg_n) = std(data.raw.VNdc(T_n,Vg_n,:));
    end
    
    function save_data()
        save(fullfile(start_dir, [FileName, '.mat']),'data');
    end
    
    %run until temperature is stable around setpoint
    function stabilizeTemperature(setPoint,time,tolerance)
        %temperature should be with +- tolerance in K for time seconds
        Tmonitor = 999*ones(1,time*10);
        n_mon = 0;
        t1 = clock;
        while max(Tmonitor)>tolerance
            Tmonitor(1,mod(n_mon,time*10)+1)=abs(TC.temperatureA()-setPoint);
            n_mon=n_mon+1;
            while etime(clock,t1) < 0.1
            end
            t1 = clock; %pause which accounts for measurement/plotting time
        end
    end
    
    %saftey checks (more checks below)
    assert(max(abs(Vg_list)) <= Vg_limit,sprintf('Gate voltage set above %.1f V',Vg_limit));
    pause on;
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%     Configurable parameters     %%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %set constants
    SD_phase = 0;           % Phase to use on LA sine output
    SD_freq = 17.777;
    SD_timeConstant = 0.3;  % time constant to use on LA
    SD_coupling = 'AC';     % only use DC when measureing below 160mHz
    tolProbe=0.1;           % temperatre tolerance for the probe
    tempRampRate=2;         % 5 K/min
    
    % Initialize data structure and filename
    start_dir = 'C:\Crossno\data\';
    start_dir = uigetdir(start_dir);
    StartTime = clock;
    FileName = strcat(datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',mfilename(),'_',UniqueName);
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%     Initialize file structure and equipment     %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    TC = FrancoisLakeShore335();
    TC.connect('12');
    % Connect to the DC noise multimeter
    Ndc = deviceDrivers.Keysight34401A();
    Ndc.connect('6');
    %Connect source-drain lockin amplifier
    SD = deviceDrivers.SRS830();
    SD.connect('1')
    %connect to YOKO gate supply
    VG = deviceDrivers.YokoGS200();
    VG.connect('16')
    
    %initialize the gate
    if Vg_limit <= 1.2
        VG.range = 1;
    elseif Vg_limit <=12
        VG.range = 10;
    else
        VG.range = 30;
    end
    
    %initialize Temperature controler
    TC.rampRate1=tempRampRate;
    
    %initialize Lockin
    SD.sineAmp = SD_Vex;
    SD.sinePhase = SD_phase;
    SD.sineFreq = SD_freq;
    SD.timeConstant = SD_timeConstant;
    SD.inputCoupling = SD_coupling;
    SD_sens = SD.sens;
    
    % Initialize data structure
    blank = zeros(length(T_list),length(Vg_list));
    blank_raw = zeros(length(T_list),length(Vg_list),Nmeasurements);
    
    data.time = blank;
    data.T = blank;
    data.Vsd_X = blank;
    data.Vsd_Y = blank;
    data.R = blank;
    data.VNdc = blank;
    
    data.raw.time = blank_raw;
    data.raw.T = blank;
    data.raw.Vsd_X = blank_raw;
    data.raw.Vsd_Y = blank_raw;
    data.raw.R = blank_raw;
    data.raw.VNdc = blank_raw;
    
    data.T = T_list;
    data.Vg = Vg_list;
    
    %record all the unsed settings
    %record all the unsed settings
    data.settings.SR560.gain = 100;
    data.settings.SR560.LP = 100;
    data.settings.SD.sineAmp = SD_Vex;
    data.settings.SD.sinePhase = SD_phase;
    data.settings.SD.sineFreq = SD_freq;
    data.settings.SD.timeConstant = SD_timeConstant;
    data.settings.SD.inputCoupling = SD_coupling;
    data.settings.SD.Rex = SD_Rex;
    data.settings.TC.tolProbe = tolProbe;
    
    %initialize plots and GUIs
    cmap = cbrewer('div','RdYlBu',64,'linear');
    scrsz = get(groot,'ScreenSize');
    figure(994);set(gcf,'Position',[10, scrsz(4)/2, scrsz(3)/3-10, 0.84*scrsz(4)/2]);
    figure(993);set(gcf,'Position',[10+scrsz(3)/3, scrsz(4)/2, scrsz(3)/3-10, 0.84*scrsz(4)/2]);
    figure(992);set(gcf,'Position',[10+2*scrsz(3)/3, scrsz(4)/2, scrsz(3)/3-10, 0.84*scrsz(4)/2]);
    figure(991);set(gcf,'Position',[scrsz(3)/3, 50, 2*scrsz(3)/3, scrsz(4)/2-130]);
    tic
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%       main loop    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for T_n=1:length(T_list)
        T_set = T_list(T_n);
        TC.setPoint1 = T_set;
        
        currentVg = Vg_list(1);
        VG.ramp2V(currentVg,Vg_rampRate);
        
        %only stabilize if T is above 2, otherwise dont bother.
        if T_set > 3
            stabilizeTemperature(T_set,60,tolProbe)
        end
        
        for Vg_n=1:length(Vg_list)
            %set Vg
            currentVg = Vg_list(Vg_n);
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
                    measure_data(T_n,Vg_n)
                    break
                catch
                    attempts = attempts+1;
                    if attempts < 10
                        warning('failed to collect data at %.1f K, %.3f V. retrying.',...
                            T_set, currentVg);
                    else
                        warning('failed 10 times. moving on')
                        break
                    end
                end
            end
            
            plot1Dconductance(T_n);
            plot1Dnoise(T_n);
            if mod(Vg_n,10) == 1
                %plot2Dresistance();
                %plot2Dnoise();
            end
        end
        save_data();
        toc
    end
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    TC.setPoint1 = 0;
    VG.ramp2V(0,Vg_rampRate);
    pause off
    TC.disconnect();
    SD.disconnect();
    VG.disconnect();
end