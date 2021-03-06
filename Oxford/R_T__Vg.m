%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cooling log using LakeShore Temperature Controller while taking VNA data
% in Oxford fridge at KimLab
% Created in Mar 2014 by Jesse Crossno and KC Fong and Evan Walsh
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = R_T__Vg(Vg_list)

%Internal convenience functions
    function plotTemperature()
        figure(992); clf; xlabel('Vg (Volts)');ylabel('Temperature (K)');
        grid on; hold on;
        plot(data.Vg,data.tempVapor,'r')
        plot(data.Vg,data.tempProbe,'b')
        legend('Vapor','Probe')
    end
    function plotResistance()
        figure(993); clf; xlabel('Vg (Volts)');ylabel('Resistance (\Omega)');
        grid on; hold on;
        plot(data.Vg,data.R,'b')
    end

%measures the "fast" variables: Temp,Res, Field, and time
    function measure_fast_data(i,j)
        data.time(i,j) = etime(clock, StartTime);
        data.tempVapor(i,j) = TC.get_temperature('A');
        data.tempProbe(i,j) = TC.get_temperature('B');
        data.LA_X(i,j) = LA.X;
        data.LA_Y(i,j) = LA.Y;
        data.R(i,j) = data.LA_X(i,j)*Rex/Vex;
        data.Vg(i,j) = currentVg;
    end

    function saveData()
        save(fullfile(start_dir, FileName),'data');
        lastSave = clock;
    end

% Connect to the Cryo-Con 22 temperature controler
TC = deviceDrivers.Lakeshore335();
TC.connect('12');
%Connect lockin amplifier
LA = deviceDrivers.SRS830();
LA.connect('8')
%connect to YOKO gate supply
VG = deviceDrivers.YokoGS200();
VG.connect('17')


%saftey checks (more checks below)
assert(max(abs(Vg_list)) <= 32,'Gate voltage set above 30 V');


%get experiment parameters from user
Rex = 9.79E6; % resistor in series with sample for resistance measurements
Nmeasurements = input('How many measurements per parameter point? ');
VWaitTime1 = input('Enter initial Vg equilibration time: ');
VWaitTime2 = input('Enter Vg equilibration time for each step: ');
Vex = input('Enter source-drain excitation voltage: ');
MeasurementWaitTime = input('Enter time between lockin measurents: ');
assert(isnumeric(Nmeasurements)&&isnumeric(VWaitTime1)&&isnumeric(VWaitTime2)...
    &&isnumeric(Vex)&&isnumeric(MeasurementWaitTime)&&Nmeasurements >= 0 ...
    &&VWaitTime1 >= 0&&VWaitTime2 >= 0&&Vex >= 0&&MeasurementWaitTime >= 0 ...
    , 'Oops! please enter non-negative values only')
UniqueName = input('Enter uniquie file identifier: ','s');
aditional_info = input('Any additional info to include with file? ','s');

% Initialize data structure and filename
start_dir = 'C:\Crossno\data\';
start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat('R_T__Vg_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

data = struct('time',[],'tempVapor',[],'tempProbe',[],'LA_X',[],'LA_Y',[], ...
    'R',[],'Vg',[],'LA',struct('Vex', Vex,'Rex',Rex,'timeConstant',LA.timeConstant()) ...
    ,'info',aditional_info);


%never go longer than saveTime without saving
saveTime = 60; %in seconds
lastSave = clock;

%initilze data counter
pause on;
h = createPauseButton;
pause(0.01); % To create the button.
%main loop
for Vg_n=1:length(Vg_list)
    
    %set Vg
    currentVg = Vg_list(Vg_n);
    VG.ramp2V(currentVg);
    if Vg_n==1
        pause(VWaitTime1);
    else
        pause(VWaitTime2);
    end
    
    %take "fast" data
    for n=1:Nmeasurements
        pause(MeasurementWaitTime);
        measure_fast_data(Vg_n,n);
    end
     
    %update plots
    plotTemperature();
    plotResistance();
    
    %save every "saveTime" seconds
    if etime(clock, lastSave) > saveTime
        saveData();
    end

    saveData()
    
end
pause off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VG.ramp2V(0,0);
TC.disconnect();
SD.disconnect();
clear TC LA MS
end