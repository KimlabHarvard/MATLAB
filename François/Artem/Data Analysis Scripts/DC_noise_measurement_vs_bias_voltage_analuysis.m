%load 

tempIndex=1;
fanoFitStart=3; %the value of eV/kT where to begin fitting for the fano factor
fanoFitEnd=40; %the value of eV/kT where to end fitting for the fano factor

fanoData=data;
%data=fanoData;

k_B=1.38064852e-23;
e=1.60217662e-19;

%find the index of zero bias voltage
theZero=1e-8;
theIndex=-1;
for(i=1:length(fanoData.biasVoltageList))
    if(abs(fanoData.biasVoltageList(i))<theZero)
        theIndex=i;
        break;
    end
end



%find the index of zero gate voltage
theZero2=1e-15;
for(i=1:length(fanoData.gateVoltageList))
    if(abs(fanoData.gateVoltageList(i))<theZero2)
        fanoData.gateVoltageList(i)=0;
        break;
    end
end


figure(1);
subplot(2,2,1);
hold on;

% biasVoltage=zeros(65,19)/0;
% resistance=zeros(65,19)/0;
% power=zeros(65,19)/0;

%combine the data!!
% for(p=1:47)
%     biasVoltage(p,:)=squeeze(data12.biasVoltage(tempIndex,p,:));
%     resistance(p,:)=squeeze(data12.resistance(tempIndex,p,:));
%     power(p,:)=squeeze(data12.power(tempIndex,p,:));
% end
% for(p=48:65)
%     biasVoltage(p,:)= squeeze(data11.biasVoltage(1,p-47,:));
%     resistance(p,:)=squeeze(data11.resistance(1,p-47,:));
%     power(p,:)=squeeze(data11.power(1,p-47,:));
% end

for(j=1:length(fanoData.gateVoltageList)-0)
    mypwr=fanoData.power(tempIndex,j,:)-fanoData.power(tempIndex,j,theIndex);
    plot(squeeze(fanoData.biasVoltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),squeeze(mypwr),'.-');
end
title(sprintf('graphene %gK',fanoData.tempList(tempIndex)));
xlim([min(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex))) max(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)))]*1.05);
xlabel('eV_{DS}/(kT)');
ylabel('noise power offset(W)');
grid on;

figure(999);
clf;
hold on;
%65 gate voltages

% for(p=n:-1:1)
%     plot(xi2(p,:),zi2(p,:),'o-','MarkerSize',4);
%     
% end
clear legendList;
colorIndexList=[3:10:length(fanoData.gateVoltageList)];
legendList=cell(length(colorIndexList),1);
p=1;
for(j=1:length(fanoData.gateVoltageList)-0)
    if(~ismember(j,colorIndexList))
        mypwr=fanoData.power(tempIndex,j,:);
        h=plot(squeeze(fanoData.biasVoltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),squeeze(mypwr)*1e9,'-','Color','k');
        h.Color(4) = 0.5;
        set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    end;
end
for(j=colorIndexList)
    mypwr=fanoData.power(tempIndex,j,:);
    plot(squeeze(fanoData.biasVoltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),squeeze(mypwr)*1e9,'-',...
            'LineWidth',2,...
            'MarkerSize',15,...
            'DisplayName',sprintf('%g V',fanoData.gateVoltageList(j)));
end
title('Grahpene 3K Shot Noise Raw Data')
xlim([min(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex))) max(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)))]*1.05);
xlabel('eV_{DS}/(kT)');
ylabel('Noise Power (nW)');
xlim([-150 150]);
l = legend('show','Location','best');


figure(1);

subplot(2,2,2);
hold on;

for(j=1:length(fanoData.gateVoltageList)-0)
    plot(squeeze(fanoData.biasVoltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),squeeze(fanoData.resistance(tempIndex,j,:)),'.-');
end
title(sprintf('graphene %gK',fanoData.tempList(tempIndex)));
xlim([min(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex))) max(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)))]*1.05);
xlabel('eV_{DS}/(kT)');
ylabel('resistance (R)');
grid on

