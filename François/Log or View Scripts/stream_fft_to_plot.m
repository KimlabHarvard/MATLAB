ats850 = deviceDrivers.ATS850Driver(1,1);
ats850.configureDefault();
ats850.configureChannel('A','AC',.04,50);
ats850.configureChannel('B','DC',.4,1000000);
ats850.setTriggerTimeout(1);
%ats850.setAcquisitionSize(2^10, 30);
%[a,~]=ats850.acquireDataSamples('A');

ats850.setSizeSpectralVoltagePower(2^10,255);
[freq, dataAPwr, ~,abab,~]=ats850.acquireAvgSpectralVoltagePower('A');

    runningAvgLength=500;
    decayFactor=exp(-1/runningAvgLength);
    samuel=1-decayFactor;
runningAvg=dataAPwr;
h=loglog(freq, dataAPwr,'o-');
%h=plot(1:1024,abab(1:1024));
%hist(abab);
 ylim([1e-15 1e-13]);
 %xlim([10000 1e8]);
 xlim([16000000,18200000]);
 xlabel('f(Hz)');
 ylabel('power (V^2/Hz)');
 grid on;

j=0;
while(true)
    %tic
    [~, dataAPwr, ~, abab,~]=ats850.acquireAvgSpectralVoltagePower('A');
    runningAvg=runningAvg*decayFactor+samuel*dataAPwr;
    %drawnow;
    %[x,y]=ats850.acquireVoltSamples('A'+'B');
    %dataAPwr
    %abab
    %figure(22);
    %loglog(dataAPwr);
    set(h,'XData',freq,'YData',runningAvg);
    %set(h,'XData',1:1024,'YData',abab(1:1024));
    %figure(13)
    %j=j+1
    %hist(abab);
    drawnow;
    
    %toc
end
