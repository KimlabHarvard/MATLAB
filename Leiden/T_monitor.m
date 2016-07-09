close_all;
Ndc = deviceDrivers.Keithley2450();
Ndc.connect('140.247.189.130');
SD = deviceDrivers.SRS830();
SD.connect('1');
T = deviceDrivers.X110375(101.1E6,'7');
pause on;
figure()
Ts=[];
Rs=[];
Tb=[];
while true
    Rs=[Rs SD.X*10.8E6];
    g=gain_curve(log10(Rs(end)));
    Ts=[Ts 4.8+(Ndc.voltage()-.140)*10/g];
    Tb=[Tb T.temperature()];
    clf;
    plotyy(1:length(Ts),Ts,1:length(Ts),Rs);
    pause(0.5)
end