subplot(2,2,3);
mypwr=setZerosToNaN(fanoData.power(tempIndex,:,:));
surf(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)),fanoData.gateVoltageList,squeeze(mypwr),'EdgeAlpha',0);
xlim([min(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex))) max(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)))]*1.05);
colormap('hot');
view([0 0 1]);
shading interp;
colorbar();
title(sprintf('graphene noise power (W) at %gK',fanoData.tempList(tempIndex)));
xlabel('eV_{DS}/(kT)');
ylabel('gate votlage V_g (V)');

subplot(2,2,4);
surf(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)),fanoData.gateVoltageList,squeeze(fanoData.resistance(tempIndex,:,:)),'EdgeAlpha',0);
xlim([min(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex))) max(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)))]*1.05);
colormap('hot');
view([0 0 1]);
shading interp;
colorbar();
title(sprintf('graphene resistance (R) at %gK',fanoData.tempList(tempIndex)));
xlabel('eV_{DS}/(kT)');
ylabel('gate votlage V_g (V)');


%calculate differential resistance at the midpoints by the two-point derivative
%R_diff=dV/dI=d/dI (R*I) = dR/dI*I+R 
figure(2);
clf;
%subplot(2,2,1);
current=fanoData.biasVoltage./fanoData.resistance;
voltage=fanoData.biasVoltage;
current2=(current(tempIndex,:,1:end-1)+current(tempIndex,:,2:end))/2; %get the midpoints
voltage2=(fanoData.biasVoltage(tempIndex,:,1:end-1)+fanoData.biasVoltage(tempIndex,:,2:end))/2; %get the midpoints
differentialResistance=(voltage(tempIndex,:,2:end)-voltage(tempIndex,:,1:end-1))./(current(tempIndex,:,2:end)-current(tempIndex,:,1:end-1));
grid on;
hold on;
for(j=1:length(fanoData.gateVoltageList))
    %plot(squeeze(voltage2(1,j,:)),tsmovavg(squeeze(differentialResistance(1,j,:)),'s',1,1));
    plot(squeeze(voltage2(1,j,:))*e/(k_B*fanoData.tempList(tempIndex)),smooth(squeeze(differentialResistance(1,j,:)),1),'.-');
end

ylabel('two-point differential Resistance (\Omega)');
title(sprintf('graphene %gK',fanoData.tempList(tempIndex)));
xlim([min(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex))) max(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)))]*1.05);

%calculate the differential resistance at the same original bias voltage points
%for the V=0 point, use the original
%for the endpoints, use the two-point derivative of the endpoint and the adjacent point
%for all other points, compute it using the three-point derivative (i.e. linear fit to three points and take the slope)
figure(3);
clf;
clear differentialResistance2;
for(j=1:length(fanoData.gateVoltageList)-0)
    %do the two endpoints first
    differentialResistance2(j,1)=(voltage(tempIndex,j,2)-voltage(tempIndex,j,1))/(current(tempIndex,j,2)-current(tempIndex,j,1));
    asdf=length(fanoData.biasVoltageList);
    differentialResistance2(j,asdf)=(voltage(tempIndex,j,asdf)-voltage(tempIndex,j,asdf-1))/(current(tempIndex,j,asdf)-current(tempIndex,j,asdf-1));
    
    %now do the bulk, linear fit to three points and take the slope
    for(k=2:length(fanoData.biasVoltageList)-1)
        xList=squeeze(current(tempIndex,j,k-1:k+1));
        yList=squeeze(voltage(tempIndex,j,k-1:k+1));
        myfit=fit(xList,yList,'poly1');
        differentialResistance2(j,k)=myfit.p1;
        
        %at zero bias use the plain resistance instead of calculating a differential resistance
        if(k==theIndex)
            differentialResistance2(j,k)=fanoData.resistance(tempIndex,j,k);
        end
    end
end
grid on;
hold on;
for(j=1:length(fanoData.gateVoltageList)-0)
    %plot(squeeze(voltage2(1,j,:)),tsmovavg(squeeze(differentialResistance(1,j,:)),'s',1,1));
    plot(squeeze(voltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),smooth(differentialResistance2(j,:),1),'.-');
