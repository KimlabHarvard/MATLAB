%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Records VNA, resistance via lockin, and temperature of X110375 via lockin
% on leiden in Kimlab
% Created in Jun 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = leiden_VNA_R_T__B_Vg(B_list,Vg_list, Nmeasurements, VWaitTime1,...
    VWaitTime2, measurementWaitTime, VNAwaitTime, rampRate, SD_Rex, SD_Vex, ...
    EmailJess, EmailKC, UniqueName)
%%Internal convenience functions

    function plot1Dconductance(i)
        change_to_figure(992); clf;
        plot(data.Vg, 25813./data.R(i,:),'.','MarkerSize',15);
        xlabel('Vg (Volts)');ylabel('Conductance (h/e^2)');
        box on; grid on;
    end
    function plot2Dresistance()
        change_to_figure(993); clf;
        surf(data.Vg,data.B,data.R);
        xlabel('Vg (Volts)');ylabel('Field (T)');
        view(2);shading flat; colorbar; box on; colormap(flipud(cmap));
    end
    function plotVNA(i)
        change_to_figure(991); clf;
        surf(data.freq*1E-6,data.Vg,squeeze(20*log10(abs(data.traces(i,:,:)))));
        xlabel('Frequency (MHz)');ylabel('freq (MHz)');box on;grid on;
        xlim([10,110]);
        view(2);shading flat; 
        h = colorbar; ylabel(h,'S11^2');
        box on; colormap(cmap);
    end

%measures the data
    function measure_data(i,j,measure_VNA)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(i,j,n) = etime(clock, StartTime);
            data.raw.T(i,j,n) = T.temperature();
            [data.raw.Vsd_X(i,j,n), data.raw.Vsd_Y(i,j,n)] = SD.snapXY();
            Vsd = sqrt(data.raw.Vsd_X(i,j,n)^2+data.raw.Vsd_Y(i,j,n)^2);
            data.raw.R(i,j,n) = Vsd*SD_Rex/(SD_Vex-Vsd);
                
            
            %check if we are between 5% and 95% of the range, if not autoSens
            high = max(data.raw.Vsd_X(i,j,n),data.raw.Vsd_Y(i,j,n));
            if high > SD_sens*0.95 || high < SD_sens*0.05
                SD.autoSens(0.25,0.75);
                SD_sens = SD.sens();
            else
                %if the measurement was good, increment.
                n = n+1;
            end   
        end
        data.time(i,j) = mean(data.raw.time(i,j,:));
        data.T(i,j) = mean(data.raw.T(i,j,:));
        data.Vsd_X(i,j) = mean(data.raw.Vsd_X(i,j,:));
        data.Vsd_Y(i,j) = mean(data.raw.Vsd_Y(i,j,:));
        data.R(i,j) = mean(data.raw.R(i,j,:));
        data.std.T(i,j) = std(data.raw.T(i,j,:));
        data.std.Vsd_X(i,j) = std(data.raw.Vsd_X(i,j,:));
        data.std.Vsd_Y(i,j) = std(data.raw.Vsd_Y(i,j,:));
        data.std.R(i,j) = std(data.raw.R(i,j,:));
        if measure_VNA
            VNA.trigger;
            data.traces(i,j,:) = single(VNA.getSingleTrace());
            pause(VNAwaitTime);
        end
    end

    function save_data()%i,j, save_VNA)
        save(fullfile(start_dir, [FileName, '.mat']),'data');
    end


%saftey checks (more checks below)
assert(max(abs(Vg_list)) <= 32,'Gate voltage set above 32 V');
assert(max(abs(B_list)) <= 5, 'field set above 5 T');
pause on;

%% get experiment parameters from user

%set constants
SD_phase = 0; %Phase to use on LA sine output
SD_freq = 17.777;
SD_timeConstant = 0.3; %time constant to use on LA
SD_coupling = 'AC'; %only use DC when measureing below 160mHz

% Initialize data structure and filename
start_dir = 'D:\Crossno\data\';
start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat(datestr(StartTime, 'yyyymmdd_HHMMSS'),'_VNA_R_T__Vg_',UniqueName);

%% Initialize file structure and equipment
% Connect to the thermometer via lockin
T = deviceDrivers.X110375(101.1E6,'7');
% Connect to the VNA
VNA = deviceDrivers.AgilentE8363C();
VNA.connect('140.247.189.42')
%Connect source-drain lockin amplifier
SD = deviceDrivers.SRS830();
SD.connect('1')
%connect to YOKO gate supply
VG = deviceDrivers.YokoGS200();
VG.connect('140.247.189.132')
%connect to magnet supply
MS = deviceDrivers.AMI430();
MS.connect('140.247.189.135');

%initialize magnet supply
MS.ramp_rate = 0.001;
pause(1) %gives the magent supply a second to catch up
target_field = B_list(1);
MS.target_field = target_field;
MS.ramp();

%initialize the gate
VG.range = 30;
currentVg = Vg_list(1);
VG.ramp2V(currentVg,rampRate);

%initialize Lockin
SD.sineAmp = SD_Vex;
SD.sinePhase = SD_phase;
SD.sineFreq = SD_freq;
SD.timeConstant = SD_timeConstant;
SD.inputCoupling = SD_coupling;
SD_sens = SD.sens;

%initialize VNA
VNA.trigger_source = 'manual';
freq = VNA.getX;

% Initialize data structure
blank = zeros(length(B_list),length(Vg_list));
blank_raw = zeros(length(B_list),length(Vg_list),Nmeasurements);
blank_traces = single(complex(ones(length(B_list),length(Vg_list),length(freq))));

data.time = blank;
data.T = blank;
data.Vsd_X = blank;
data.Vsd_Y = blank;
data.R = blank;

data.raw.time = blank_raw;
data.raw.T = blank_raw;
data.raw.Vsd_X = blank_raw;
data.raw.Vsd_Y = blank_raw;
data.raw.R = blank_raw;

data.traces = blank_traces;

data.B = B_list;
data.Vg = Vg_list;
data.freq = freq;

%record all the unsed settings
data.settings.SD.sineAmp = SD_Vex;
data.settings.SD.sinePhase = SD_phase;
data.settings.SD.sineFreq = SD_freq;
data.settings.SD.timeConstant = SD_timeConstant;
data.settings.SD.inputCoupling = SD_coupling;
data.settings.SD.Rex = SD_Rex;
data.settings.MS.ramp_rate = MS.ramp_rate;
data.settings.MS.field_units = MS.field_units;
data.settings.MS.ramp_rate_units = MS.ramp_rate_units;

%initialize plots
cmap = cbrewer('div','RdYlBu',64,'linear');
figure(993);
figure(992);
figure(991);
%% main loop
pb = createPauseButton;
pause(0.01);
tic
for B_n=1:length(B_list)
    %set field
    target_field = B_list(B_n);
    MS.target_field = target_field;
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
        if Vg_n==1
            pause(VWaitTime1);
        else
            pause(VWaitTime2);
        end
        
        measure_data(B_n,Vg_n,1)
        
        plot1Dconductance(B_n);
        if mod(Vg_n,25) == 1
            plot2Dresistance();
            plotVNA(B_n);
        end    
    end
    save_data();
    toc
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pause off
close(pb)
VG.ramp2V(0,rampRate);
%MS.zero();
T.disconnect();
VNA.disconnect();
SD.disconnect();
MS.disconnect();
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