%load calibration.csv;
calibration=csvread('calibration.csv');
tempSetpoints=calibration(:,1);
avgCalibratedTemps=calibration(:,2);
calibratedTempsStDev=calibration(:,3);
calibratedTempsErrorOfMean=calibration(:,4);
avgVoltage=calibration(:,5);
voltageStDev=calibration(:,6);
voltageErrorOfMean=calibration(:,7);

figure(1);
plot(tempSetpoints(4:end),tempSetpoints(4:end)-avgCalibratedTemps(4:end),'*-')
xlabel('T(K)');
ylabel('Setpoint - Actual Temp (K)');

figure(2);
loglog(avgCalibratedTemps,calibratedTempsStDev./avgCalibratedTemps);
xlabel('T(K)');
ylabel('fractional st dev variation in temperature (unitless)');

figure(3);
loglog(avgCalibratedTemps,calibratedTempsErrorOfMean);
xlabel('T(K)');
ylabel('standard error of mean T (K)');

figure(4);
loglog(avgCalibratedTemps,voltageStDev./avgVoltage);
xlabel('T(K)');
ylabel('fractional st dev variation in voltage (unitless)');


figure(5);
loglog(avgCalibratedTemps,voltageStDev/sqrt(4*400));
xlabel('T(K)');
ylabel('fractional standard error of mean voltage (unitless)');



ls335=deviceDrivers.Lakeshore335();
ls335.connect('12')

for i=1:80
    [val(i), temp(i)] = ls335.get_curve_val(2, i);
end
ls335.disconnect();

figure(6);
plot(temp,val,avgCalibratedTemps,avgVoltage);
xlabel('T(K)');
ylabel('standard and measured voltages');


figure(7);
plot(temp,val-interp1(avgCalibratedTemps,avgVoltage,temp),avgCalibratedTemps,voltageStDev/sqrt(4*400))
xlabel('T(K)');
ylabel('blue = difference between measured and std voltage, red = std error of mean voltage');