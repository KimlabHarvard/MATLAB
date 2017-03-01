figure(3);
lockin=deviceDrivers.SRS830();
lockin.connect('1');
amplitudes=[1:.005:1.5];
a1=[];
a2=[];
for(a=amplitudes)
    lockin.sineAmp=a;
    pause(6);
    list=[];
    for(i=1:30)
        list(i)=lockin.R;
        pause(1);
    end
    a1=[a1 mean(list)];
    a2=[a2 a];
    plot(a2,a1);
end
lockin.disconnect;