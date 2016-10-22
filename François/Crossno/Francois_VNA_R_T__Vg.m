%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Records VNA, resistance via lockin, and temperature
% on Francois in Kimlab
% Created in Sep 2016 by Jesse Crossno
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Francois_VNA_R_T__Vg(Vg_list, Vg_limit, Vg_rampRate,...
        Nmeasurements, VWaitTime1, VWaitTime2, measurementWaitTime, VNAwaitTime,...
        SD_Rex, SD_Vex, UniqueName)
    %%Internal convenience functions
    
    function plot1Dconductance()
        change_to_figure(991); clf;
        mask = find(data.R ~= 0);
        plot(data.Vg(mask), squeeze(25813./data.R(mask)),'.','MarkerSize',15);
        xlabel('Vg (Volts)');ylabel('Conductance (h/e^2)');
        box on; grid on;
    end
    
    function plotVNA()
        change_to_figure(992); clf;
        surf(data.freq*1E-6,data.Vg,20*log10(abs(data.traces)));
        xlabel('Frequency (MHz)');ylabel('Gate Voltage (V)');box on;grid on;
        xlim([min(data.freq*1E-6),max(data.freq*1E-6)]);
        view(2);shading flat;
        h = colorbar; ylabel(h,'S11^2');
        box on; colormap(cmap);
    end
    %measures the data
    function measure_data(Vn)
        n = 1;
        t = clock;
        %repeat measurements n time (excluding VNA)
        while n <= Nmeasurements
            while etime(clock,t) < measurementWaitTime
            end
            t = clock; %pausing this way accounts for the measurement time
            data.raw.time(Vn,n) = etime(clock, StartTime);
            data.raw.T(Vn,n) = TC.temperatureA();
            [data.raw.Vsd_X(Vn,n), data.raw.Vsd_Y(Vn,n)] = SD.snapXY();
            Vsd = sqrt(data.raw.Vsd_X(Vn,n)^2+data.raw.Vsd_Y(Vn,n)^2);
            data.raw.R(Vn,n) = Vsd*SD_Rex/(SD_Vex-Vsd);
            
            
            %check if we are between 5% and 95% of the range, if not autoSens
            high = max(data.raw.Vsd_X(Vn,n),data.raw.Vsd_Y(Vn,n));
            if high > SD_sens*0.95 || high < SD_sens*0.05
                SD.autoSens(0.25,0.75);
                SD_sens = SD.sens();
            else
                %if the measurement was good, increment.
                n = n+1;
            end
        end
        data.time(Vn) = mean(data.raw.time(Vn,:));
        data.Vsd_X(Vn) = mean(data.raw.Vsd_X(Vn,:));
        data.Vsd_Y(Vn) = mean(data.raw.Vsd_Y(Vn,:));
        data.R(Vn) = mean(data.raw.R(Vn,:));
        data.T(Vn) = mean(data.raw.T(Vn,:));
        data.std.Vsd_X(Vn) = std(data.raw.Vsd_X(Vn,:));
        data.std.Vsd_Y(Vn) = std(data.raw.Vsd_Y(Vn,:));
        data.std.R(Vn) = std(data.raw.R(Vn,:));
        data.T(Vn) = mean(data.raw.T(Vn,:));
        VNA.trigger;
        data.traces(Vn,:) = single(VNA.getSingleTrace());
        pause(VNAwaitTime);
    end
    
    function save_data()
        save(fullfile(start_dir, [FileName, '.mat']),'data');
    end
    
    %saftey checks (more checks below)
    assert(max(abs(Vg_list)) <= Vg_limit,sprintf('Gate voltage set above %.1f',Vg_limit));
    pause on;
    
    %% get experiment parameters from user
    
    %set constants
    SD_phase = 0; %Phase to use on LA sine output
    SD_freq = 17.777;
    SD_timeConstant = 0.3; %time constant to use on LA
    SD_coupling = 'AC'; %only use DC when measureing below 160mHz
    
    % Initialize data structure and filename
    start_dir = 'C:\Crossno\data\';
    start_dir = uigetdir(start_dir);
    StartTime = clock;
    FileName = strcat(datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',mfilename(),'_',UniqueName);
    
    %% Initialize file structure and equipment
    TC = deviceDrivers.Lakeshore335();
    TC.connect('12');
    % Connect to the VNA
    VNA = deviceDrivers.AgilentE8363C();
    VNA.connect('140.247.189.127')
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
    blank = zeros(1,length(Vg_list));
    blank_raw = zeros(length(Vg_list),Nmeasurements);
    blank_traces = single(complex(ones(length(Vg_list),length(freq))));
    
    data.time = blank;
    data.T = blank;
    data.Vsd_X = blank;
    data.Vsd_Y = blank;
    data.R = blank;
    
    data.raw.time = blank_raw;
    data.raw.T = blank;
    data.raw.Vsd_X = blank_raw;
    data.raw.Vsd_Y = blank_raw;
    data.raw.R = blank_raw;
    
    data.traces = blank_traces;
    
    data.Vg = Vg_list;
    data.freq = freq;
    
    data.log = struct('time',[],'Tvapor',[],'Tprobe',[],'SD_X',[],'SD_Y',[],...
        'R',[],'field',[]);
    
    %record all the unsed settings
    data.settings.SD.sineAmp = SD_Vex;
    data.settings.SD.sinePhase = SD_phase;
    data.settings.SD.sineFreq = SD_freq;
    data.settings.SD.timeConstant = SD_timeConstant;
    data.settings.SD.inputCoupling = SD_coupling;
    data.settings.SD.Rex = SD_Rex;
    
    %initialize plots and GUIs
    cmap = cbrewer('div','RdYlBu',64,'linear');
    scrsz = get(groot,'ScreenSize');
    figure(991);set(gcf,'Position',[10, scrsz(4)/2, scrsz(3)/3-10, 0.84*scrsz(4)/2]);
    figure(992);set(gcf,'Position',[10+2*scrsz(3)/3, scrsz(4)/2, scrsz(3)/3-10, 0.84*scrsz(4)/2]);
    tic
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%       main loop    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                measure_data(Vg_n)
                break
            catch
                attempts = attempts+1;
                if attempts < 10
                    warning('failed to collect data at %.3f V. retrying.',...
                        currentVg);
                else
                    warning('failed 10 times. moving on')
                    break
                end
            end
        end
        
        plot1Dconductance();
        if mod(Vg_n,1) == 0
            plotVNA();
        end  
    end
    save_data();
    toc
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    VG.ramp2V(0,Vg_rampRate);
    TC.disconnect();
    VNA.disconnect();
    SD.disconnect();
    VG.disconnect();
end