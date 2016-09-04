function V = K2450_IV(I_list)
V = zeros(1,length(I_list));
IS = deviceDrivers.Keithley2450;
IS.connect('140.247.189.121');
IS.sourceMode = 'CURR';
IS.measMode = 'VOLT';
IS.count = 1;
IS.NPLC = 10;
IS.current = I_list(1);
IS.output = 1;
pause on;
for I_n=1:length(I_list)
    IS.current = I_list(I_n);
    pause(1);
    V(I_n) = IS.voltage;
end
IS.output = 0;
IS.disconnect;

        