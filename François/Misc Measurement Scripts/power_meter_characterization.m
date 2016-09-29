%sweeps frequency and power in dBm to characterize the power meter

%14 dbm=1.12 vrms

freqList=[100]*10^6; %Hz
%freqList=50000000;
powerList_dBm=[-30:1:0]; %dBm
%voltList_rms=[0.001 .002 .003 .004 .005 .01:.01:1.1];
waitTime=1;

powerList=voltList_rms.*voltList_rms/50;
powerList=powerList_dBm;

offset=0.071631;
offset=0;

sg386 = deviceDrivers.SG382();
sg386.connect('27');

k24401A= deviceDrivers.Keysight34401A();
k24401A.connect('6');

clear volt;

for i=1:length(freqList)
    sg386.freq=freqList(i);
    for j=1:length(powerList)
        sg386.amp_N_dBm=powerList_dBm(j);
        %sg386.ampBNC_RMS=voltList_rms(j);
        pause(waitTime);
        powerList(j)
        volt(i,j)=k24401A.value+offset;
    end
end
semilogy(powerList,volt,'.');
legend('50 MHz')
xlabel('input power (dBm)');
ylabel('voltage output (V)');
grid on