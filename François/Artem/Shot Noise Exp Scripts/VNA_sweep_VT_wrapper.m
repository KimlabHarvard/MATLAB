    resistance=10530000;
    leadResistance=0;
    
    tempWaitTime=10;%60*.2; %3 mins
    temperatureWindow=0.003; %difference to setpoint when temperature is considered reached
    gateVoltageList=[-1:.05:-.65   -.6:.01:-.2 -.15:.05:.2 .3:.1:1];
    gateVoltageList=[0];
    %gateVoltageList=-1:0.05:1;
    %gateVoltageList=0;
    %tempList=[3 4:2:100];
    tempList=[315];
    lockInTimeConstant=3;
    tempRampRate=3; %K/min
    
    UniqueName='Al TJ VNA 100 to 5 K';
    start_dir = 'C:\Users\Artem\My Documents\Data\AL Tunnel Junction\';
    
    VNA_sweep_VT(UniqueName, start_dir, tempWaitTime, temperatureWindow, tempRampRate, resistance, leadResistance, gateVoltageList, tempList, lockInTimeConstant)
