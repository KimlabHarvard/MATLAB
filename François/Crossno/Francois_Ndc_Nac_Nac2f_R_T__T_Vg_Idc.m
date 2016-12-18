%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% designed for thermal conductance via johnson noise in Francois
% Created in Oct 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Francois_Ndc_Nac_Nac2f_R_T__T_Vg_Idc(T_list,Vg_list, Idc_list, Iac,...
        Idc_limit, Idc_rampRate, Vg_limit, Vg_rampRate, Nmeasurements, ...
        TWaitTime, VWaitTime1, VWaitTime2, measurementWaitTime, SD_Rex, UniqueName)
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%     Internal convenience functions    %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot1DR(T_n)
        change_to_figure(991); clf; hold all;
        R = mean(data.Rac,3);
        for i=1:T_n
            y = R(i,:);
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K',...
            T_list(T_n)));
        xlabel('Vg (Volts)');ylabel('Resistance (\Omega)');
        box on; grid on;
    end
    function plot1DNoise(T_n)
        change_to_figure(992); clf; hold all;
        VNdc = mean(data.VNdc,3);
        for i=1:T_n
            y = VNdc(i,:);
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        xlabel('Vg (Volts)');ylabel('DC Noise (\Omega)');
        box on; grid on;
    end
    function plot2Dnoise(T_n)
        change_to_figure(993); clf; hold all;
        VNac = 1E3*squeeze(data.VNac_X(T_n,:,:));
        surf(data.Vg,data.Idc,VNac');
        title('AC noise');
        xlabel('gate voltage (V)');ylabel('Source-Drain Current (A)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'Noise (mV)');
    end
    function plotNdcvI(T_n,Vg_n)
        change_to_figure(994); clf;
        mask = find(squeeze(data.VNdc(T_n,Vg_n,:)));
        plot(squeeze(1E3*data.Vsd(T_n,Vg_n,mask)), 1E3*squeeze(data.VNdc(T_n,Vg_n,mask)),'.-','MarkerSize',15);
        hold all;
        xlabel('Voltage (mV)');ylabel('DC Noise (mV)');
        title(sprintf('T_{bath} = %.1f K, Vg = %.3f V',...
            T_list(T_n),Vg_list(Vg_n)));
        box on; grid on;
    end
    function plotNacvI(T_n,Vg_n)
        change_to_figure(995); clf;
        mask = find(squeeze(data.VNac_X(T_n,Vg_n,:)));
        plot(squeeze(1E3*data.Vsd(T_n,Vg_n,mask)), 1E3*squeeze(data.VNac_X(T_n,Vg_n,mask)),'.-','MarkerSize',15);
        hold all;
        xlabel('Voltage (mV)');ylabel('AC Noise (mV)');
        title(sprintf('T_{bath} = %.1f K, Vg = %.3f V',...
            T_list(T_n),Vg_list(Vg_n)));
        box on; grid on;
    end
    function plotNac2fvI(T_n,Vg_n)
        change_to_figure(996); clf;
        mask = find(squeeze(data.VNac2f_X(T_n,Vg_n,:)));
        plot(squeeze(1E3*data.Vsd(T_n,Vg_n,mask)), 1E3*squeeze(data.VNac2f_X(T_n,Vg_n,mask)),'.-','MarkerSize',15);
        hold all;
        xlabel('Voltage (mV)');ylabel('AC 2f Noise (mV)');
        title(sprintf('T_{bath} = %.1f K, Vg = %.3f V',...
            T_list(T_n),Vg_list(Vg_n)));
        box on; grid on;
    end
    function plotVvI(T_n,Vg_n)
        change_to_figure(997); clf;
        mask = find(squeeze(data.Vsd(T_n,Vg_n,:)));
        plot(squeeze(1E6*data.Idc(mask)), 1E3*squeeze(data.Vsd(T_n,Vg_n,mask)),'.-','MarkerSize',15);
        hold all;
        xlabel('Current (\muA)');ylabel('Voltage (mV)');
        title(sprintf('T_{bath} = %.1f K, Vg = %.3f V',...
            T_list(T_n),Vg_list(Vg_n)));
        box on; grid on;
    end
    
    %measures the data
    function measure_data(T_n,Vg_n,Idc_n)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(T_n,Vg_n,Idc_n,n) = etime(clock, StartTime);
            data.raw.T(T_n,Vg_n,Idc_n,n) = TC.temperatureA();
            [data.raw.Vsd_X(T_n,Vg_n,Idc_n,n), data.raw.Vsd_Y(T_n,Vg_n,Idc_n,n)] = SD.snapXY();
            Vsd = sqrt(data.raw.Vsd_X(T_n,Vg_n,Idc_n,n)^2+data.raw.Vsd_Y(T_n,Vg_n,Idc_n,n)^2);
            data.raw.Rac(T_n,Vg_n,Idc_n,n) = Vsd*SD_Rex/(SD_Vex-Vsd);
            data.raw.Vsd(T_n,Vg_n,Idc_n,n) = DC.value();
            data.raw.R(T_n,Vg_n,Idc_n,n) = data.raw.Vsd(T_n,Vg_n,Idc_n,n)/currentIdc;
            data.raw.VNdc(T_n,Vg_n,Idc_n,n) = Ndc.value();
            [data.raw.VNac_X(T_n,Vg_n,Idc_n,n), data.raw.VNac_Y(T_n,Vg_n,Idc_n,n)] = Nac.snapXY();
            [data.raw.VNac2f_X(T_n,Vg_n,Idc_n,n), data.raw.VNac2f_Y(T_n,Vg_n,Idc_n,n)] = Nac2f.snapXY();
            
            
            %check if we are between 5% and 95% of the range, if not autoSens
            SD_high = max(abs(data.raw.Vsd_X(T_n,Vg_n,Idc_n,n)),abs(data.raw.Vsd_Y(T_n,Vg_n,Idc_n,n)));
            Nac_high = max(abs(data.raw.VNac_X(T_n,Vg_n,Idc_n,n)),abs(data.raw.VNac_Y(T_n,Vg_n,Idc_n,n)));
            Nac2f_high = max(abs(data.raw.VNac2f_X(T_n,Vg_n,Idc_n,n)),abs(data.raw.VNac2f_Y(T_n,Vg_n,Idc_n,n)));
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
            if Nac2f_high > Nac2f_sens*0.95 || Nac2f_high < Nac2f_sens*0.05
                Nac2f.autoSens(0.25,0.75);
                Nac2f_sens = Nac2f.sens();
                OK = 0;
            end
            if OK == 1
                %if the measurement was good, increment.
                n = n+1;
            end
        end
        data.time(T_n,Vg_n,Idc_n) = mean(data.raw.time(T_n,Vg_n,Idc_n,:));
        data.Vsd_X(T_n,Vg_n,Idc_n) = mean(data.raw.Vsd_X(T_n,Vg_n,Idc_n,:));
        data.Vsd_Y(T_n,Vg_n,Idc_n) = mean(data.raw.Vsd_Y(T_n,Vg_n,Idc_n,:));
        data.Rac(T_n,Vg_n,Idc_n) = mean(data.raw.Rac(T_n,Vg_n,Idc_n,:));
        data.Vsd(T_n,Vg_n,Idc_n) = mean(data.raw.Vsd(T_n,Vg_n,Idc_n,:));
        data.R(T_n,Vg_n,Idc_n) = mean(data.raw.R(T_n,Vg_n,Idc_n,:));
        data.T(T_n,Vg_n,Idc_n) = mean(data.raw.T(T_n,Vg_n,Idc_n,:));
        data.VNdc(T_n,Vg_n,Idc_n) = mean(data.raw.VNdc(T_n,Vg_n,Idc_n,:));
        data.VNac_X(T_n,Vg_n,Idc_n) = mean(data.raw.VNac_X(T_n,Vg_n,Idc_n,:));
        data.VNac_Y(T_n,Vg_n,Idc_n) = mean(data.raw.VNac_Y(T_n,Vg_n,Idc_n,:));
        data.VNac2f_X(T_n,Vg_n,Idc_n) = mean(data.raw.VNac2f_X(T_n,Vg_n,Idc_n,:));
        data.VNac2f_Y(T_n,Vg_n,Idc_n) = mean(data.raw.VNac2f_Y(T_n,Vg_n,Idc_n,:));
        
        data.std.Vsd_X(T_n,Vg_n,Idc_n) = std(data.raw.Vsd_X(T_n,Vg_n,Idc_n,:));
        data.std.Vsd_Y(T_n,Vg_n,Idc_n) = std(data.raw.Vsd_Y(T_n,Vg_n,Idc_n,:));
        data.std.Rac(T_n,Vg_n,Idc_n) = std(data.raw.Rac(T_n,Vg_n,Idc_n,:));
        data.std.Vsd(T_n,Vg_n,Idc_n) = std(data.raw.Vsd(T_n,Vg_n,Idc_n,:));
        data.std.R(T_n,Vg_n,Idc_n) = std(data.raw.R(T_n,Vg_n,Idc_n,:));
        data.std.T(T_n,Vg_n,Idc_n) = std(data.raw.T(T_n,Vg_n,Idc_n,:));
        data.std.VNdc(T_n,Vg_n,Idc_n) = std(data.raw.VNdc(T_n,Vg_n,Idc_n,:));
        data.std.VNac_X(T_n,Vg_n,Idc_n) = std(data.raw.VNac_X(T_n,Vg_n,Idc_n,:));
        data.std.VNac_Y(T_n,Vg_n,Idc_n) = std(data.raw.VNac_Y(T_n,Vg_n,Idc_n,:));
        data.std.VNac2f_X(T_n,Vg_n,Idc_n) = std(data.raw.VNac2f_X(T_n,Vg_n,Idc_n,:));
        data.std.VNac2f_Y(T_n,Vg_n,Idc_n) = std(data.raw.VNac2f_Y(T_n,Vg_n,Idc_n,:));
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
    assert(max(abs(Idc_list)) <= Idc_limit,sprintf('Current set above %.1f A',Idc_limit));
    pause on;
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%     Configurable parameters     %%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %set constants
    SD_phase = 0;           %Phase to use on LA sine output
    SD_freq = 17.777;
    SD_timeConstant = 1;  %time constant to use on LA
    SD_coupling = 'AC';     %only use DC when measureing below 160mHz
    tolProbe=0.1;           %temperatre tolerance for the probe
    Nac_timeConstant = 1;
    Nac_coupling = 'AC';
    Nac2f_timeConstant = 1;
    Nac2f_coupling = 'AC';
    tempRampRate=2;         % 2 K/min
    
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
    %Connect Nac lockin amplifier
    Nac = deviceDrivers.SRS830();
    Nac.connect('2')
    %Connect Nac lockin amplifier
    Nac2f = deviceDrivers.SRS830();
    Nac2f.connect('3')
    %connect to YOKO gate supply
    VG = deviceDrivers.YokoGS200();
    VG.connect('16')
    %Connect source-drain current supply
    DC = deviceDrivers.Keithley2400();
    DC.connect('24')
    
    % initialize dc current source. for safety, user must place unit in current
    % mode and turn on output.
    assert(strcmp(DC.mode, 'CURR'), 'safely place Idc in current mode and try again')
    assert(DC.output == 1, 'safely turn on Idc output and try again')
    DC.DisableAllMeasure();
    DC.EnableVoltageMeasure();
    DC.NPLC = 10;

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
    
    %initialize Nac2f Lockin
    Nac2f.timeConstant = Nac2f_timeConstant;
    Nac2f.inputCoupling = Nac2f_coupling;
    Nac2f_sens = Nac2f.sens;
    
    %initialize Temperature controler
    TC.rampRate1=tempRampRate;
    
    %initialize Lockin
    SD_Vex = Iac*SD_Rex;
    SD_Vex=min(max(0.004,round(500*SD_Vex)/500),5); %round Vex to nearest 2mV between 4mV and 5 V
    SD.sineAmp = SD_Vex;
    SD.sinePhase = SD_phase;
    SD.sineFreq = SD_freq;
    SD.timeConstant = SD_timeConstant;
    SD.inputCoupling = SD_coupling;
    SD_sens = SD.sens;
    

    % Initialize data structure
    blank = zeros(length(T_list),length(Vg_list),length(Idc_list));
    blank_raw = zeros(length(T_list),length(Vg_list),length(Idc_list),Nmeasurements);
    
    data.time = blank;
    data.T = blank;
    data.Vsd = blank;
    data.R = blank;
    data.Vsd_X = blank;
    data.Vsd_Y = blank;
    data.Rac = blank;
    data.VNdc = blank;
    data.VNac_X = blank;
    data.VNac_Y = blank;
    data.VNac2f_X = blank;
    data.VNac2f_Y = blank;
    
    data.raw.time = blank_raw;
    data.raw.T = blank_raw;
    data.raw.Vsd = blank_raw;
    data.raw.R = blank_raw;
    data.raw.Vsd_X = blank_raw;
    data.raw.Vsd_Y = blank_raw;
    data.raw.Rac = blank_raw;
    data.raw.VNdc = blank_raw;
    data.raw.VNac_X = blank_raw;
    data.raw.VNac_Y = blank_raw;
    data.raw.VNac2f_X = blank_raw;
    data.raw.VNac2f_Y = blank_raw;
    
    data.std.T = blank;
    data.std.Vsd = blank;
    data.std.R = blank;
    data.std.Vsd_X = blank;
    data.std.Vsd_Y = blank;
    data.std.Rac = blank;
    data.std.VNdc = blank;
    data.std.VNac_X = blank;
    data.std.VNac_Y = blank;
    data.std.VNac2f_X = blank;
    data.std.VNac2f_Y = blank;
    
    data.Tset = T_list;
    data.Vg = Vg_list;
    data.Idc = Idc_list;
    
    %record all the unsed settings
    data.settings.SD.sinePhase = SD_phase;
    data.settings.SD.sineFreq = SD_freq;
    data.settings.SD.timeConstant = SD_timeConstant;
    data.settings.SD.inputCoupling = SD_coupling;
    data.settings.SD.Rex = SD_Rex;
    data.settings.Nac.timeConstant = Nac_timeConstant;
    data.settings.Nac.inputCoupling = Nac_coupling;
    data.settings.Nac.sinePhase = SD_phase;
    
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
    tic; pause on;
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%       main loop    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for T_n=1:length(T_list)
        T_set = T_list(T_n);
        TC.setPoint1 = T_set;

        currentVg = Vg_list(1);
        VG.ramp2V(currentVg,Vg_rampRate);
        
        %only stabilize if T is above 3, otherwise dont bother.
        if T_set > 3
            stabilizeTemperature(T_set,5,tolProbe)
        end
        
        if T_n ~=1
            pause(TWaitTime);
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
            
            
            for Idc_n=1:length(Idc_list)
                currentIdc = Idc_list(Idc_n);
                DC.ramp2value(currentIdc,Idc_rampRate)
                pause(VWaitTime2)
                measure_data(T_n,Vg_n,Idc_n)
                
                %plotNdcvI(T_n,Vg_n);
                %plotNacvI(T_n,Vg_n);
                %plotNac2fvI(T_n,Vg_n);
                %plotVvI(T_n,Vg_n);pause(0.01);
            end
            
            if mod(Vg_n,1)==0
                plot1DR(T_n);
                plot1DNoise(T_n);
                plot2Dnoise(T_n);
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
    DC.ramp2value(0,Idc_rampRate)
    pause off
    Ndc.disconnect();
    Nac.disconnect();
    Nac2f.disconnect();
    TC.disconnect();
    SD.disconnect();
    VG.disconnect();
    DC.disconnect();
end