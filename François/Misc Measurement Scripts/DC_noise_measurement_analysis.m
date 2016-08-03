%load data;

%first index = temp
%second index = gate
%third index = current (through the sample)

[tempLength, gateLength, currentLength]=size(data.temp);

%plot data for a given gateIndex
gateIndex=1;
myTemp=squeeze(data.temp(:,1,1));
myVoltage=squeeze(data.sourceVoltage(1,1,:));
powerPerTemp=zeros(tempLength,currentLength);
powerErrPerTemp=zeros(tempLength,currentLength);

for(q=1:currentLength)
    powerPerTemp(:,q)=data.power(:,gateIndex,q);
    powerErrPerTemp(:,q)=data.powerErr(:,gateIndex,q);
end

%powerPerTemp(1,:)=powerPerTemp(1,:)-1.5e-8;
%powerPerTemp(7,:)=powerPerTemp(7,:)+4.8e-8;
plot(myVoltage*15059/(15059+10530000),powerPerTemp(1:8,:)/15059,'-o');

%plot(myTemp,powerPerTemp(:,1)/15059,'*')

%shadedErrorBar(myVoltage,powerPerTemp(1:5,:),powerErrPerTemp(1:5,:))

%plot(vector, matrix(a,b)) plots the vectors matrix(a,:) vs vector for all a
