SD = deviceDrivers.SRS830;
SD.connect('1');
Nac = deviceDrivers.SRS830;
Nac.connect('2');
TC = deviceDrivers.Lakeshore335;
TC.connect('12')

Rex = 558E3;
Vex = SD.sineAmp();

V = SD.X;
I = (Vex-V)/Rex;
R = V/I;
g = gain_curve(log10(R));
Tac = 2*sqrt(2)*Nac.X/g;
Tb = TC.temperatureA();
Q = 2*I^2*(R);
G = Q/Tac;
L = G*(R)/(12*2.44E-8*Tb)
SD.disconnect();Nac.disconnect(); TC.disconnect();
clear Rex Vex g V I SD Nac