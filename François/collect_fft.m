ats850 = deviceDrivers.ATS850Driver(1,1);
ats850.configureDefault(.02,.02);
%ats850.setAcquisitionSize(2^10, 30);
%[a,~]=ats850.acquireDataSamples('A');

[freq, dataAPwr, ~]=ats850.acquireAvgSpectralVoltagePower(2^10,500,18000,1,'A');
h=semilogy(freq, dataAPwr);
ylim([1e-11 1e-7]);
grid on;

while(true)
    [~, dataAPwr, ~]=ats850.acquireAvgSpectralVoltagePower(2^10,500,18000,1,'A');
    h.YData=dataAPwr;
    %pause(0.5);
    drawnow
end