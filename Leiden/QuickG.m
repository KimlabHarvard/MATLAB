SD = deviceDrivers.SRS830();
SD.connect('1');
Nac = deviceDrivers.SRS830;
Nac.connect('2');
Th = deviceDrivers.X110375(101.1E6,'7');

Rex = 46E3;
Vex = SD.sineAmp();


V = SD.R;
I = (Vex-V)/Rex;
R = V/I;
g = gain_curve(log10(R));
Tac = 2*sqrt(2)*Nac.R/g;
Tb = Th.temperature();
Q = 2*(I)^2*R;
G = Q/Tac;
L = G*R/(12*2.44E-8*Tb)
SD.disconnect();Nac.disconnect(); pause(1);
close_all()
clear Rex Vex g V I SD Nac