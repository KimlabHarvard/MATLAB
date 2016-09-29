f=[10:10:200 210:10:1000];
clear r;
clear theta;

lockin=deviceDrivers.SRS830();
lockin.connect('1');

for(k=1:length(f))
    if(f(k)==10)
        timeConst=.3;
        lockin.timeConstant=timeConst;
    end
    if(f(k)==40)
        timeConst=0.1;
        lockin.timeConstant=timeConst;
    end
    lockin.sineFreq=f(k);
    pause(6*timeConst);
    r(k)=lockin.R;
    theta(k)=lockin.theta;
    plot(f(1:k),theta);
end

xlabel('f(Hz)')
ylabel('theta (deg)');
yyaxis right
plot(f,r)
title('R, theta vs. freq with line and 2x line filter')
yyaxis left
grid on