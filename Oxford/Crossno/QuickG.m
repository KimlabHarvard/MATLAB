SD = deviceDrivers.SRS830;
SD.connect('8');
Nac = deviceDrivers.SRS830;
Nac.connect('9');
TC = deviceDrivers.Lakeshore335;
TC.connect('12')

Rex = 558E3;
Vex = SD.sineAmp();


V = SD.X;
I = (Vex-V)/Rex;
R = V/I;
g = gain_curve(log10(R));
Tac = 2*sqrt(2)*Nac.R/g;
Tb = TC.temperatureB();
Q = 2*I^2*(R);
G = Q/Tac;
L = G*(R)/(12*2.44E-8*Tb)
SD.disconnect();Nac.disconnect(); pause(1);
clear Rex Vex g V I SD Nac