end
xlabel('eV_{DS}/(kT)');
ylabel('three-point differential Resistance (\Omega)');
title(sprintf('graphene %gK',fanoData.tempList(tempIndex)));
xlim([min(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex))) max(fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)))]*1.05);

%at this point, make sure the gain data is loaded
%we will need the gain and the noise temperature as a function of resistance
%this will then be interpolated
%this should be in the stucture gainData, with variables gain, noiseTemperature, resistance
%convert the noise power from watts to Kelvins using the differential resistance and then subtract off the noise temperature
%plot the noise in units of Kelvin vs ev/kT
noisePower=[];
for(j=1:length(fanoData.gateVoltageList)-0)
    for(k=1:length(fanoData.biasVoltageList))
        res=differentialResistance2(j,k);
        gain=interp1(gainData.resistance,gainData.gain,res);
        noiseTemp=interp1(gainData.resistance,gainData.noiseTemperature,res);
        noisePower(j,k)=fanoData.power(tempIndex,j,k)/gain-noiseTemp;
        if(noisePower(j,k)<-60)
            res
            noiseTemp
        end
    end
end

figure(4);
clf;
figure(21);
clf;
subplot(2,2,1);
for(j=1:length(fanoData.gateVoltageList)-0)
%for(j=30:40);
    %plot(squeeze(voltage2(1,j,:)),tsmovavg(squeeze(differentialResistance(1,j,:)),'s',1,1));
    semilogy(squeeze(voltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),smooth(noisePower(j,:),1),'.-');
    hold on;
end
xlabel('eV_{DS}/(kT)');
ylabel('noise power (K)');
grid on;
title(sprintf('noise power vs. bias voltage, corrected by variable gain and noise temperature, at %g K',fanoData.tempList(tempIndex)));
figure(5);
clf;
surf(fanoData.gateVoltageList(1:end-0),fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)),noisePower','EdgeAlpha',0)
ylabel('V_B (V)');
xlabel('gate voltage (V)');
colormap('hot');
colorbar();
view([0 0 1])
shading interp;
title('Noise Power (K)');
figure(21);
subplot(2,2,2);
for(j=1:length(fanoData.gateVoltageList)-0)
%for(j=30:40);
    %plot(squeeze(voltage2(1,j,:)),tsmovavg(squeeze(differentialResistance(1,j,:)),'s',1,1));
    plot(squeeze(voltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),smooth(noisePower(j,:),1),'.-');
    hold on;
end
xlabel('eV_{DS}/(kT)');
ylabel('noise power (K)');
grid on;
subplot(2,2,4);
figure(1000);
clf;
hold on;
for(j=1:length(fanoData.gateVoltageList)-0)
    if(~ismember(j,colorIndexList))
        h=plot(squeeze(voltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),smooth(noisePower(j,:),1),'-','Color','k');
        h.Color(4) = 0.5;
        set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');  
    end
end
for(j=colorIndexList)
    plot(squeeze(voltage(tempIndex,j,:))*e/(k_B*fanoData.tempList(tempIndex)),smooth(noisePower(j,:),1),'-',...
            'LineWidth',2,...
            'MarkerSize',15,...
            'DisplayName',sprintf('%g V',fanoData.gateVoltageList(j)));
    hold on;
