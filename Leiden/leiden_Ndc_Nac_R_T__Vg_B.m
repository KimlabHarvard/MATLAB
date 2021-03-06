%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Records VNA, resistance via lockin, and temperature of X110375 via lockin
% on leiden in Kimlab
% Created in Jun 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = leiden_Ndc_Nac_R_T__Vg_B(B_list, Vg_list, Tac_list, Vex_list,...
    gain_curve, SD_Rex, Nmeasurements, VWaitTime1, VWaitTime2, rampRate, ...
    measurementWaitTime, EmailJess, EmailKC, UniqueName)
%%Internal convenience functions

    function plot1Dcond(i)
        change_to_figure(991); clf;
        R = mean(data.R,3);
        plot(data.Vg(1:Vg_n), 25813./R(i,1:Vg_n,:),'.','MarkerSize',15);
        xlabel('Vg (Volts)');ylabel('Conductance (h/e^2)');
        title(sprintf('B = %.3f T',B_list(i)));
        box on; grid on;
    end
    function plot1DG(i)
        change_to_figure(992); clf;
        G = mean(data.G,3);
        plot(data.Vg(1:Vg_n), G(i,1:Vg_n,:)*1E9,'.','MarkerSize',15);
        xlabel('Vg (Volts)');ylabel('G_{th} (nW/K)');
        title(sprintf('B = %.3f T',B_list(i)));
        box on; grid on;
    end
    function plotTvP(i,j)
        change_to_figure(993); clf;
        mask = find(squeeze(data.Q(i,j,:)));
        plot(squeeze(data.Q(i,j,mask))*1E9, 1E3*squeeze(data.Tac(i,j,mask)),'.','MarkerSize',15);
        hold all; plot(0,0,'.','MarkerSize',15);
        xlabel('Power (nW)');ylabel('\DeltaT (mK)');
        title(sprintf('Vg = %.2f V and B = %.3f T',Vg_list(j),B_list(i)));
        box on; grid on;
    end
    function plot2DR()
        change_to_figure(994); clf;
        surf(data.Vg,data.B,mean(data.R,3));
        xlabel('gate voltage (V)');ylabel('Field (T)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'Resistance (\Omega)');
    end
    function plot2DG()
        change_to_figure(995); clf;
        G=mean(data.G,3)*1E9;
        surf(data.Vg,data.B,G);
        xlabel('gate voltage (V)');ylabel('Field (T)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'G_{th} (nW/K)');
    end
    function plot2L()
        change_to_figure(996); clf;
        L=mean(data.G,3).*mean(data.R,3)./(mean(data.T,3);
        surf(data.Vg,data.B,10*log10(L/2.44E-8));
        xlabel('gate voltage (V)');ylabel('Field (T)');box on;grid on;
        view(2);shading flat; box on; colormap(cmap);
        h = colorbar; ylabel(h, 'L/L_0 (dB)');
    end


%measures the data
    function measure_data(i,j,k)
        n = 1;
        t = clock;
        %repeat measurements n time
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(i,j,k,n) = etime(clock, StartTime);
            data.raw.T(i,j,k,n) = T.temperature();
            [data.raw.Vsd_X(i,j,k,n), data.raw.Vsd_Y(i,j,k,n)] = SD.snapXY();
            data.raw.VNdc(i,j,k,n) = Ndc.voltage();
            [data.raw.VNac_X(i,j,k,n), data.raw.VNac_Y(i,j,k,n)] = Nac.snapXY();
            
            %check if we are between 5% and 95% of the range, if not autoSens
            SD_high = max(abs(data.raw.Vsd_X(i,j,k,n)),abs(data.raw.Vsd_Y(i,j,k,n)));
            Nac_high = max(abs(data.raw.VNac_X(i,j,k,n)),abs(data.raw.VNac_Y(i,j,k,n)));
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
        
        data.time(i,j,k) = mean(data.raw.time(i,j,k,:));
        data.T(i,j,k) = mean(data.raw.T(i,j,k,:));
        data.Vsd_X(i,j,k) = mean(data.raw.Vsd_X(i,j,k,:));
        data.Vsd_Y(i,j,k) = mean(data.raw.Vsd_Y(i,j,k,:));
        data.VNdc(i,j,k) = mean(data.raw.VNdc(i,j,k,:));
        data.VNac_X(i,j,k) = mean(data.raw.VNac_X(i,j,k,:));
        data.VNac_Y(i,j,k) = mean(data.raw.VNac_Y(i,j,k,:));
        
        data.std.T(i,j,k) = std(data.raw.T(i,j,k,:));
        data.std.Vsd_X(i,j,k) = std(data.raw.Vsd_X(i,j,k,:));
        data.std.Vsd_Y(i,j,k) = std(data.raw.Vsd_Y(i,j,k,:));
        data.std.VNdc(i,j,k) = std(data.raw.VNdc(i,j,k,:));
        data.std.VNac_X(i,j,k) = std(data.raw.VNac_X(i,j,k,:));
        data.std.VNac_Y(i,j,k) = std(data.raw.VNac_X(i,j,k,:));
        
        Vsd = sqrt(data.Vsd_X(i,j,k)^2+data.raw.Vsd_Y(i,j,k)^2);
        R = Vsd*SD_Rex/(SD_Vex-Vsd);
        g = gain_curve(log10(R));
        Q = 2*R*(SD_Vex/(SD_Rex+R))^2; %factor of 2 converts between rms and p2p
        Tac = 2*sqrt(2)*data.VNac_X(i,j,k)/g;
        data.Tac(i,j,k) = Tac;
        data.R(i,j,k) = R;
        data.Q(i,j,k) = Q;
        data.G(i,j,k) = Q/Tac;
    end

    function save_data()
        save(fullfile(start_dir, [FileName, '.mat']),'data');
    end


%saftey checks (more checks below)
assert(max(abs(Vg_list)) <= 32,'Gate voltage set above 32 V');
assert(max(abs(B_list)) <= 5, 'Field set above 5 T');
pause on;

%% Initialize data structure, equipment, and filename

%set constants
SD_phase = 0; %Phase to use on LA sine output
SD_freq = 17.777;
SD_timeConstant = 0.3; %time constant to use on LA
SD_coupling = 'AC'; %only use DC when measureing below 160mHz
Nac_timeConstant = 0.3;
Nac_coupling = 'AC';

start_dir = 'D:\Crossno\data\';
start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat(datestr(StartTime, 'yyyymmdd_HHMMSS'),'_Ndc_Nac_R_T__Vg_B',UniqueName);

% Connect to the thermometer via lockin
T = deviceDrivers.X110375(101.1E6,'7');
% Connect to the DC noise multimeter
Ndc = deviceDrivers.Keithley2450();
Ndc.connect('140.247.189.130');
%connect to heater
Heat = deviceDrivers.YokoGS200();
Heat.connect('140.247.189.131')
%Connect source-drain lockin amplifier
SD = deviceDrivers.SRS830();
SD.connect('1')
%Connect Nac lockin amplifier
Nac = deviceDrivers.SRS830();
Nac.connect('2')
%connect to gate supply
VG = deviceDrivers.YokoGS200();
VG.connect('140.247.189.132')
%connect to magnet supply
MS = deviceDrivers.AMI430();
MS.connect('140.247.189.135');

%initialize magnet supply
MS.ramp_rate = 0.001;
target_field = B_list(1);
MS.target_field = target_field;
MS.ramp();

%initialize the gate
currentVg = Vg_list(1);
VG.ramp2V(currentVg,rampRate);

%initialize the DC noise voltmeter
Ndc.sense_mode = 'volt';
Ndc.NPLC = 10;
Ndc.sense_range = 'auto';
Ndc.source_limit = 10;

%initialize the heater
%Heat.mode = 'current';
%Heat.range = 0.1;
%currentIh = Ih_list(1);
%Heat.value = currentIh;
%Heat.output = 1;

%initialize SD Lockin
SD.sineAmp = 0.004;
SD.sinePhase = SD_phase;
SD.sineFreq = SD_freq;
SD.timeConstant = SD_timeConstant;
SD.inputCoupling = SD_coupling;
SD_sens = SD.sens;

%initialize Nac Lockin
Nac.timeConstant = Nac_timeConstant;
Nac.inputCoupling = Nac_coupling;
Nac_sens = Nac.sens;


% Initialize data structure
blank = zeros(length(B_list),length(Vg_list),length(Tac_list));
blank_raw = zeros(length(B_list),length(Vg_list),length(Tac_list),Nmeasurements);

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

data.raw.time = blank_raw;
data.raw.T = blank_raw;
data.raw.Vsd_X = blank_raw;
data.raw.Vsd_Y = blank_raw;
data.raw.R = blank_raw;
data.raw.VNdc = blank_raw;
data.raw.VNac_X = blank_raw;
data.raw.VNac_Y = blank_raw;

data.Tac_set = Tac_list;
data.B = B_list;
data.Vg = Vg_list;
data.gain_curve = gain_curve;

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
data.settings.Nac.phase = Nac.sinePhase;

%initialize plots
cmap = cbrewer('div','RdYlBu',246,'linear');
figure(991);clf;figure(992);clf;figure(993);clf;
figure(994);clf;figure(995);clf;figure(996);clf;
%% main loop
pb = createPauseButton;
pause(0.01);
tic
for B_n=1:length(B_list)
    SD.sineAmp = 0.004; %set Vex to a safe value
    %set field
    target_field = B_list(B_n);
    MS.target_field = target_field;
    %reset gate
    currentVg = Vg_list(1);
    VG.ramp2V(currentVg,rampRate);
    %state 2 is 'HOLDING at the target field/current'
    while MS.state() ~= 2
        pause(5);
    end
    
    for Vg_n=1:length(Vg_list)
        %set Vg
        currentVg = Vg_list(Vg_n);
        VG.ramp2V(currentVg,rampRate);
        if Vg_n==1 && B_n ~= 1
            pause(VWaitTime1);
        else
            pause(VWaitTime2);
        end
        
        %first measurment G is unknown, so you cant set a target T
        %second measurment uses G from first to estimate Q for target T
        for Tn=1:length(Tac_list) 
            %round Vex to nearest 2mV between 4mV and 5 V
            SD_Vex=min(max(0.004,round(500*Vex_list(Vg_n))/500),5);
            SD.sineAmp=SD_Vex;
            measure_data(B_n,Vg_n,Tn)
            %use the previous G to estimate what Vex is needed next
            Tnext = Tac_list(mod(Tn,length(Tac_list))+1);
            G = mean(data.G(B_n,Vg_n,1:Tn));
            R = max(50,mean(data.R(B_n,Vg_n,1:Tn)));
            if G > 0
                Vex_list(Vg_n) = sqrt(G*Tnext/R)*SD_Rex;
            else
                Vex_list(Vg_n) = Vex_list(Vg_n)*sqrt(2);
            end
            plotTvP(B_n,Vg_n);pause(0.01);
        end
        
        if mod(Vg_n,1)==0
            plot1Dcond(B_n);
            plot1DG(B_n);
            plot2DG();
            plot2DR();
            %plot2L();
            save_data();
        end
        
    end
    save_data();
    %plots
    plot1Dcond(B_n);
    plot1DG(B_n);
    plot2DG();
    plot2DR();
    %plot2L();
    toc
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pause off
close(pb)
SD.sineAmp = 0.004;
VG.ramp2V(0,rampRate);
%Heat.value = 0;
%MS.zero();
T.disconnect();
Heat.disconnect();
SD.disconnect();
Ndc.disconnect();
Nac.disconnect();
%% Email data
if EmailJess || EmailKC == 'Y'
    setpref('Internet','E_mail','Sweet.Lady.Science@gmail.com');
    setpref('Internet','SMTP_Server','smtp.gmail.com');
    setpref('Internet','SMTP_Username','Sweet.Lady.Science@gmail.com');
    setpref('Internet','SMTP_Password','graphene');
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class','javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');
    if EmailJess && EmailKC == 'Y'
        sendmail({'JDCrossno@gmail.com','fongkc@gmail.com'},strcat('Your Science is done : ',UniqueName),strcat('File :', UniqueName,' taken on :',datestr(StartTime),' at Harvard.    With Love, Sweet Lady Science'),fullfile(start_dir, [FileName, '.mat']));
    elseif EmailJess == 'Y'
        sendmail({'JDCrossno@gmail.com'},strcat('Your Science is done : ',UniqueName),strcat('File :', UniqueName,' taken on :',datestr(StartTime),' at Harvard.    With Love, Sweet Lady Science'),fullfile(start_dir, [FileName, '.mat']));
    elseif EmailKC == 'Y'
        sendmail({'fongkc@gmail.com'},strcat('Your Science is done : ',UniqueName),strcat('File :', UniqueName,' taken on :',datestr(StartTime),' at Harvard.    With Love, Sweet Lady Science'),fullfile(start_dir, [FileName, '.mat']));
    end
end
end