       resistance=10530000;
    leadResistance=0;
    
    tempWaitTime=30;%60*.2; %3 mins
    temperatureWindow=0.003; %difference to setpoint when temperature is considered reached
    gateVoltageList=[-1:.05:-.65   -.6:.01:-.2 -.15:.05:.2 .3:.1:1];
    gateVoltageList=[0];
    %gateVoltageList=-1:0.05:1;
    %gateVoltageList=0;
    %tempList=[3 4:2:100];
    tempList=[305:-1:3];
    lockInTimeConstant=3;
    tempRampRate=2; %K/min
    numberOfCycles=300;
    
    UniqueName='Al TJ gain calibration 3 to 100K';
    start_dir = 'C:\Users\Artem\My Documents\Data\AL Tunnel Junction\';
    
    JNCal_measure_gain_analog(UniqueName, start_dir, numberOfCycles, tempWaitTime, temperatureWindow, tempRampRate, resistance, leadResistance, gateVoltageList, tempList, lockInTimeConstant)
