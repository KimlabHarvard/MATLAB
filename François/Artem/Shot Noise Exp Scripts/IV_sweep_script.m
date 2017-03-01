R_externalAC=10530000;
R_externalDC=9936;

V_ext_list=[-6:.2:6];

biasController_Vdc=deviceDrivers.YokoGS200();
biasController_Vdc.connect('18');
biasController_Vdc.range=10;
assert(strcmp(biasController_Vdc.mode,'VOLT'),'wrong bias source mode');

%drive current through fake resistor
%measure the voltage drop aross the device
voltageMeter_Rdc=deviceDrivers.Keithley2000();
voltageMeter_Rdc.connect('17');

clear V_dc_meas;
for(k=1:length(V_ext_list))
    biasController_Vdc.ramp2V(V_ext_list(k),.5);
    dontuse=voltageMeter_Rdc.fetch;
    pause(1);
    clear jake;
    for(p=1:3)
       jake(p)=voltageMeter_Rdc.fetch;
       %pause(0.3);
    end
    V_dc_meas(k)=mean(jake);
    k
end
figure(1); clf;
plot( V_dc_meas,V_ext_list/R_externalDC);
xlabel('V');
ylabel('I approx');

figure(2); clf;
plot(V_dc_meas, V_dc_meas./(V_ext_list/R_externalDC));
xlabel('V');
ylabel('R approx');

figure(3); clf;
plot(V_ext_list/R_externalDC, V_dc_meas);
xlabel('I approx');
ylabel('V');

biasController_Vdc.disconnect
voltageMeter_Rdc.disconnect