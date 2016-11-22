    bigResistor=10530000;
    leadResistance=0;
    
    tempWaitTime=30;%60*.2; %3 mins
    temperatureWindow=0.005; %difference to setpoint when temperature is considered reached
    gateVoltageList=[-1:.05:-.65   -.6:.01:-.2 -.15:.05:.2 .3:.1:1];
    gateVoltageList=[0];
    %gateVoltageList=-1:0.05:1;
    %gateVoltageList=0;
    %tempList=[3 4:2:100];
    tempList=[300:-25:100 90:-10:40 35:-5:10 8 6 4 3];
    lockInTimeConstant=3;
    tempRampRate=2; %K/min
    numberOfCycles=30;
    
    
    UniqueName='A3 Al TJ3 cal Johnson Noise 300K to 3K quick';
    start_dir = 'C:\Users\Artem\My Documents\Artem Data\AL Tunnel Junction\';
    
    Francois_T_Vg___R_NDCAnalog(UniqueName, start_dir, numberOfCycles, tempWaitTime, temperatureWindow, tempRampRate, bigResistor, leadResistance, gateVoltageList, tempList, lockInTimeConstant)