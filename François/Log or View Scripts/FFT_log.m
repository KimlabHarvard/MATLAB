ats850 = deviceDrivers.ATS850Driver(1,1);
ats850.configureDefault();
range=0.04;
ats850.configureChannel('A','AC',range,50);
ats850.configureChannel('B','DC',range,1000000);
ats850.setTriggerTimeout(1);
resistor=10530000;

%ats850.setAcquisitionSize(2^10, 30);
%[a,~]=ats850.acquireDataSamples('A');

lockin=deviceDrivers.SRS830();
lockin.connect('1');

lockin.sineAmp=1;
leadResistance=40;

fftMask=[0 1.627e7; 1.807e7 3e7];

UniqueName='Graphene DC double ended measurement noise and resistance log at 105K and 0 gate voltage and 100 nA_rms';
    %UniqueName = input('Enter uniquie file identifier: ','s');
    start_dir = 'C:\Users\Artem\My Documents\Data\FFT Logs\';
    StartTime = clock;
    FileName = strcat('FFTlog_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');

ats850.setSizeSpectralVoltagePower(2^10,255);
[freq, dataAPwr, ~,abab,~]=ats850.acquireAvgSpectralVoltagePower('A');
[noiseArray(1),~,aDataForHist,~]=ats850.acquireTotalAvgVoltagePowerWithSpectralMask(fftMask, fftMask, 'A');
        figure(1992);
        hist(aDataForHist/range*127.5+127.5,(1:256));
        xlabel('bit bins');
        ylabel('counts');
        drawnow;   
    runningAvgLength=2000;
    pause(5);
    decayFactor=exp(-1/runningAvgLength);
    samuel=1-decayFactor;
runningAvg=dataAPwr;
h=loglog(freq, dataAPwr,'o-');
%h=plot(1:1024,abab(1:1024));
%hist(abab);
 ylim([1e-14 1e-13]);
 %xlim([10000 1e8]);
 xlim([15000000,23000000]);
 xlabel('f(Hz)');
 ylabel('power (V^2/Hz)');
 grid on;
 startTime=clock;
 data=struct('time',0,'spectrum',0,'resistance',0);
 
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
        topVoltage=lockin.sineAmp;
        bottomVoltage=lockin.R;
        p=p+1;
        data.resistance(p)=resistor*bottomVoltage/(topVoltage-bottomVoltage)-leadResistance;
        data.time(p)=etime(clock,startTime);
        data.spectrum(p,1:length(freq))=runningAvg;
        save(fullfile(start_dir, FileName),'data');
    end
    %toc
end

