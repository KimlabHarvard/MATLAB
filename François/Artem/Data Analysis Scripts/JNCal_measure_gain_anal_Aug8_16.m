%combine lots of files together
%clearvars;

%clf;
%clear all;
%close all;
%fclose all;

loadTheData=true;

%aug 8,9
indices=[1 2 3 0 0; 4 5 6 7 0; 8 9 10 11 0; 12 13 14 15 0; 16 17 18 19 0; 20 21 22 23 0; 24 25 26 27 0; 28 29 30 31 32; 33 34 35 36 0; 38 39 40 41 0; 42 43 44 45 46];
gateVoltageList=[-1:.05:-.65   -.6:.01:-.2 -.15:.05:.2 .3:.1:1];
tempList=[3 4 6 8 10 12 14 16 18 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100:10:200 220:10:300];

tempFitIndices=[8:19]; %8-19 is 16K to 65K
tempFitIndices=[1:19]; %1-19 is 3K to 65K
%tempFitIndices=[1:11]; %1-19 is 3K to 25K


%aug 10
%indices=[1 2 3 0 0; 4 5 6 7 0];
%gateVoltageList=[-1:.05:-.65   -.6:.01:-.2 -.15:.05:.2 .3:.1:1];
%tempList=[3 4 6 8 10 12 14];

%aug 12
%indices=[1 2 3 4 0; 5 6 7 0 0];
%tempList=[100 105 110 115 120 125 130];

%aug 13
%indices=[1 2 3 0 0; 4 0 0 0 0];
%tempList=[100 105 110 115];



if(loadTheData)
    [s1, s2]=size(indices);
    count=1;
    for(i=1:s1)

        myIndices=[];
        myIndices2=[];
        for j=1:s2
            if(indices(i,j)~=0)
                myIndices=[myIndices indices(i,j)];
                myIndices2=[myIndices2 count];
                count=count+1;
            end
        end

        load(['file' num2str(i) '.mat']);
        %data=calData;
        %indices(i,:)
        calData.temp((myIndices2),:)=data.temp(1:length(myIndices),:);
        calData.johnsonNoise((myIndices2),:)=data.johnsonNoise(1:length(myIndices),:);
        calData.johnsonNoiseErr((myIndices2),:)=data.johnsonNoiseErr(1:length(myIndices),:);
        calData.resistance((myIndices2),:)=data.resistance(1:length(myIndices),:);
        temp((myIndices2),:)=data.temp(1:length(myIndices),:);
        johnsonNoise((myIndices2),:)=data.johnsonNoise(1:length(myIndices),:);
        johnsonNoiseErr((myIndices2),:)=data.johnsonNoiseErr(1:length(myIndices),:);
        resistance((myIndices2),:)=data.resistance(1:length(myIndices),:);
        
    end
end
calData.tempList=tempList;

%manually shift the data to fix it
%aug 8,9
% johnsonNoise(20:end,:)=johnsonNoise(20:end,:)-.203e-8;
% johnsonNoise(20,:)=johnsonNoise(20,:)-.1e-8;
% 
% johnsonNoise(27:end,:)=johnsonNoise(27:end,:)-.01e-8;
% johnsonNoise(27,:)=johnsonNoise(27,:)+.08e-8;



%raw data
figure(1);
clf;
subplot(2,2,1);


figure(1001);
clf;
hold on;
for(j=1:length(gateVoltageList))
    h=plot(tempList(tempFitIndices),johnsonNoise(tempFitIndices,j),'-','Color','k');
    h.Color(4) = 0.5;
    set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
for(j=colorIndexList)
     h=plot(tempList(tempFitIndices),johnsonNoise(tempFitIndices,j),'-',...
            'LineWidth',2,...
            'MarkerSize',15,...
            'DisplayName',sprintf('%g V',fanoData.gateVoltageList(j)));
end
xlabel('T(K)');
ylabel('Johnson Noise Power (W)');
title('Graphene Raw Calibration Data');
l = legend('show','Location','best');
hold off;

figure(1)
subplot(2,2,3);
surf(tempList,gateVoltageList,johnsonNoise(:,:)','EdgeAlpha',0)
xlabel('T(K)');
ylabel('gate voltage (V)');
colormap('hot');
colorbar();
view([0 0 1])
shading interp;
title('Johnson Noise Power (W)');

subplot(2,2,2);
plot(gateVoltageList,resistance);
xlabel('gate voltage (V)');
ylabel('resistance (\Omega)');
title('graphene 8/13/16 all gates');

subplot(2,2,4);
surf(tempList,gateVoltageList,resistance','EdgeAlpha',0);
xlabel('T(K)');
ylabel('gate voltage (V)');
colormap('hot');
colorbar();
view([0 0 1]);
shading interp;
title('Resistance (\Omega)');

figure(2) %raw data, P vs R for all T
clf; hold on; grid on;
%for all temps, plot johnson noise power vs resistance
legendList=cell(length(tempFitIndices),1);
ii=1;
for(i=tempFitIndices)
    plot(resistance(i,:),johnsonNoise(i,:),'.-')
    legendList(ii)={sprintf('%g K',tempList(i))};
    ii=ii+1;
end
title('Graphene Johnson Noise Calibration, P_P vs. R for gate sweeps');
xlabel('Resistance (\Omega)');
ylabel('Johnson Noise (W)');
legend(legendList);

figure(3); %fits to raw data, P vs R for all T
clf; hold on; grid on;
%for all temps, fit a cubic polynomial to johnson noise power vs resistance
legendList=cell(length(tempFitIndices),1);
ii=1;
for(i=tempFitIndices)
    plot(resistance(i,:),johnsonNoise(i,:),'o-','MarkerSize',3)
    legendList(ii)={sprintf('%g K',tempList(i))};
    ii=ii+1;
end
xl=xlim;
xfine21=linspace(xl(1),xl(2),5000);
rctr=2000;
clear myPolyFit
ii=1;
for(i=tempFitIndices)
    %myX21=resistance(i,:);
    %myY21=johnsonNoise(i,:);
    %fitObject=fit(myX21',myY21','poly3');
    %plot(fitObject);
    myPolyFit(ii,:)=polyfit(resistance(i,:)-rctr,johnsonNoise(i,:),3);
    yeval=polyval(myPolyFit(ii,:),xfine21-rctr);
    plot(xfine21,yeval,'Color','Red'); 
    ii=ii+1;
end
title('Graphene Johnson Noise Calibration, cubic fits to P_P vs. R for gate sweeps');
xlabel('Resistance (\Omega)');
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
% xlabel('R (\Omega)')
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
trimmedJohnsonNoise=johnsonNoise(tempFitIndices,:);
trimmedResistance=resistance(tempFitIndices,:);
trimmedTemps=tempList(tempFitIndices);
trimmedTempsMat=[];
for(p=1:length(gateVoltageList))
    trimmedTempsMat(:,p)=trimmedTemps;
end
scatter3(trimmedTempsMat(:),trimmedResistance(:),trimmedJohnsonNoise(:));
xlabel('T(K)');
ylabel('R(\Omega)');
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
%     xlabel('R (\Omega)')
%     ylabel('gain, i.e. the slope dP_{P0}/dT (W/K)')
%     title(sprintf('%g K',T_derivative2(sam)));    
% end

    

