%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% designed for thermal conductance via johnson noise in Francois
% Created in Oct 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Francois_Ndc_Nac_R_T__T_Vg(T_list,Vg_list, Tac_list, ...
        Vex_initial, Vg_limit, Vg_rampRate, gain_curve, Nmeasurements, VWaitTime1, VWaitTime2, ...
        measurementWaitTime, SD_Rex, UniqueName)
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%     Internal convenience functions    %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot1Dconductance(T_n)
        change_to_figure(991); clf; hold all;
        R = mean(data.R,3);
        for i=1:T_n
            y = squeeze(25813./R(i,:));
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K',...
            T_list(T_n)));
        xlabel('Vg (Volts)');ylabel('Conductance (h/e^2)');
        box on; grid on;
    end
    function plot1DG(T_n)
        change_to_figure(992); clf; hold all;
        G = mean(data.G,3);
        for i=1:T_n
            y = squeeze(G(i,:)*1E9);
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K',...
            T_list(T_n)));
        xlabel('Vg (Volts)');ylabel('G_{th} (nW/K)');
        box on; grid on;
    end
    function plotTvP(T_n,Vg_n)
        change_to_figure(993); clf;
        mask = find(squeeze(data.Q(T_n,Vg_n,:)));
        plot(squeeze(data.Q(T_n,Vg_n,mask))*1E9, 1E3*squeeze(data.Tac(T_n,Vg_n,mask)),'.','MarkerSize',15);
        hold all; plot(0,0,'.','MarkerSize',15);
        xlabel('Power (nW)');ylabel('\DeltaT (mK)');
        title(sprintf('T_{bath} = %.1f K and Vg = %.3f V',...
            T_list(T_n),Vg_list(Vg_n)));
        box on; grid on;
    end
    function plot1Dnoise(T_n)
        change_to_figure(994); clf; hold all;
        VNdc = mean(data.VNdc,3);
        for i=1:T_n
            y = squeeze(VNdc(i,:));
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K',...
            T_list(T_n)));
        xlabel('Vg (Volts)');ylabel('V_{noise}');
        box on; grid on;
    end
    function plotGvVgvT()
        change_to_figure(995); clf;
        G=mean(data.G,3)*1E9;
        surf(data.Vg,data.Tset,G);
        xlabel('gate voltage (V)');ylabel('T_{set} (K)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'G_{th} (nW/K)');
    end
    function plot1DL(T_n)
        change_to_figure(996); clf; hold all;
        L = mean(data.G,3).*mean(data.R,3)./(12*2.44E-8*mean(data.T,3));
        for i=1:T_n
            y = squeeze(L(i,:));
            mask = find(y ~= 0);
            plot(data.Vg(mask), y(mask),'.','MarkerSize',15);
        end
        title(sprintf('T_{bath} = %.1f K',...
            T_list(T_n)));
        xlabel('Vg (Volts)');ylabel('L (L_0)');
        box on; grid on;
    end
    
    %measures the data
    function measure_data(T_n,Vg_n,Tac_n)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(T_n,Vg_n,Tac_n,n) = etime(clock, StartTime);
            data.raw.T(T_n,Vg_n,Tac_n,n) = TC.temperatureA();
            [data.raw.Vsd_X(T_n,Vg_n,Tac_n,n), data.raw.Vsd_Y(T_n,Vg_n,Tac_n,n)] = SD.snapXY();
            Vsd = sqrt(data.raw.Vsd_X(T_n,Vg_n,Tac_n,n)^2+data.raw.Vsd_Y(T_n,Vg_n,Tac_n,n)^2);
            data.raw.R(T_n,Vg_n,Tac_n,n) = Vsd*SD_Rex/(SD_Vex-Vsd);
            data.raw.VNdc(T_n,Vg_n,Tac_n,n) = Ndc.value();
            [data.raw.VNac_X(T_n,Vg_n,Tac_n,n), data.raw.VNac_Y(T_n,Vg_n,Tac_n,n)] = Nac.snapXY();
            
            
            %check if we are between 5% and 95% of the range, if not autoSens
            SD_high = max(abs(data.raw.Vsd_X(T_n,Vg_n,Tac_n,n)),abs(data.raw.Vsd_Y(T_n,Vg_n,Tac_n,n)));
            Nac_high = max(abs(data.raw.VNac_X(T_n,Vg_n,Tac_n,n)),abs(data.raw.VNac_Y(T_n,Vg_n,Tac_n,n)));
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
        data.time(T_n,Vg_n,Tac_n) = mean(data.raw.time(T_n,Vg_n,Tac_n,:));
        data.Vsd_X(T_n,Vg_n,Tac_n) = mean(data.raw.Vsd_X(T_n,Vg_n,Tac_n,:));
        data.Vsd_Y(T_n,Vg_n,Tac_n) = mean(data.raw.Vsd_Y(T_n,Vg_n,Tac_n,:));
        data.R(T_n,Vg_n,Tac_n) = mean(data.raw.R(T_n,Vg_n,Tac_n,:));
        data.T(T_n,Vg_n,Tac_n) = mean(data.raw.T(T_n,Vg_n,Tac_n,:));
        data.VNdc(T_n,Vg_n,Tac_n) = mean(data.raw.VNdc(T_n,Vg_n,Tac_n,:));
        data.VNac_X(T_n,Vg_n,Tac_n) = mean(data.raw.VNac_X(T_n,Vg_n,Tac_n,:));
        data.VNac_Y(T_n,Vg_n,Tac_n) = mean(data.raw.VNac_Y(T_n,Vg_n,Tac_n,:));
        data.SD_Vex(T_n,Vg_n,Tac_n) = SD_Vex;
        
        data.std.Vsd_X(T_n,Vg_n,Tac_n) = std(data.raw.Vsd_X(T_n,Vg_n,Tac_n,:));
        data.std.Vsd_Y(T_n,Vg_n,Tac_n) = std(data.raw.Vsd_Y(T_n,Vg_n,Tac_n,:));
        data.std.R(T_n,Vg_n,Tac_n) = std(data.raw.R(T_n,Vg_n,Tac_n,:));
        data.T(T_n,Vg_n,Tac_n) = mean(data.raw.T(T_n,Vg_n,Tac_n,:));
        data.std.VNdc(T_n,Vg_n,Tac_n) = std(data.raw.VNdc(T_n,Vg_n,Tac_n,:));
        data.std.VNac_X(T_n,Vg_n,Tac_n) = std(data.raw.VNac_X(T_n,Vg_n,Tac_n,:));
        data.std.VNac_Y(T_n,Vg_n,Tac_n) = std(data.raw.VNac_X(T_n,Vg_n,Tac_n,:));
        
        Vsd = sqrt(data.Vsd_X(T_n,Vg_n,Tac_n)^2+data.raw.Vsd_Y(T_n,Vg_n,Tac_n)^2);
        %VNac = sqrt(data.VNac_X(T_n,Vg_n,Tac_n)^2+data.raw.VNac_Y(T_n,Vg_n,Tac_n)^2);
        VNac = data.VNac_X(T_n,Vg_n,Tac_n);
        R = Vsd*SD_Rex/(SD_Vex-Vsd);
        g = gain_curve(log10(R));
        Q = 2*R*(SD_Vex/(SD_Rex+R))^2; %factor of 2 converts between rms and p2p
        Tac = 2*sqrt(2)*VNac/g;
        data.Tac(T_n,Vg_n,Tac_n) = Tac;
        data.R(T_n,Vg_n,Tac_n) = R;
        data.Q(T_n,Vg_n,Tac_n) = Q;
        data.G(T_n,Vg_n,Tac_n) = Q/Tac;
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
    SD_phase = 0;           %Phase to use on LA sine output
    SD_freq = 17.777;
    SD_timeConstant = 0.3;  %time constant to use on LA
    SD_coupling = 'AC';     %only use DC when measureing below 160mHz
    tolProbe=0.1;           %temperatre tolerance for the probe
    Nac_timeConstant = 1;
    Nac_coupling = 'AC';
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
    %Connect Nac lockin amplifier
    Nac = deviceDrivers.SRS830();
    Nac.connect('2')
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
    
    %initialize Nac Lockin
    Nac.timeConstant = Nac_timeConstant;
    Nac.inputCoupling = Nac_coupling;
    Nac_sens = Nac.sens;
    
    %initialize Temperature controler
    TC.rampRate1=tempRampRate;
    
    %initialize Lockin
    SD_Vex = 0.004;
    SD.sineAmp = SD_Vex;
    SD.sinePhase = SD_phase;
    SD.sineFreq = SD_freq;
    SD.timeConstant = SD_timeConstant;
    SD.inputCoupling = SD_coupling;
    SD_sens = SD.sens;
    
    %initialize Vex_list
    Vex_list = zeros(1,length(Vg_list));
    Vex_list(1) = Vex_initial;
    
    % Initialize data structure
    blank = zeros(length(T_list),length(Vg_list),length(Tac_list));
    blank_raw = zeros(length(T_list),length(Vg_list),length(Tac_list),Nmeasurements);
    
    data.time = blank;
    data.T = blank;
    data.Vsd_X = blank;
    data.Vsd_Y = blank;
    data.R = blank;
    data.VNdc = blank;
    data.VNac_X = blank;
    data.VNac_Y = blank;
    data.Tac = blank;
    data.Q = blank;
    data.G = blank;
    data.SD_Vex = blank;
    
    data.raw.time = blank_raw;
    data.raw.Tvapor = blank;
    data.raw.Tprobe = blank;
    data.raw.Vsd_X = blank_raw;
    data.raw.Vsd_Y = blank_raw;
    data.raw.R = blank_raw;
    data.raw.VNdc = blank_raw;
    data.raw.VNac_X = blank_raw;
    data.raw.VNac_Y = blank_raw;
    
    data.Tset = T_list;
    data.Vg = Vg_list;
    data.Tac_set = Tac_list;
    data.gain_curve = gain_curve;
    
    %record all the unsed settings
    data.settings.SR560.gain = 100;
    data.settings.SR560.LP = 100;
    data.settings.SD.sinePhase = SD_phase;
    data.settings.SD.sineFreq = SD_freq;
    data.settings.SD.timeConstant = SD_timeConstant;
    data.settings.SD.inputCoupling = SD_coupling;
    data.settings.SD.Rex = SD_Rex;
    data.settings.Nac.timeConstant = Nac_timeConstant;
    data.settings.Nac.inputCoupling = Nac_coupling;
    data.settings.Nac.sinePhase = SD_phase;
    data.settings.TC.tolProbe = tolProbe;
    
    %initialize plots and GUIs
    cmap = cbrewer('div','RdYlBu',64,'linear');
    scrsz = get(groot,'ScreenSize');
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
        
        %Vex to 4mV
        SD.sineAmp=0.004;
        
        currentVg = Vg_list(1);
        VG.ramp2V(currentVg,Vg_rampRate);
        
        %only stabilize if T is above 2, otherwise dont bother.
        if T_set > 2
            stabilizeTemperature(T_set,5,tolProbe)
        end
        
        for Vg_n=1:length(Vg_list)
            %set Vg
            currentVg = Vg_list(Vg_n);
            VG.ramp2V(currentVg,Vg_rampRate);
            %round Vex to nearest 2mV between 4mV and 5 V
            SD_Vex=min(max(0.004,round(500*Vex_list(Vg_n))/500),5);
            SD.sineAmp=SD_Vex;
            if Vg_n==1
                pause(VWaitTime1);
            else
                pause(VWaitTime2);
            end
            
            % during first temperature, make initial Vex based on previous gate voltage
            if T_n ==1 && Vg_n ~= 1
                Vex_list(Vg_n) = Vex_list(Vg_n-1);
            end
            
            %first measurment G is unknown, so you can set a target T
            %second measurment uses G from first to estimate Q for target T
            for Tac_n=1:length(Tac_list)

                %round Vex to nearest 2mV between 4mV and 5 V
                SD_Vex=min(max(0.004,round(500*Vex_list(Vg_n))/500),5);
                SD.sineAmp=SD_Vex;
                pause(VWaitTime2)
                measure_data(T_n,Vg_n,Tac_n)
                %use the previous G to estimate what Vex is needed next
                Tnext = Tac_list(mod(Tac_n,length(Tac_list))+1);
                G = mean(data.G(T_n,Vg_n,1:Tac_n));
                R = max(50,mean(data.R(T_n,Vg_n,1:Tac_n)));
                if G > 0
                    Vex_list(Vg_n) = sqrt(G*Tnext/(2*R))*SD_Rex;
                else
                    Vex_list(Vg_n) = Vex_list(Vg_n)*sqrt(2);
                end
                
                plotTvP(T_n,Vg_n);pause(0.01);
            end
            
            if mod(Vg_n,5) == 0
                plotGvVgvT()
            end
            if mod(Vg_n,1)==0
                plot1Dconductance(T_n);
                plot1Dnoise(T_n);
                plot1DG(T_n);
                plot1DL(T_n);
            end
        end
        SD_Vex=0.004;
        SD.sineAmp=SD_Vex;
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
    Ndc.disconnect();
    Nac.disconnect();
    TC.disconnect();
    SD.disconnect();
    VG.disconnect();
end