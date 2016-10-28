%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cooling log using LakeShore Temperature Controller while taking VNA data
% in Oxford fridge at KimLab
% Created in Mar 2014 by Jesse Crossno and KC Fong and Evan Walsh
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Francois_T_R_and_analog_noise_log()

clear temp StartTime start_dir CoolLogData;
close all;
fclose all;

% Connect to the Cryo-Con 22 temperature controler
TC = FrancoisLakeShore335();
TC.connect('12');

resistor=10530000;
lockinVoltage=0.01;

lockin=deviceDrivers.SRS830();
lockin.connect('1');
lockin.sineAmp=lockinVoltage;

dmm=deviceDrivers.Keysight34401A();
dmm.connect('6');


% Initialize variables
%TempInterval = input('Time interval between temperature measurements (in second) = ');
%UniqueName = input('Enter uniquie file identifier: ','s');
TempInterval=0;
UniqueName='TJ cooldown and analog noise log';
start_dir = 'C:\Users\Artem\My Documents\Data\AL Tunnel Junction\';
%start_dir = uigetdir(start_dir);
StartTime = clock;
FileName = strcat('Tlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

% Initialize VNA Data
data=struct('time',[],'T_A',[],'T_B',[],'NoiseVoltage',[], 'lockin_R', [], 'lockin_theta', [], 'resistance', []);

% Log Loop

T_n = 1;
pause on;





data.time(T_n) = etime(clock, StartTime);
data.T_A(T_n) = TC.measureTempAWithPolynomialInterpolation();
data.T_B(T_n) = TC.temperatureB();
data.NoiseVoltage(T_n)=dmm.value;
data.lockin_R(T_n)=lockin.R;
data.lockin_theta(T_n)=lockin.theta;
data.resistance(T_n)=data.lockin_R(T_n)*resistor/(lockinVoltage-data.lockin_R(T_n));


save(fullfile(start_dir, FileName),'data')

figure(992); clf;
grid on; hold on;
%myplot=plot(data.time/60,data.T_A,data.time/60,data.T_B);
%plot1=myplot(1);
%plot2=myplot(2);
plot1=plot(data.time,data.T_A);
xlabel('time')
ylabel('temp (K)');

figure(993); clf;
grid on; hold on;
myplot2=plot(data.T_A, data.NoiseVoltage);
xlabel('T(K)');
ylabel('noise power Voltage (V)');

T_n = T_n+1;
pause(TempInterval);



    while true

        data.time(T_n) = etime(clock, StartTime);
        data.T_A(T_n) = TC.temperatureA();
        data.T_B(T_n) = TC.temperatureB();
        data.NoiseVoltage(T_n)=dmm.value;
        data.lockin_R(T_n)=lockin.R;
        data.lockin_theta(T_n)=lockin.theta;
        data.resistance(T_n)=data.lockin_R(T_n)*resistor/(lockinVoltage-data.lockin_R(T_n));

        save(fullfile(start_dir, FileName),'data')

        %figure(992); clf; xlabel('time (min)');ylabel('Temperature (K)'); 
        %grid on; hold on;1
        set(plot1,'XData',data.time,'YData',data.T_A);
        %set(plot2,'XData',data.time/60,'YData',data.T_B);
        %plot(,,data.time/60,data.T_B)
        set(myplot2,'XData',data.T_A,'YData',data.NoiseVoltage);

        T_n = T_n+1;
        pause(TempInterval);
    end
end