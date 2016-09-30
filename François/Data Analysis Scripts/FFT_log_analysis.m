fftData=data;
movingAvgLength=1;
numSamples=1024;
samplingFreq=50000000;
freq = 0:samplingFreq/numSamples:samplingFreq/2;

[s1, s2]=size(data.spectrum);

clf;
figure(1);
plot(data.time/3600,tsmovavg(data.spectrum(:,370:400),'s',movingAvgLength,1))

figure(2);
%plot(freq(20:end),data.spectrum(4700,20:end),freq(20:end),data.spectrum(5000,20:end));
plot(freq(20:end),data.spectrum(4700,20:end));