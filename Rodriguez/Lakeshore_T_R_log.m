%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cooling log using LakeShore Temperature Controller while taking VNA data
% in Oxford fridge at KimLab
% Created in Mar 2014 by Jesse Crossno and KC Fong and Evan Walsh
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Lakeshore_T_R_log(T_list)

clear temp StartTime start_dir CoolLogData;
close all;
fclose all;

% Connect to the Cryo-Con 22 temperature controler
TC = deviceDrivers.Lakeshore335();
LA = deviceDrivers.SRS830();
TC.connect('12');
LA.connect('2');


% Initialize variables
TempInterval = input('Time interval between temperature measurements (in second) = ');
RampRate = input('Enter ramp rate: ');
FinalT = input('Enter final Temperature: ');
UniqueName = input('Enter uniquie file identifier: ','s');
start_dir = 'C:\GitHub\Graphene\Expt Control\Rodriguez\CoolLogs';
start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat('Coollog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');


% Initialize VNA Data
data=struct('time',[],'temp',[],'X',[],'Y',[],'resistance',[]);

% Log Loop
n=1;
pause on;
TC.rampRate1 = RampRate;
TC.setPoint1 = FinalT;
while true
    
    data.time(n) = etime(clock, StartTime);
    data.temp(n) = TC.temperatureA;
    [data.X(n),data.Y(n)] = LA.snapXY();
    data.resistance(n) = data.X(n)*1E4;
    
    save(fullfile(start_dir, FileName),'data')

    figure(992); clf; xlabel('time (min)');ylabel('Temperature (K)'); 
    grid on; hold on;
    plot(data.time/60,data.temp,'r')
    
    figure(993); clf; xlabel('Temperature (K)');ylabel('Resistance (\Omega)'); 
    grid on; hold on;
    plot(data.temp,data.resistance)
    
    n=n+1;
    pause(TempInterval);
end
pause off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TC.disconnect();
LA.disconnect();
clear TC LA;