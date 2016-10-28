%load 

tempIndex=2;

data=fanoData;

k_B=1.38064852e-23;
e=1.60217662e-19;

%find the index of zero bias voltage
theZero=1e-8;
theIndex=-1;
for(i=1:length(data.biasVoltageList))
    if(abs(data.biasVoltageList(i))<theZero)
        theIndex=i;
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

for(j=1:length(data.gateVoltageList))
    mypwr=data.power(tempIndex,j,:)-data.power(tempIndex,j,theIndex);
    plot(squeeze(data.biasVoltage(tempIndex,j,:))*e/(k_B*data.tempList(tempIndex)),squeeze(mypwr),'.-');
end
title(sprintf('graphene %gK',data.tempList(tempIndex)));
xlim([min(data.biasVoltageList*e/(k_B*data.tempList(tempIndex))) max(data.biasVoltageList*e/(k_B*data.tempList(tempIndex)))]*1.05);
xlabel('eV_B/(kT) (dimensionless)');
ylabel('noise power offset(W)');
grid on;


subplot(2,2,2);
hold on;

for(j=1:length(data.gateVoltageList))
    plot(squeeze(data.biasVoltage(tempIndex,j,:))*e/(k_B*data.tempList(tempIndex)),squeeze(data.resistance(tempIndex,j,:)),'.-');
end
title(sprintf('graphene %gK',data.tempList(tempIndex)));
xlim([min(data.biasVoltageList*e/(k_B*data.tempList(tempIndex))) max(data.biasVoltageList*e/(k_B*data.tempList(tempIndex)))]*1.05);
xlabel('eV_B/(kT) (dimensionless)');
ylabel('resistance (R)');
grid on

subplot(2,2,3);
mypwr=setZerosToNaN(data.power(tempIndex,:,:));
surf(data.biasVoltageList*e/(k_B*data.tempList(tempIndex)),data.gateVoltageList,squeeze(mypwr),'EdgeAlpha',0);
xlim([min(data.biasVoltageList*e/(k_B*data.tempList(tempIndex))) max(data.biasVoltageList*e/(k_B*data.tempList(tempIndex)))]*1.05);
colormap('hot');
view([0 0 1]);
shading interp;
colorbar();
title(sprintf('graphene noise power (W) at %gK',data.tempList(tempIndex)));
xlabel('eV_B/(kT) (dimensionless)');
ylabel('gate votlage V_g (V)');

subplot(2,2,4);
surf(data.biasVoltageList*e/(k_B*data.tempList(tempIndex)),data.gateVoltageList,squeeze(data.resistance(tempIndex,:,:)),'EdgeAlpha',0);
xlim([min(data.biasVoltageList*e/(k_B*data.tempList(tempIndex))) max(data.biasVoltageList*e/(k_B*data.tempList(tempIndex)))]*1.05);
colormap('hot');
view([0 0 1]);
shading interp;
colorbar();
title(sprintf('graphene resistance (R) at %gK',data.tempList(tempIndex)));
xlabel('eV_B/(kT) (dimensionless)');
ylabel('gate votlage V_g (V)');


%calculate differential resistance
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
    plot(squeeze(voltage2(1,j,:))*e/(k_B*data.tempList(tempIndex)),smooth(squeeze(differentialResistance(1,j,:)),5),'.-');
end
xlabel('eV_B/(kT) (dimensionless)');
ylabel('averaged differential Resistance (Ohms)');
title(sprintf('graphene %gK',data.tempList(tempIndex)));
xlim([min(data.biasVoltageList*e/(k_B*data.tempList(tempIndex))) max(data.biasVoltageList*e/(k_B*data.tempList(tempIndex)))]*1.05);