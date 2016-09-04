[biasVoltageLength, ~]=size(squeeze(data.highBiasVoltage(1,1,:)));
[~, gateVoltageLength]=size(data.johnsonNoise);

%temp index
i=1;

biasVoltage(1)=0;
biasVoltage(2:2:biasVoltageLength*2+1)=squeeze(data.lowBiasVoltage(i,1,:));
biasVoltage(3:2:biasVoltageLength*2+2)=squeeze(data.highBiasVoltage(i,1,:));

noisePower(:,1)=data.johnsonNoise(i,:);
noisePower(:,2:2:biasVoltageLength*2+1)=squeeze(data.noisePowerLow(i,:,:));
noisePower(:,3:2:biasVoltageLength*2+2)=squeeze(data.noisePowerHigh(i,:,:));

biasVoltage2=squeeze(data.midBiasVoltage(i,1,:));
noisePower2=squeeze(data.noiseDerivative(i,:,:));

figure(1);
hold on; grid off; %grid on;
plot(biasVoltage,noisePower(:,:)','.-','Color',[.75 .75 .75])
xlabel('bias voltage (V)')
ylabel('noise power (W)');
title(sprintf('Graphene 8/8/16 at %g K',data.temp(i,1)));

plot(biasVoltage,noisePower(1:3:end,:)','.-','LineWidth',1)
xlabel('bias voltage (V)')
ylabel('noise power (W)');
title(sprintf('Graphene 8/8/16 at %g K',data.temp(i,1)));

figure(2);
hold on; grid off; %grid on;
plot(biasVoltage2,noisePower2(:,:)','.-','Color',[.75 .75 .75])
xlabel('bias voltage (V)')
ylabel('noise power derivative (W/V)');
title(sprintf('Graphene 8/8/16 at %g K',data.temp(i,1)));

plot(biasVoltage2,noisePower2(1:3:end,:)','.-','LineWidth',1)
xlabel('bias voltage (V)')
ylabel('noise power derivative (W/V)');
title(sprintf('Graphene 8/8/16 at %g K',data.temp(i,1)));