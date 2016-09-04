%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cooling log using LakeShore Temperature Controller while taking VNA data
% in Oxford fridge at KimLab
% Created in Mar 2014 by Jesse Crossno and KC Fong and Evan Walsh
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Rodriguez_T_and_noise_log()

clear temp StartTime start_dir CoolLogData;
close all;
fclose all;

% Connect to the Cryo-Con 22 temperature controler
TC = FrancoisLakeShore335();
TC.connect('12');

alazarLoadLibrary();
digitizer = deviceDrivers.ATS850Driver(1,1);
digitizer.configureDefault(.02,.02);
maxSamples=262144-4;
numSamples=2^10;
numAvg=255;


% Initialize variables
%TempInterval = input('Time interval between temperature measurements (in second) = ');
%UniqueName = input('Enter uniquie file identifier: ','s');
TempInterval=0;
UniqueName='50 Ohm R noise log at base';
start_dir = 'C:\Users\Artem\My Documents\Data\Digitizer Card Testing\';
%start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat('Tlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');
R=18000;

% Initialize VNA Data
data=struct('time',[],'T_A',[],'T_B',[],'NoisePower',[]);

% Log Loop

T_n = 1;
pause on;





[pwA,~]=digitizer.acquireTotalAvgVoltagePowerWithSpectralMask([0 1.31e7; 1.56e7 3e7], [0 1.31e7; 1.56e7 3e7], numSamples, numAvg, R, 1, 'A');

data.time(T_n) = etime(clock, StartTime);
data.T_A(T_n) = TC.measureTempAWithPolynomialInterpolation();
data.T_B(T_n) = TC.temperatureB();
data.NoisePower=pwA;


save(fullfile(start_dir, FileName),'data')

figure(992); clf; xlabel('time (s)');ylabel('Temperature (K)'); 
grid on; hold on;
%myplot=plot(data.time/60,data.T_A,data.time/60,data.T_B);
%plot1=myplot(1);
%plot2=myplot(2);
plot1=plot(data.time,data.T_A);

figure(993); clf; xlabel('time(s))'); ylabel('Total Noise Power (W)');
grid on; hold on;
myplot2=plot(data.time, data.NoisePower);

T_n = T_n+1;
pause(TempInterval);



while true
    

    [pwA,~]=digitizer.acquireTotalAvgVoltagePowerWithSpectralMask([0 1.31e7; 1.56e7 3e7], [0 1.31e7; 1.56e7 3e7], numSamples, numAvg, R, 1, 'A');

    data.time(T_n) = etime(clock, StartTime);
    data.T_A(T_n) = TC.measureTempAWithPolynomialInterpolation();
    data.T_B(T_n) = TC.temperatureB();
    data.NoisePower(T_n)=pwA;
    
    save(fullfile(start_dir, FileName),'data')

    %figure(992); clf; xlabel('time (min)');ylabel('Temperature (K)'); 
    %grid on; hold on;1
    set(plot1,'XData',data.time,'YData',data.T_A);
    %set(plot2,'XData',data.time/60,'YData',data.T_B);
    %plot(,,data.time/60,data.T_B)
    set(myplot2,'XData',data.time,'YData',data.NoisePower);
    
    T_n = T_n+1;
    pause(TempInterval);
end
pause off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TC.disconnect();
clear TC;