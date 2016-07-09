SD = deviceDrivers.SRS830();
SD.connect('1');
Nac = deviceDrivers.SRS830;
Nac.connect('2');

Rex = 46E3;
Vex = SD.sineAmp();

R = SD.X*Rex/Vex;
%g = gain_curve(log10(R));
g = 0.483/300;
T = 2*sqrt(2)*Nac.R/g;
Q = 2*(SD.X)^2/R;
G = Q/T;
L = G/(12*2.44E-8*4.8/R)

SD.disconnect();
Nac.disconnect();
clear Rex Vex g SD Nac