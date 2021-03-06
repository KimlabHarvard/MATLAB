%before running this, load the matlab struct file with calData

tempFitRange=[min(calData.tempList) max(calData.tempList)];
tempFitIndices=1:3;

%raw data
figure(1);
clf;
subplot(2,2,1);
%plot(calData.tempList,calData.johnsonNoise(:,:),'Color',[.85 .85 .85])
hold on; grid on;
plot(calData.tempList,calData.johnsonNoise(:,1:end)','.-')
xlabel('T(K)');
ylabel('Johnson Noise P_P0 (W)');
title('graphene 8/21/16 all gates');
hold off;

subplot(2,2,3);
surf(calData.tempList,calData.gateVoltageList,calData.johnsonNoise(:,:)','EdgeAlpha',0)
xlabel('T(K)');
ylabel('gate voltage (V)');
colormap('hot');
colorbar();
view([0 0 1])
shading interp;
title('Johnson Noise Power (W)');

subplot(2,2,2);
grid on;
plot(calData.gateVoltageList,calData.resistance);
xlabel('gate voltage (V)');
ylabel('resistance (Ohms)');
title('graphene 8/13/16 all gates');

subplot(2,2,4);
surf(calData.tempList,calData.gateVoltageList,calData.resistance','EdgeAlpha',0);
xlabel('T(K)');
ylabel('gate voltage (V)');
colormap('hot');
colorbar();
view([0 0 1]);
shading interp;
title('Resistance (Ohms)');

figure(2) %raw data, P vs R for all T
clf; hold on; grid on;
%for all temps, plot johnson noise power vs resistance
legendList=cell(length(tempFitIndices),1);
ii=1;
for(i=tempFitIndices)
    plot(calData.resistance(i,:),calData.johnsonNoise(i,:),'.-')
    legendList(ii)={sprintf('%g K',calData.tempList(i))};
    ii=ii+1;
end
title('Graphene Johnson Noise Calibration, P_P vs. R for gate sweeps');
xlabel('Resistance (Ohms)');
ylabel('Johnson Noise (W)');
legend(legendList);

figure(3); %fits to raw data, P vs R for all T
clf; hold on; grid on;
%for all temps, fit a cubic polynomial to johnson noise power vs resistance
legendList=cell(length(tempFitIndices),1);
ii=1;
%for(i=1:10:length(tempFitIndices))
for(i=tempFitIndices)
    plot(calData.resistance(i,:),calData.johnsonNoise(i,:),'o-','MarkerSize',3)
    legendList(ii)={sprintf('%g K',calData.tempList(i))};
    ii=ii+1;
end
xl=xlim;
xfine21=linspace(xl(1),xl(2),5000);
rctr=2000;
clear myPolyFit
ii=1;
%for(i=1:10:length(tempFitIndices))
for(i=tempFitIndices)
    %myX21=resistance(i,:);
    %myY21=johnsonNoise(i,:);
    %fitObject=fit(myX21',myY21','poly3');
    %plot(fitObject);
    myPolyFit(ii,:)=polyfit(calData.resistance(i,:)-rctr,calData.johnsonNoise(i,:),2);
    yeval=polyval(myPolyFit(ii,:),xfine21-rctr);
    plot(xfine21,yeval,'Color','Red'); 
    ii=ii+1;
end
title('Graphene Johnson Noise Calibration, cubic fits to P_P vs. R for gate sweeps');
xlabel('Resistance (Ohms)');
ylabel('Johnson Noise (W)');
legend(legendList);



% figure(2);
% for p=1:length(tempList)-1
%     T_derivative(p)=(tempList(p)+tempList(p+1))/2;
%     resistanceAvg(p,:)=(resistance(p,:)+resistance(p+1,:))/2;
%     johnsonNoiseDerivative(p,:)=(johnsonNoise(p+1,:)-johnsonNoise(p,:))/(tempList(p+1)-tempList(p));
% end
% 
% for p=2:length(tempList)-1
%     for q=1:length(gateVoltageList)
%        f=fit(tempList(p-1:p+1)',johnsonNoise(p-1:p+1,q),'poly1');
%        johnsonNoiseDerivative2(p,q)=f.p1;
%     end
%     T_derivative2(p)=mean(tempList(p-1:p+1));
%     resistanceAvg2(p,:)=mean(resistance(p-1:p+1,:));
%end
% 
% subplot(2,2,1);
% plot(T_derivative,johnsonNoiseDerivative);
% xlabel('T(K)');
% ylabel('johnson noise derivative (W/K)');
% %ylim([-0.5e-10,2e-10]);
% grid on;
% title('moving 2-point linear fit slope to JN Calibration')
% 
% subplot(2,2,3);
% surf(T_derivative,gateVoltageList,johnsonNoiseDerivative','EdgeAlpha',0);
% colormap('hot');
% colorbar();
% view([0 0 1])
% shading interp;
% xlabel('T(K)');
% ylabel('gate voltage (V)');
% title('johnson noise derivative (W/K), moving 2-point');
% 
% subplot(2,2,2);
% hold on;
% sam=1;
% plot(resistanceAvg(sam,:),johnsonNoiseDerivative(sam,:))
% xlabel('R (ohms)')
% ylabel('gain, i.e. the slope dP_{P0}/dT (W/K)')
% title(sprintf('gain trace over the dirac peak sweeping V_g, at %g K, averaged over 2 temps',mean(tempList(sam:sam+1))));
% 
% subplot(2,2,4);
% hold on;
% sam=[1 2];
% plot(gateVoltageList,johnsonNoiseDerivative(sam,:));
% xlabel('gate voltage (V)');
% ylabel('noise derivative (W/K)');
% title(['johnson noise derivative (W/K), moving 2-point ' sprintf('at %g K',tempList(sam))]);

figure(4); %scatter plot raw data
trimmedJohnsonNoise=calData.johnsonNoise(tempFitIndices,:);
trimmedResistance=calData.resistance(tempFitIndices,:);
trimmedTemps=calData.tempList(tempFitIndices);
trimmedTempsMat=[];
for(p=1:length(calData.gateVoltageList))
    trimmedTempsMat(:,p)=trimmedTemps;
end
scatter3(trimmedTempsMat(:),trimmedResistance(:),trimmedJohnsonNoise(:));
xlabel('T(K)');
ylabel('R(Ohms)');
zlabel('Noise Power (W)');
title('Raw calibration data, 3D scatter plot');

%data for gainByInterpolation
X=trimmedTempsMat(:);
Y=trimmedResistance(:);
Z=trimmedJohnsonNoise(:);


figure(5);
numPts=10000;
clear fittedJohnsonNoise fittedResistance fittedTempsMat
fittedJohnsonNoise=zeros(length(tempFitIndices),numPts);
fittedResistance=zeros(length(tempFitIndices),numPts);
for(p=1:length(tempFitIndices))
    rrr5=trimmedResistance(p,:);
    myMin=min(rrr5);
    myMax=max(rrr5);
    rlinspace=linspace(myMin,myMax,numPts);
    fittedResistance(p,:)=rlinspace';
    fittedJohnsonNoise(p,:)=polyval(myPolyFit(p,:),rlinspace-rctr);
end
for(p=1:numPts)
    fittedTempsMat(:,p)=trimmedTemps;
end
scatter3(fittedTempsMat(:),fittedResistance(:),fittedJohnsonNoise(:),'.');
X2=fittedTempsMat(:);
Y=fittedResistance(:);
Z=fittedJohnsonNoise(:);


% figure(4)
% title(sprintf('gain trace over the dirac peak sweeping V_g, at %g K, averaged over 3 temps',sam));
% for(sam=2:17)
%     subplot(2,3,sam-1)
%     plot(resistanceAvg(sam,:),johnsonNoiseDerivative(sam,:),'.-')
%     xlabel('R (ohms)')
%     ylabel('gain, i.e. the slope dP_{P0}/dT (W/K)')
%     title(sprintf('%g K',T_derivative2(sam)));    
% end

    

