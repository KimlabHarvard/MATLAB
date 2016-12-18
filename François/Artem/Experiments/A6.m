%measure VNA and R vs T for hans, the cuprate sample
UniqueName='Hans VNA vs T A6';
start_dir='C:\Users\Artem\My Documents\Artem Data\';
start_dir = uigetdir(start_dir)
tempRampRate=3; %K/min
tempWaitTime=30; %seconds
temperatureWindow=0.1;
tempList=[3.11 4:2:30 35:5:60 70:10:300];
resistanceExternal=10530000;
gateVoltageList=0;
lockInTimeConstant=3;
leadResistance=0;


Francois_T_Vg___R_VNA(UniqueName, start_dir, tempWaitTime, temperatureWindow, tempRampRate, resistanceExternal, leadResistance, gateVoltageList, tempList, lockInTimeConstant)
    