end
xlabel('eV_{DS}/(kT)');
ylabel('Noise Power (K)');
title(sprintf('noise power vs. bias voltage, corrected by variable gain and noise temperature, at %g K',fanoData.tempList(tempIndex)));
title('Grahpene 3K Shot Noise')
l = legend('show','Location','best');
xlim([-150 150]);
figure(5);
clf;
surf(fanoData.gateVoltageList(1:end-0),fanoData.biasVoltageList*e/(k_B*fanoData.tempList(tempIndex)),noisePower','EdgeAlpha',0)
ylabel('V_B (V)');
xlabel('gate voltage (V)');
colormap('hot');
colorbar();
view([0 0 1])
shading interp;
title('Noise Power (K)');

figure(21)
%now we can attempt to linear fit data to get a fano factor
%we select the positive and negative bias regimes, above the minimal bias voltage specified above
vmin=fanoFitStart*k_B*fanoData.tempList(tempIndex)/e;
vmax=fanoFitEnd*k_B*fanoData.tempList(tempIndex)/e;
fanoFactorNegative=[];
fanoFactorPositive=[];
fanoFactorNegativeErr=[];
fanoFactorPositiveErr=[];
ci=[];
for(j=1:length(fanoData.gateVoltageList)-0)
    negativeBiasVoltages=[];
    positiveBiasVoltages=[];
    negativeBiasNoisePower=[];
    positiveBiasNoisePower=[];
    for(k=1:length(fanoData.biasVoltageList))
        %negative bias
        if(fanoData.biasVoltage(tempIndex,j,k)>-vmax && fanoData.biasVoltage(tempIndex,j,k)<-vmin && ~isnan(noisePower(j,k)))
            negativeBiasVoltages=[negativeBiasVoltages fanoData.biasVoltage(tempIndex,j,k)];
            negativeBiasNoisePower=[negativeBiasNoisePower noisePower(j,k)];
        end
        
        %positive bias
        if(fanoData.biasVoltage(tempIndex,j,k)>vmin && fanoData.biasVoltage(tempIndex,j,k)<vmax && ~isnan(noisePower(j,k)))
            positiveBiasVoltages=[positiveBiasVoltages fanoData.biasVoltage(tempIndex,j,k)];
            positiveBiasNoisePower=[positiveBiasNoisePower noisePower(j,k)];
        end
    end
    try
        myFitNegative=fit(negativeBiasVoltages',negativeBiasNoisePower','poly1');
        fanoFactorNegative(j)=myFitNegative.p1*4*k_B/(2*e);
        ci=confint(myFitNegative);
        fanoFactorNegativeErr(j)=(ci(2,1)-ci(1,1))*4*k_B/(2*e)/4; % divide by 4 to get 1-sigma
        
        myFitPositive=fit(positiveBiasVoltages',positiveBiasNoisePower','poly1');
        fanoFactorPositive(j)=myFitPositive.p1*4*k_B/(2*e);
        ci=confint(myFitPositive);
        fanoFactorPositiveErr(j)=(ci(2,1)-ci(1,1))*4*k_B/(2*e)/4; % divide by 4 to get 1-sigma
    catch
        %j
        %negativeBiasVoltages
        %negativeBiasNoisePower
        %positiveBiasVoltages
        %positiveBiasNoisePower
        %myFitNegative
        
        %negativeBiasVoltages
        %negativeBiasNoisePower
        
        fanoFactorNegative(j)=0;
        fanoFactorPositive(j)=0;
        fanoFactorNegativeErr(j)=0;
        fanoFactorPositiveErr(j)=0;
    end
end
figure(6);
clf;
hold on;
%plot(fanoData.gateVoltageList(1:end-0),abs(fanoFactorNegative)*0.5+fanoFactorPositive*0.5);%,'.',fanoData.gateVoltageList(1:end-0),fanoFactorPositive,'.');
shadedErrorBar(fanoData.gateVoltageList(1:end-0),abs(fanoFactorNegative)*0.5+0.5*fanoFactorPositive,0.5*sqrt(fanoFactorNegativeErr.^2+fanoFactorPositiveErr.^2),{'-or','markerfacecolor',[1,0,0]},1);
%errorbar(fanoData.gateVoltageList(1:end-0),abs(fanoFactorPositive),fanoFactorPositiveErr);
xlabel('V_g (V)');
ylabel('Fano Factor');
title(sprintf('Fano factor graphene at %g K, linear fit to %g < ev/kT < %g',fanoData.tempList(tempIndex),fanoFitStart,fanoFitEnd));
grid on;
legend('negative bias', 'positive bias');
xx99=-10:0.1:10;
plot(xx99,xx99*0+1/3,'--','LineWidth',2,'Color','k')
xlim([-.6 -.2])