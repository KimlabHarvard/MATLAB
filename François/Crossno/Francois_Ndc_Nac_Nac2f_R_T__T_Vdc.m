%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% designed for thermal conductance via johnson noise in Francois
% Created in Oct 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Francois_Ndc_Nac_Nac2f_R_T__T_Vdc(T_list, Vdc_list, Iac,...
        Vdc_limit, Vdc_rampRate, Nmeasurements, TWaitTime, WaitTime1, ...
        WaitTime2, measurementWaitTime, Rex_ac, Rex_dc, UniqueName)
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%     Internal convenience functions    %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plotRvT()
        change_to_figure(991); clf; hold all;
        [V0,i] = min(abs(Vdc_list));
        x = squeeze(data.T(:,i));
        y = squeeze(data.R(:,i));
        mask = find(y ~= 0);
        plot(x(mask), y(mask),'.','MarkerSize',15);
        
        title(sprintf('Vdc = %.2f V',V0));
        xlabel('T_{Bath} (K)');ylabel('Resistance (\Omega)');
        box on; grid on;
    end
    function plotNdcvI()
        change_to_figure(992); clf; hold all;
        x = Vdc_list/Rex_dc;
        y = data.VNdc;
        for i=1:T_n
            if any(y(i,:) ~= 0)
                mask = find(y(i,:) ~= 0);
                plot(x(mask), y(i,mask),'.', ...
                    'MarkerSize',15, ...
                    'DisplayName',sprintf('%.1f K',data.Tset(T_n)));
            end
        end
        legend('show','location','best');
        xlabel('Idc (A)');ylabel('DC Noise (V)');
        box on; grid on;
    end

    function plotNacvI()
        change_to_figure(993); clf; hold all;
        x = Vdc_list/Rex_dc;
        y = data.VNac_X;
        for i=1:T_n
            if any(y(i,:) ~= 0)
                mask = find(y(i,:) ~= 0);
                plot(x(mask), y(i,mask),'.', ...
                    'MarkerSize',15, ...
                    'DisplayName',sprintf('%.1f K',data.Tset(T_n)));
            end
        end
        legend('show','location','best');
        xlabel('Idc (A)');ylabel('AC Noise (V)');
        box on; grid on;
    end
    function plotNac2fvI()
        change_to_figure(994); clf; hold all;
        x = Vdc_list/Rex_dc;
        y = data.VNac2f_X;
        for i=1:T_n
            if any(y(i,:) ~= 0)
                mask = find(y(i,:) ~= 0);
                plot(x(mask), y(i,mask),'.', ...
                    'MarkerSize',15, ...
                    'DisplayName',sprintf('%.1f K',data.Tset(T_n)));
            end
        end
        legend('show','location','best');
        xlabel('Idc (A)');ylabel('2f AC Noise (V)');
        box on; grid on;
    end
    function plotRvI()
        change_to_figure(995); clf; hold all;
        x = Vdc_list/Rex_dc;
        y = data.R;
        for i=1:T_n
            if any(y(i,:) ~= 0)
                mask = find(y(i,:) ~= 0);
                plot(x(mask), y(i,mask),'.', ...
                    'MarkerSize',15, ...
                    'DisplayName',sprintf('%.1f K',data.Tset(T_n)));
            end
        end
        legend('show','location','best');
        xlabel('Idc (A)');ylabel('Resistance (\Omega)');
        box on; grid on;
    end
    
    
    %measures the data
    function measure_data(T_n,Vdc_n)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(T_n,Vdc_n,n) = etime(clock, StartTime);
            data.raw.T(T_n,Vdc_n,n) = TC.temperatureA();
            [data.raw.Vsd_X(T_n,Vdc_n,n), data.raw.Vsd_Y(T_n,Vdc_n,n)] = SDac.snapXY();
            Vsd = data.raw.Vsd_X(T_n,Vdc_n,n);
            data.raw.R(T_n,Vdc_n,n) = Vsd*Rex_ac/(SD_Vex_ac-Vsd);
            data.raw.VNdc(T_n,Vdc_n,n) = Ndc.value();
            [data.raw.VNac_X(T_n,Vdc_n,n), data.raw.VNac_Y(T_n,Vdc_n,n)] = Nac.snapXY();
            [data.raw.VNac2f_X(T_n,Vdc_n,n), data.raw.VNac2f_Y(T_n,Vdc_n,n)] = Nac2f.snapXY();
            
            
            %check if we are between 5% and 95% of the range, if not autoSens
            SD_high = max(abs(data.raw.Vsd_X(T_n,Vdc_n,n)),abs(data.raw.Vsd_Y(T_n,Vdc_n,n)));
            Nac_high = max(abs(data.raw.VNac_X(T_n,Vdc_n,n)),abs(data.raw.VNac_Y(T_n,Vdc_n,n)));
            Nac2f_high = max(abs(data.raw.VNac2f_X(T_n,Vdc_n,n)),abs(data.raw.VNac2f_Y(T_n,Vdc_n,n)));
            OK = 1;
            if SD_high > SD_sens*0.95 || SD_high < SD_sens*0.05
                SDac.autoSens(0.25,0.75);
                SD_sens = SDac.sens();
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
        data.time(T_n,Vdc_n) = mean(data.raw.time(T_n,Vdc_n,:));
        data.Vsd_X(T_n,Vdc_n) = mean(data.raw.Vsd_X(T_n,Vdc_n,:));
        data.Vsd_Y(T_n,Vdc_n) = mean(data.raw.Vsd_Y(T_n,Vdc_n,:));
        data.R(T_n,Vdc_n) = mean(data.raw.R(T_n,Vdc_n,:));
        data.T(T_n,Vdc_n) = mean(data.raw.T(T_n,Vdc_n,:));
        data.VNdc(T_n,Vdc_n) = mean(data.raw.VNdc(T_n,Vdc_n,:));
        data.VNac_X(T_n,Vdc_n) = mean(data.raw.VNac_X(T_n,Vdc_n,:));
        data.VNac_Y(T_n,Vdc_n) = mean(data.raw.VNac_Y(T_n,Vdc_n,:));
        data.VNac2f_X(T_n,Vdc_n) = mean(data.raw.VNac2f_X(T_n,Vdc_n,:));
        data.VNac2f_Y(T_n,Vdc_n) = mean(data.raw.VNac2f_Y(T_n,Vdc_n,:));
        
        data.std.Vsd_X(T_n,Vdc_n) = std(data.raw.Vsd_X(T_n,Vdc_n,:));
        data.std.Vsd_Y(T_n,Vdc_n) = std(data.raw.Vsd_Y(T_n,Vdc_n,:));
        data.std.R(T_n,Vdc_n) = std(data.raw.R(T_n,Vdc_n,:));
        data.std.T(T_n,Vdc_n) = std(data.raw.T(T_n,Vdc_n,:));
        data.std.VNdc(T_n,Vdc_n) = std(data.raw.VNdc(T_n,Vdc_n,:));
        data.std.VNac_X(T_n,Vdc_n) = std(data.raw.VNac_X(T_n,Vdc_n,:));
        data.std.VNac_Y(T_n,Vdc_n) = std(data.raw.VNac_Y(T_n,Vdc_n,:));
        data.std.VNac2f_X(T_n,Vdc_n) = std(data.raw.VNac2f_X(T_n,Vdc_n,:));
        data.std.VNac2f_Y(T_n,Vdc_n) = std(data.raw.VNac2f_Y(T_n,Vdc_n,:));
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
    assert(max(abs(Vdc_list)) <= Vdc_limit,sprintf('voltage set above %.1f V',Vdc_limit));
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
    SDac = deviceDrivers.SRS830();
    SDac.connect('1');
    %Connect Nac lockin amplifier
    Nac = deviceDrivers.SRS830();
    Nac.connect('2');
    %Connect Nac lockin amplifier
    Nac2f = deviceDrivers.SRS830();
    Nac2f.connect('3');
    %connect to YOKO gate supply
    Vdc = deviceDrivers.YokoGS200();
    Vdc.connect('18');
    
    

    %initialize the DC source
    if Vdc_limit <= 1.2
        Vdc.range = 1;
    elseif Vdc_limit <=12
        Vdc.range = 10;
    else
        Vdc.range = 30;
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
    SD_Vex_ac = Iac*Rex_ac;
    SD_Vex_ac=min(max(0.004,round(500*SD_Vex_ac)/500),5); %round Vex to nearest 2mV between 4mV and 5 V
    SDac.sineAmp = SD_Vex_ac;
    SDac.sinePhase = SD_phase;
    SDac.sineFreq = SD_freq;
    SDac.timeConstant = SD_timeConstant;
    SDac.inputCoupling = SD_coupling;
    SD_sens = SDac.sens;
    

    % Initialize data structure
    blank = zeros(length(T_list),length(Vdc_list));
    blank_raw = zeros(length(T_list),length(Vdc_list),Nmeasurements);
    
    data.time = blank;
    data.T = blank;
    data.Vsd = blank;
    data.Vsd_X = blank;
    data.Vsd_Y = blank;
    data.R = blank;
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
    data.std.VNdc = blank;
    data.std.VNac_X = blank;
    data.std.VNac_Y = blank;
    data.std.VNac2f_X = blank;
    data.std.VNac2f_Y = blank;
    
    data.Tset = T_list;
    data.Vdc = Vdc_list;
    data.Rex_dc = Rex_dc;
    data.Idc = data.Vdc/Rex_dc;
    data.Iac = SD_Vex_ac/Rex_ac;
    
    %record all the unsed settings
    data.settings.SD.sinePhase = SD_phase;
    data.settings.SD.sineFreq = SD_freq;
    data.settings.SD.timeConstant = SD_timeConstant;
    data.settings.SD.inputCoupling = SD_coupling;
    data.settings.SD.Rex = Rex_ac;
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

        currentVdc = Vdc_list(1);
        Vdc.ramp2V(currentVdc,Vdc_rampRate);
        
        %only stabilize if T is above 3, otherwise dont bother.
        if T_set > 3
            stabilizeTemperature(T_set,5,tolProbe)
        end
        
        if T_n ~=1
            pause(TWaitTime);
        end
        
        for Vdc_n=1:length(Vdc_list)
            %set Vdc
            currentVdc = Vdc_list(Vdc_n);
            Vdc.ramp2V(currentVdc,Vdc_rampRate);

            if Vdc_n==1 && T_n ~= 1
                pause(WaitTime1);
            else
                pause(WaitTime2);
            end
            
            measure_data(T_n,Vdc_n)

            plotNdcvI();
            plotNacvI();
            plotNac2fvI();
            plotRvI();pause(0.01);
            
            if mod(Vdc_n,25) == 0
                save_data()
            end
        end
        save_data();
        toc
        plotRvT();
    end
    
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    TC.setPoint1 = 0;
    Vdc.ramp2V(0,Vdc_rampRate);
    pause off
    Ndc.disconnect();
    Nac.disconnect();
    Nac2f.disconnect();
    TC.disconnect();
    SDac.disconnect();
    Vdc.disconnect();
end