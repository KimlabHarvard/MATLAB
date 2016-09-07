%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Records VNA, resistance via lockin, temperature of X110375 via lockin,
% and noise power via keithley on leiden in Kimlab
% Created in Jul 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = leiden_Ndc_R_T__Vg_T_B(B_list,Ih_list, Vg_list, Nmeasurements, VWaitTime1,...
    VWaitTime2, MagWaitTime, measurementWaitTime, TwaitTime, Vg_rampRate, SD_Rex, SD_Vex,...
    EmailJess, EmailKC, UniqueName)
%%Internal convenience functions

    function plot1Dconductance(i,j)
        change_to_figure(993); hold all;
        if j == 1
            clf;
        end
        plot(data.Vg, squeeze(25813./data.R(i,j,:)),'.','MarkerSize',15);
        xlabel('Vg (Volts)');ylabel('Conductance (h/e^2)');
        box on; grid on;
    end
    function plot1Dnoise(i,j)
        change_to_figure(992); hold all;
        if j==1
            clf;
        end
        VNdc = squeeze(data.VNdc(i,j,:));
        mask = find(VNdc ~= 0);
        plot(data.Vg(mask), VNdc(mask),'.','MarkerSize',15);
        xlabel('Vg (Volts)');ylabel('V_{noise}');
        box on; grid on;
    end
    function plot2Dnoise(i)
        change_to_figure(991); clf;
        surf(data.Vg,squeeze(data.T(i,:,:)),squeeze(data.VNdc(i,:,:)));
        xlabel('gate voltage (V)');ylabel('Temperature (K)');box on;grid on;
        title('Noise voltage (V)')
        view(2);shading flat; colorbar; box on; colormap(cmap);
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
            data.raw.R(i,j,k,n) = ...
                sqrt(data.raw.Vsd_X(i,j,k,n)^2+data.raw.Vsd_Y(i,j,k,n)^2)*SD_Rex/SD_Vex;
            data.raw.VNdc(i,j,k,n) = Ndc.voltage();
            
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
        data.T(i,j,k) = mean(data.raw.T(i,j,k,:));
        data.Vsd_X(i,j,k) = mean(data.raw.Vsd_X(i,j,k,:));
        data.Vsd_Y(i,j,k) = mean(data.raw.Vsd_Y(i,j,k,:));
        data.R(i,j,k) = mean(data.raw.R(i,j,k,:));
        data.VNdc(i,j,k) = mean(data.raw.VNdc(i,j,k,:));
        data.std.T(i,j,k) = std(data.raw.T(i,j,k,:));
        data.std.Vsd_X(i,j,k) = std(data.raw.Vsd_X(i,j,k,:));
        data.std.Vsd_Y(i,j,k) = std(data.raw.Vsd_Y(i,j,k,:));
        data.std.R(i,j,k) = std(data.raw.R(i,j,k,:));
        data.std.VNdc(i,j,k) = std(data.raw.VNdc(i,j,k,:));
    end

    function save_data()
        save(fullfile(start_dir, [FileName, '.mat']),'data');
    end


%saftey checks (more checks below)
assert(max(abs(Vg_list)) <= 32,'Gate voltage set above 32 V');
assert(max(abs(Ih_list)) <= 0.03, 'heating current set above 30 mA');
pause on;

%% Initialize data structure, equipment, and filename
%set constants
SD_phase = 0; %Phase to use on LA sine output
SD_freq = 17.777;
SD_timeConstant = 0.3; %time constant to use on LA
SD_coupling = 'AC'; %only use DC when measureing below 160mHz

start_dir = 'D:\Crossno\data\';
start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat(datestr(StartTime, 'yyyymmdd_HHMMSS'),'_Ndc_R_T__Vg_T',UniqueName);

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
%connect to gate supply
VG = deviceDrivers.YokoGS200();
VG.connect('140.247.189.132')
%connect to magnet supply
MS = deviceDrivers.AMI430();
MS.connect('140.247.189.135');

%initialize magnet supply
MS.ramp_rate = 0.001;
MS.target_field = B_list(1);
MS.ramp();

%initialize the gate
VG.range = 30;
currentVg = Vg_list(1);
VG.ramp2V(currentVg,Vg_rampRate);

%initialize the DC noise voltmeter
Ndc.sense_mode = 'volt';
Ndc.NPLC = 4;
Ndc.sense_range = 'auto';
Ndc.source_limit = 10;

%initialize the heater
Heat.mode = 'current';
Heat.range = 0.1;
currentIh = Ih_list(1);
Heat.value = currentIh;
Heat.output = 1;

%initialize Lockin
SD.sineAmp = SD_Vex;
SD.sinePhase = SD_phase;
SD.sineFreq = SD_freq;
SD.timeConstant = SD_timeConstant;
SD.inputCoupling = SD_coupling;
SD_sens = SD.sens;


% Initialize data structure
blank = zeros(length(B_list),length(Ih_list),length(Vg_list));
blank_raw = zeros(length(B_list),length(Ih_list),length(Vg_list),Nmeasurements);

data.time = blank;
data.T = blank;
data.Vsd_X = blank;
data.Vsd_Y = blank;
data.R = blank;
data.VNdc = blank;

data.raw.time = blank_raw;
data.raw.T = blank_raw;
data.raw.Vsd_X = blank_raw;
data.raw.Vsd_Y = blank_raw;
data.raw.R = blank_raw;
data.raw.VNdc = blank_raw;

data.B = B_list;
data.Ih = Ih_list;
data.Vg = Vg_list;

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

%initialize plots
cmap = cbrewer('div','RdYlBu',64,'linear');
figure(993);
figure(992);
figure(991);
%% main loop
pb = createPauseButton;
pause(0.01);
while MS.state() ~= 2
    pause(5);
end
tic
for B_n=1:length(B_list)
    %set field
    target_field = B_list(B_n);
    MS.target_field = target_field;
    currentVg = Vg_list(1);
    VG.ramp2V(currentVg,Vg_rampRate);
    %state 2 is 'HOLDING at the target field/current'
    while MS.state() ~= 2
        pause(5);
    end
    if B_n >1
        pause(MagWaitTime)
    end
    for Ih_n=1:length(Ih_list)
        %set field
        currentIh = Ih_list(Ih_n);
        Heat.value = currentIh;
        currentVg = Vg_list(1);
        VG.ramp2V(currentVg,Vg_rampRate);
        %state 2 is 'HOLDING at the target field/current'
        if currentIh ~= 0
            pause(TwaitTime);
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
            
            measure_data(B_n,Ih_n,Vg_n)
            
            plot1Dconductance(B_n,Ih_n);
            plot1Dnoise(B_n,Ih_n);
            plot2Dnoise(B_n)
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
close(pb)
VG.ramp2V(0,Vg_rampRate);
Heat.value = 0;
%MS.zero();
T.disconnect();
Heat.disconnect();
SD.disconnect();
Ndc.disconnect();
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