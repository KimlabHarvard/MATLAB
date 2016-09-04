%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     What and hOw?      %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cooling log using LakeShore Temperature Controller while taking VNA data
% in Oxford fridge at KimLab
% Created in Mar 2014 by Jesse Crossno and KC Fong and Evan Walsh
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = Francois_Data_log()

clear temp StartTime start_dir CoolLogData;
close all;
fclose all;

% Connect to the Cryo-Con 22 temperature controler
TC = FrancoisLakeShore335();
TC.connect('12');

%currentSource=deviceDrivers.Keithley2450();
%currentSource.connect('26');

range=.1;
alazarLoadLibrary();
digitizer = deviceDrivers.ATS850Driver(1,1);
    digitizer.setTriggerTimeout(1);
    digitizer.configureChannel('A', 'AC', range, 50);
    digitizer.configureChannel('B', 'DC', 4, 1000000);
    
maxSamples=262144-4;
numSamples=2^10;
numAvg=255;

digitizer.setSizeSpectralVoltagePower(numSamples,numAvg);

TempInterval=0;
%UniqueName='Al Tunnel Junction current sweep base';
UniqueName='Al TJ noise temp';
start_dir = 'C:\Users\Artem\My Documents\Data\AL Tunnel Junction\';
StartTime = clock;
FileName = strcat('Tlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');
R=21000;

%currentList = [0 2 4 6 8 10 13 17 20 25 30 35 40 45 50 60 70 80 90 100 120 130 140 150 175 200 225 250 275 300 350 400 450 500]*1e-9;
currentList = [0 5 10 15 20 30 50 70 100 150 200 250 350 500]*1e-9;
timeAtCurrentInMins=3;
currentIndex=1;

% Initialize VNA Data
data=struct('time',[],'T_A',[],'T_B',[],'NoisePower',[],'runningAvgNoisePower',[],'current',[],'voltage',[]);

% Log Loop

T_n = 1;
pause on;


%currentSource.current=currentList(currentIndex);
%currentSource.output=1;


[pwA,~]=digitizer.acquireTotalAvgVoltagePowerWithSpectralMask([0 1.31e7; 1.56e7 3e7], [0 1.31e7; 1.56e7 3e7], 'A');

data.time(T_n) = etime(clock, StartTime);
data.T_A(T_n) = TC.measureTempAWithPolynomialInterpolation();
data.T_B(T_n) = TC.temperatureB();
data.NoisePower(T_n)=pwA;
%data.current(T_n)=currentList(currentIndex);
data.runningAvgNoisePower(T_n)=pwA;
%data.voltage(T_n)=currentSource.voltage;
runningAvgSize=300;


save(fullfile(start_dir, FileName),'data')

figure(992); clf;

%myplot=plot(data.time/60,data.T_A,data.time/60,data.T_B);
%plot1=myplot(1);
%plot2=myplot(2);
plot1=plot(data.time,data.NoisePower);
xlabel('time(s))');ylabel('noise power (W)'); 
grid on; hold on;

figure(993); clf;

myplot2=plot(data.time, data.T_A);
xlabel('time(s))'); ylabel('Temp (K)');
grid on; hold on;

figure(994); clf;

myplot3=plot(data.T_A, data.runningAvgNoisePower);
xlabel('TEMP (K)'); ylabel('running avg Powr (W)');
grid on; hold on;

T_n = T_n+1;
pause(TempInterval);

figure(1000)

while true
    
    
    [pwA,~]=digitizer.acquireTotalAvgVoltagePowerWithSpectralMask([0 1.31e7; 1.56e7 3e7], [0 1.31e7; 1.56e7 3e7], 'A');

    data.time(T_n) = etime(clock, StartTime);
    data.T_A(T_n) = TC.measureTempAWithPolynomialInterpolation();
    data.T_B(T_n) = TC.temperatureB();
    data.NoisePower(T_n)=pwA;
    %data.current(T_n)=currentList(currentIndex);
    myIndex=T_n-runningAvgSize;
    if(myIndex<1)
        myIndex=1;
    end
    data.runningAvgNoisePower(T_n)=sum(data.NoisePower(myIndex:T_n))/(T_n-myIndex);
    %data.voltage(T_n)=currentSource.voltage;
    
    save(fullfile(start_dir, FileName),'data')

    %figure(992); clf; xlabel('time (min)');ylabel('Temperature (K)'); 
    %grid on; hold on;1
    set(plot1,'XData',data.time,'YData',data.NoisePower);
    %set(plot2,'XData',data.time/60,'YData',data.T_B);
    %plot(,,data.time/60,data.T_B)
    firstIndex=T_n-runningAvgSize;
    if(firstIndex<1)
        data.runningAvgNoisePower(T_n)=NaN;
    end
    %set(myplot2,'XData',data.current,'YData',sum(data.NoisePower(firstIndex:T_n))/runningAvgSize);
    set(myplot2,'XData',data.time,'YData',data.T_A);
    set(myplot3,'XData',data.T_A,'YData',data.runningAvgNoisePower);
    
    T_n = T_n+1;
    pause(TempInterval);
end
pause off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       Clear     %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TC.disconnect();
clear TC;