SD = deviceDrivers.SRS830;
SD.connect('1');
Nac = deviceDrivers.SRS830;
Nac.connect('2');
pause on

Rex = 558E3;

Vex = SD.sineAmp();
V = SD.X;
I = (Vex-V)/Rex;

Nac.harm = 2;
tc = Nac.timeConstant;
pause(7*tc);
two_f = Nac.R;

Nac.harm = 1;
pause(7*tc);
one_f = Nac.R;

Idc = one_f * I / (two_f * 2 * sqrt(2))

SD.disconnect();Nac.disconnect();
clear Rex Vex g V I SD Nac