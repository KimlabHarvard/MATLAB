ats850 = deviceDrivers.ATS850Driver(1,1);
ats850.configureDefault(.02,.02);
ats850.setAcquisitionSize(2^10, 30);
[a,~]=ats850.acquireDataSamples('A');
plot(1:length(a),a(1,:));
% [freq, dataAPwr, ~]=ats850.acquireAvgSpectralVoltagePower(2^10,100,18000,1,'A');
% h=semilogy(freq, dataAPwr);
% 
% while(true)
%     [~, dataAPwr, ~]=ats850.acquireAvgSpectralVoltagePower(2^10,100,18000,1,'A');
%     h.YData=dataAPwr;
%     pause(0.5);
% end