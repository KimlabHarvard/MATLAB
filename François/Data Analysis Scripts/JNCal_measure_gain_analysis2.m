%go through the gain calibration file, created by JN_cal_measure_gain program
%which is a file that sweeps temp and gate voltage (i and j indices) at zero bias / minimal bias to measure R
%calculate the slope (which is the gain) by fitting a linear line (in future possibly quadratic)
%the point of the gain will be the midpoint of the line; this does create some edge effect problems however

numPointsAvg=20; %how many points to have in the running linear fit


%transfer stuff from the datafile
tempList=calData.tempList;
resistance=calData.resistance;
johnsonNoise=calData.johnsonNoise;
gateVoltageList=calData.gateVoltageList;

showTempFit=0;

numTemps=length(tempList);
slopeTempIndices=1:(length(tempList)-numPointsAvg+1);

k_B=1.38064852e-23;
e=1.60217662e-19;

hold off;

gainFit=zeros(length(slopeTempIndices)-1,length(gateVoltageList));
tempFit=gainFit;
resistanceFit=gainFit;
nosieTempFit=gainFit;
for(j=1:length(gateVoltageList))
    for(i=1:length(slopeTempIndices)-1)
        xData=tempList(i:i+numPointsAvg)';
        yData=johnsonNoise(i:i+numPointsAvg,j);
        myFit=fit(xData,yData,'poly1');
        gainFit(i,j)=myFit.p1/(4*k_B);
        tempFit(i,j)=geomean(xData');
        noiseTempFit(i,j)=myFit.p2/myFit.p1;
        resistanceFit(i,j)=geomean(resistance(i:i+numPointsAvg,j));
        if(showTempFit)
            plot(myFit,xData,yData);
            dlgTitle    = 'User Question';
            dlgQuestion = 'Do you wish to continue?';
            choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
            if(strcmp(choice,'No'))
                return;
            end
        end
    end
end



figure(1);
clf;
subplot(2,2,1);
plot(tempList,johnsonNoise(:,:),'.-','Color',[.85 .85 .85])
hold on;
plot(tempList,johnsonNoise(:,1:4:end)','.-')
xlabel('T(K)');
ylabel('Johnson Noise P_P0 (W)');
title('graphene 8/13/16 all gates');
hold off;

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
%figure(3);
plot(gateVoltageList,resistance,'.-');
xlabel('gate voltage (V)');
ylabel('resistance (Ohms)');
title('graphene 8/13/16 all gates');

subplot(2,2,4);
%figure(4)
surf(tempList,gateVoltageList,resistance','EdgeAlpha',0);
xlabel('T(K)');
ylabel('gate voltage (V)');
colormap('hot');
colorbar();
view([0 0 1]);
shading interp;
title('Resistance (Ohms)');

figure(2);
clf;
subplot(2,2,1);
plot(tempFit,gainFit,'.-');
xlabel('T(K)');
ylabel('Gain G*\Delta f (Hz)');
%ylim([-0.5e-10,2e-10]);
grid on;
title(sprintf('moving %g-point linear fit slope gain to JN Calibration',numPointsAvg))

subplot(2,2,3);
size(tempFit(:,1))
size(gateVoltageList)
size(gainFit)
surf(tempFit(:,1)',gateVoltageList,gainFit','EdgeAlpha',0);
colormap('hot');
colorbar();
view([0 0 1])
shading interp;
xlabel('T(K)');
ylabel('gate voltage (V)');
title(sprintf('moving %g-point linear fit slope Gain G*Delta f (Hz)',numPointsAvg))





figure(3);
clf;
subplot(2,2,1);
hold off;
sam=1;
    plot(resistanceFit(sam,:),noiseTempFit(sam,:),'.-')
xlabel('R (ohms)')
tempFit(sam,:)
ylabel('Noise Temp (K)');
%ylim([-0.5e-10,2e-10]);
grid on;
title(sprintf('moving %g-point linear fit noise temop',numPointsAvg))


subplot(2,2,2);
grid on;
hold on;
for(sam=1:numPointsAvg/2:length(tempFit))
    plot(resistanceFit(sam,:),gainFit(sam,:),'.-')
end
xlabel('R (ohms)')
ylabel('Gain G*\Delta f (Hz)');
title(sprintf('gain trace over the dirac peak sweeping V_g, at various temps'));

subplot(2,2,4);
grid on;
hold on;
for(sam=1:5:length(tempList))
    plot(resistance(sam,:),johnsonNoise(sam,:),'.-')
end
xlabel('R (ohms)')
ylabel('Johnson Noise (W)');
title(sprintf('JN trace over the dirac peak sweeping V_g, at various temps'));
