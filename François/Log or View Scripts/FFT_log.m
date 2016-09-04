ats850 = deviceDrivers.ATS850Driver(1,1);
ats850.configureDefault();
range=0.2;
ats850.configureChannel('A','AC',range,50);
ats850.configureChannel('B','DC',range,1000000);
ats850.setTriggerTimeout(1);
%ats850.setAcquisitionSize(2^10, 30);
%[a,~]=ats850.acquireDataSamples('A');

fftMask=[0 1.627e7; 1.807e7 3e7];

UniqueName='Al Tunnel Junction DC double ended measurement noise Log 0 amps';
    %UniqueName = input('Enter uniquie file identifier: ','s');
    start_dir = 'C:\Users\Artem\My Documents\Data\AL Tunnel Junction\';
    StartTime = clock;
    FileName = strcat('Tlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

ats850.setSizeSpectralVoltagePower(2^10,255);
[freq, dataAPwr, ~,abab,~]=ats850.acquireAvgSpectralVoltagePower('A');
[noiseArray(1),~,aDataForHist,~]=ats850.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');
        figure(1992);
        hist(aDataForHist/range*127.5+127.5,(1:256));
        xlabel('bit bins');
        ylabel('counts');
        drawnow;   
    runningAvgLength=500;
    pause(5);
    decayFactor=exp(-1/runningAvgLength);
    samuel=1-decayFactor;
runningAvg=dataAPwr;
h=loglog(freq, dataAPwr,'o-');
%h=plot(1:1024,abab(1:1024));
%hist(abab);
 ylim([1e-13 1e-12]);
 %xlim([10000 1e8]);
 xlim([16000000,18200000]);
 xlabel('f(Hz)');
 ylabel('power (V^2/Hz)');
 grid on;
 startTime=clock;
 data=struct('time',0,'spectrum',0);
 
 for(jj=1:2000)
    [~, dataAPwr, ~, abab,~]=ats850.acquireAvgSpectralVoltagePower('A');
    runningAvg=runningAvg*decayFactor+samuel*dataAPwr;
    set(h,'XData',freq,'YData',runningAvg);
    drawnow;
    drawnow;
 end
 
 j=1;
 p=0;

while(true)
    %tic
    [~, dataAPwr, ~, abab,~]=ats850.acquireAvgSpectralVoltagePower('A');
    runningAvg=runningAvg*decayFactor+samuel*dataAPwr;
    set(h,'XData',freq,'YData',runningAvg);
    drawnow;
    j=j+1;
    drawnow;
    if(rem(j,500)==0)
        p=p+1
        data.time(p)=etime(clock,startTime);
        data.spectrum(p,1:length(freq))=runningAvg;
        save(fullfile(start_dir, FileName),'data');
    end
    %toc
end

