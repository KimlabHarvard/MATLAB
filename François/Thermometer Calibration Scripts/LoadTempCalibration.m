%written by Artem Talanov 06/10/2016
%loads calibration data from file into Lakeshore LS335

%load the calibration data 
%load C:\GitHub\MATLAB\X108541.dat;

curve=21;
%name='CX_1030_AA';
%serialNumber='X108541';
serialNumber='000';
name='cal_diode';
format=2; % 1 = mV/K, 2 = V/K,3 = Ohm/K, 4 = log Ohm/K
limitValue=320;
coefficient=1; %1 or 0 doesnt matter

%extract temps and resistances from calibation data
%temps=X108541(:,1);
%resistances=X108541(:,2);
calibration=csvread('calibration.csv');
tempSetpoints=calibration(:,1);
avgCalibratedTemps=calibration(:,2);
calibratedTempsStDev=calibration(:,3);
calibratedTempsErrorOfMean=calibration(:,4);
avgVoltage=calibration(:,5);
voltageStDev=calibration(:,6);
voltageErrorOfMean=calibration(:,7);

%connect to lakeshore bridge
ls335 = deviceDrivers.Lakeshore335();
ls335.connect('12')

ls335.set_curve_header(curve, name, serialNumber, format, limitValue, coefficient)

%function set_curve_val(obj, curve, index, val, temp)
len=length(avgCalibratedTemps)
for i=1:len
      %ls335.set_curve_val(curve,i,log10(resistances(len-i+1)),temps(len-i+1));
      ls335.set_curve_val(curve,i,avgVoltage(len-i+1),avgCalibratedTemps(len-i+1));
end

ls335.disconnect()