lockin1=deviceDrivers.SRS830();
lockin1.connect('1');

lockin2=deviceDrivers.SRS830();
lockin2.connect('2');

vList1=[.004 .05 .1 .2 .5];
vList2=[.004 .006 .008 .01 .02 .03 .04 .05 .1 .2 .3 .4 .5];

outList=zeros(length(vList1),length(vList2))/0;

lockin1.bufferReset;
lockin2.bufferReset;

for i=1:length(vList1)
    lockin1.sineAmp=vList1(i);
    for j=1:length(vList2)
        lockin2.sineAmp=vList2(j);
        if j==1
             pause(6*lockin1.timeConstant);
        end
        pause(8*lockin1.timeConstant);
        outList(i,j)=lockin1.R;
        j
    end
    i
    figure(1);
    loglog(vList2,outList(i,:)-vList1(i),'.-');
    hold on;
    xlabel('V2 (V)')
    ylabel('Vout adjusted (V)')
    figure(2);
    plot(vList2,outList(i,:)-vList1(i),'.-');
    hold on;
    xlabel('V2 (V)')
    ylabel('Vout adjusted (V)')
end

figure(1);
legend('V1=.004','V1=.05', 'V1=.1', 'V1=.2', 'V1=.5');
figure(2);
legend('V1=.004','V1=.05', 'V1=.1', 'V1=.2', 'V1=.5');