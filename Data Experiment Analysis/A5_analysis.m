startIndex=25;
endIndex=59;

temp=data.Tset(startIndex:endIndex);
tempFull=data.Tset;
resistance=data.R(startIndex:endIndex);
resistanceFull=data.R;
resistance=resistance';
noiseVoltage=data.VNdc(startIndex:endIndex);
noiseVoltage=noiseVoltage';
gamma=(resistance-50)./(resistance+50);;




G_=.0234;
Tn_=94+0*temp; %370
Ti_=25; %100
plot(temp,G_*((1-gamma.^2).*temp+gamma.^2*Ti_+Tn_),temp,noiseVoltage)

r=@(t) interp1(tempFull,resistanceFull,t);
g=@(t) (r(t)-50)./(r(t)+50);
powerFn=@(G, Tn, Ti, x)  G*((1-(g(x)).^2).*x+(g(x)).^2.*Ti+Tn);




%myFitType=fittype(powerFn,'dependent',{'n'},'independent',{'t'},'coefficients',{'G','Tn','Ti'});
%myFitOptions=fitoptions('Method','NonlinearLeastSquares','StartPoint',[5.86e-3,375,100]);
%myFit1=fit(temp,noiseVoltage,myFitType,myFitOptions);
myFit1=fit(temp',noiseVoltage',powerFn,'StartPoint',[.0237 87.8 34])


%
%resistance(1:15)=resistance(1:15)*.6;
%resistanceFull(1:15)=resistanceFull(1:15)*.6;

%resistance(1:8)=resistance(1:8)*.65;
%resistanceFull(1:8)=resistanceFull(1:8)*.65;

r=@(t) interp1(tempFull,resistanceFull,t);
g=@(t) (r(t)-50)./(r(t)+50);
powerFn=@(G, Tn, Ti, x)  G*((1-(g(x)).^2).*x+(g(x)).^2.*Ti+Tn);

plot(1:.1:300,powerFn(myFit1.G,myFit1.Tn,myFit1.Ti,1:.1:300),data.Tset,data.VNdc,'o',data.Tset(startIndex:endIndex),data.VNdc(startIndex:endIndex),'ko')

xlabel('T(K)')
ylabel('Johnson Noise (V)')
title('A5')



% myFitType=fittype('G*(1-((r-50)/(r+50))^2*4*t+((r-50)/(r+50))^2*Ti+Tn)','dependent',{'n'},'independent',{'t','r'},'coefficients',{'G','Tn','Ti'});
% myFitOptions=fitoptions('Method','NonlinearLeastSquares','StartPoint',[5.86e-3,375,100]);
% myFit1=fit([temp',resistance'],noiseVoltage,myFitType,myFitOptions);
% plot(myFit1)
% xlabel('T(K)');
% ylabel('R(Ohms)');
% zlabel('Johnson Noise (V)');
% myFit1.G
% myFit1.Tn
% myFit1.Ti