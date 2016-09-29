%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created in Sep 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Oxford_R_T__Vg(Vg_list, SD_Vex, Nmeasurements, VWaitTime1, VWaitTime2,...
    measurementWaitTime, Vg_rampRate, Vg_limit, SD_Rex, EmailJess, EmailKC, UniqueName)
%%Internal convenience functions

    function plotResistance()
        change_to_figure(993); clf; 
        mask = find(data.R);
        plot(data.Vg(mask),data.R(mask),'.','MarkerSize',15);
        xlabel('Vg (Volts)');ylabel('Resistance (\Omega)');
        grid on; box on;
    end

%measures the data
    function measure_data(i)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(i,n) = etime(clock, StartTime);
            [data.raw.Vsd_X(i,n), data.raw.Vsd_Y(i,n)] = SD.snapXY();
            data.raw.R(i,n) = ...
                sqrt(data.raw.Vsd_X(i,n)^2+data.raw.Vsd_Y(i,n)^2)*SD_Rex/SD_Vex;
            data.raw.Tvapor(i,n) = TC.temperatureA;
            data.raw.Tprobe(i,n) = TC.temperatureB;
            %check if we are between 5% and 95% of the range, if not autoSens
            high = max(data.raw.Vsd_X(i,n),data.raw.Vsd_Y(i,n));
            if high > SD_sens*0.95 || high < SD_sens*0.05
                SD.autoSens(0.25,0.75);
                SD_sens = SD.sens();
            else
                %if the measurement was good, increment.
                n = n+1;
            end
        end
        data.time(i) = mean(data.raw.time(i,:));
        data.Vsd_X(i) = mean(data.raw.Vsd_X(i,:));
        data.Vsd_Y(i) = mean(data.raw.Vsd_Y(i,:));
        data.R(i) = mean(data.raw.R(i,:));
        data.Tvapor(i) = mean(data.raw.Tvapor(i,:));
        data.Tprobe(i) = mean(data.raw.Tprobe(i,:));
        data.std.Vsd_X(i) = std(data.raw.Vsd_X(i,:));
        data.std.Vsd_Y(i) = std(data.raw.Vsd_Y(i,:));
        data.std.R(i) = std(data.raw.R(i,:));
        data.Tvapor(i) = std(data.raw.Tvapor(i,:));
        data.Tprobe(i) = std(data.raw.Tprobe(i,:));
    end

    function save_data()
        save(fullfile(start_dir, [FileName, '.mat']),'data');
    end


%saftey checks (more checks below)
if max(abs(Vg_list)) > Vg_limit
    error('Gate voltage set above limit,exiting');
end

%% set constants
SD_phase = 0; %Phase to use on LA sine output
SD_freq = 17.777;
SD_timeConstant = 0.3; %time constant to use on LA
SD_coupling = 'AC'; %only use DC when measureing below 160mHz

%% Initialize data structure and filename
start_dir = 'C:\Crossno\data\';
start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat(datestr(StartTime, 'yyyymmdd_HHMMSS'),'_R_T__Vg_',UniqueName);

%% Initialize file structure and equipment

% Connect to the Cryo-Con 22 temperature controler
TC = deviceDrivers.Lakeshore335();
TC.connect('12');
%Connect lockin amplifier
SD = deviceDrivers.SRS830();
SD.connect('8');
%connect to YOKO gate supply
VG = deviceDrivers.YokoGS200();
VG.connect('18');

%initialize the gate
if Vg_limit <= 1.2
    VG.range = 1;
elseif Vg_limit <=12
    VG.range = 10;
else
    VG.range = 30;
end
currentVg = Vg_list(1);
VG.ramp2V(currentVg,Vg_rampRate);

%initialize Lockin
SD.sineAmp = SD_Vex;
SD.sinePhase = SD_phase;
SD.sineFreq = SD_freq;
SD.timeConstant = SD_timeConstant;
SD.inputCoupling = SD_coupling;
SD_sens = SD.sens;


% Initialize data structure
blank = zeros(1,length(Vg_list));
blank_raw = zeros(length(Vg_list),Nmeasurements);

data.time = blank;
data.Vsd_X = blank;
data.Vsd_Y = blank;
data.R = blank;
data.Tprobe = blank;
data.Tvapor = blank;

data.raw.time = blank_raw;
data.raw.Vsd_X = blank_raw;
data.raw.Vsd_Y = blank_raw;
data.raw.R = blank_raw;
data.Tprobe = blank_raw;
data.Tvapor = blank_raw;

data.Vg = Vg_list;

%record all the unsed settings
data.settings.SD.sineAmp = SD_Vex;
data.settings.SD.sinePhase = SD_phase;
data.settings.SD.sineFreq = SD_freq;
data.settings.SD.timeConstant = SD_timeConstant;
data.settings.SD.inputCoupling = SD_coupling;
data.settings.SD.Rex = SD_Rex;

%initialize plots
figure(993);clf;xlabel('Vg (Volts)');ylabel('Resistance (\Omega)');grid on;
%% main loop
pause on;
h = createPauseButton;
pause(0.01); % To create the button.
for Vg_n=1:length(Vg_list)
    
    %set Vg
    currentVg = Vg_list(Vg_n);
    VG.ramp2V(currentVg,Vg_rampRate);
    if Vg_n==1
        pause(VWaitTime1);
    else
        pause(VWaitTime2);
    end
    
    measure_data(Vg_n)
    
    %update plots
    plotResistance();
end
save_data()
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pause off
VG.ramp2V(0,Vg_rampRate);
SD.disconnect();
VG.disconnect();
TC.disconnect();
close(h);
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