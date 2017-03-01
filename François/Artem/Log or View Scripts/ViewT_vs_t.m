tc=FrancoisLakeShore335();
tc.connect('12');

clear t;
clear T;
startTime=clock;
count=1;
while(etime(clock,startTime)<10)
    t(count)=etime(clock,startTime);
    T(count)=tc.temperatureA;
    plot(t,T);
    pause(0.05);
    count=count+1;
end

tc.disconnect