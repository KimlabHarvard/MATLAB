Tmin=100;
Tmax=110;
Tstep=1;
Rmin=800;
Rstep=100;
Rmax=5000;

numResPts=1000; %1k points or so is good

lowerExtrapolationFactor=.8;
upperExtrapolationFactor=.8;

lowerExtrapolationFactorForFit=.2;
upperExtrapolationFactorForFit=.5;

trimmedResistance=calData.resistance(tempFitIndices,:); %the needed data

figure(10); %nicely colored surface of noise vs R and T that is extrapolated and then interpolated
clf; hold on; grid on;
clear fittedJohnsonNoise fittedResistance fittedTempsMat
fittedJohnsonNoise=zeros(length(tempFitIndices),numResPts);
fittedResistance=zeros(length(tempFitIndices),numResPts);
for(p=1:length(tempFitIndices))
    rrr5=trimmedResistance(p,:);
    myMin=min(rrr5);
    myMax=max(rrr5);
    range=myMax-myMin;
    rlinspace=linspace(myMin-lowerExtrapolationFactor*range,myMax+upperExtrapolationFactor*range,numResPts);
    fittedResistance(p,:)=rlinspace';
    fittedJohnsonNoise(p,:)=polyval(myPolyFit(p,:),rlinspace-rctr);
end
for(p=1:numResPts)
    fittedTempsMat(:,p)=trimmedTemps;
end
X2=fittedTempsMat(:);
Y2=fittedResistance(:);
Z2=fittedJohnsonNoise(:);

[xi2, yi2]=meshgrid(Tmin:Tstep:Tmax, Rmin:Rstep:Rmax);
zi2=griddata(X2,Y2,Z2,xi2,yi2,'cubic');
surf(xi2,yi2,zi2)
xlabel('T(K)')
ylabel('R(Ohms)')
zlabel('John Son Noise Power (W)')
title('Calibration with some fitting and extrapolation')

% figure(11);
% clf;
% hold on;
% [n m]=size(xi2);
% legendList=cell(n,1);
% for(p=n:-1:1)
%     plot(xi2(p,:),zi2(p,:),'o-','MarkerSize',4);
%     legendList(n-p+1)={sprintf('%g Ohms',yi2(p,1))};
% end
% legend(legendList);
% xlabel('T(K)');
% ylabel('Johnson Noise Power (W)');
% title('Interpolated Johnson Noise on a grid vs R and T, 8/8-9/16')
% grid on;
% drawnow;

figure(12); %plot grid points of the isotherm curves that were fitted to johnson noise power vs R
clf; hold on; grid on;
resistanceGridList=Rmin:Rstep:Rmax;
tempGridList=Tmin:Tstep:Tmax;
measuredTempList=calData.tempList(tempFitIndices);
sortedMeasuredTempList=sort(measuredTempList);
T_List_array=cell(length(resistanceGridList),1);
P_List_array=cell(length(resistanceGridList),1);
R_List=[];
countss=0;
%for each resistance, plot the T-points that are measured/fitted and those that aren't extrapolated too far
for(j=1:length(resistanceGridList)) 
   T_List=[];
   P_List=[];
   %
   for(i=1:length(tempGridList))
       %only if the temp grid point falls within the measured temp range
       if(tempGridList(i)>=sortedMeasuredTempList(1) && tempGridList(i)<=sortedMeasuredTempList(end))
           %find the two indices between which tempGridList(i) sits, or one index if its in the list
           sammy=find(sortedMeasuredTempList==tempGridList(i),1);
           if(~isempty(sammy)) %if its in the list
               pow67=polyval(myPolyFit(sammy,:),resistanceGridList(j)-rctr);
               minR=min(calData.resistance(sammy,:));
               maxR=max(calData.resistance(sammy,:));
           else %if its not, interpolate between the fitted functions/polynomials
               %find index of nearest temp above tempGridList(i), and store into sammy2
               sammy2=1;
               while(sortedMeasuredTempList(sammy2)<tempGridList(i))
                   sammy2=sammy2+1;
               end
               d1=sortedMeasuredTempList(sammy2)-tempGridList(i);
               d2=tempGridList(i)-sortedMeasuredTempList(sammy2-1);
               %interpolate the polynomial fits by like the center of mass or the fractional lever rule
               pow67=(d1*polyval(myPolyFit(sammy2-1,:),resistanceGridList(j)-rctr)+d2*polyval(myPolyFit(sammy2,:),resistanceGridList(j)-rctr))/(d1+d2);
               minR=(min(calData.resistance(sammy2,:))+min(calData.resistance(sammy2-1,:)))/2;
               maxR=(max(calData.resistance(sammy2,:))+max(calData.resistance(sammy2-1,:)))/2;
            end
            rangeR67=maxR-minR;
            if(resistanceGridList(j)>minR-lowerExtrapolationFactorForFit*range && resistanceGridList(j)<maxR+upperExtrapolationFactorForFit*range)
                tem67=tempGridList(i);
                T_List=[T_List tem67];
                P_List=[P_List pow67];
                countss=countss+1;
            end
       end
   end
   if(~isempty(P_List))
       R_List=[R_List resistanceGridList(j)];
   end
   plot(T_List,P_List);
   T_List_array{j}=T_List;
   P_List_array{j}=P_List;
end
lennn=length(R_List)
legendList=cell(lennn,1);
for(p=lennn:-1:1)
     legendList(lennn-p+1)={sprintf('%g Ohms',R_List(p))};
end

clear myNoiseTemp myGain myRes
%fit linear lines to the data
figure(13)
clf; hold on; grid on;
for(p=length(resistanceGridList):-1:1)
    xfit=T_List_array{p};
    yfit=P_List_array{p};
    plot(xfit,yfit,'o-','MarkerSize',3)
end
for(p=length(R_List):-1:1)
    xfit=T_List_array{p};
    yfit=P_List_array{p};
    xfit(isnan(yfit))=[];
    yfit(isnan(yfit))=[];
    try %in case it tries to fit to one point
        fitObject=fit(xfit',yfit','poly1');
        plot(fitObject);
        myNoiseTemp(p)=fitObject.p2./fitObject.p1;
        myGain(p)=fitObject.p1;
        %myRes(p)=yi2(p,1);
        myRes(p)=R_List(p);
    catch
        myNoiseTemp(p)=NaN;
        myGain(p)=NaN;
        myRes(p)=NaN;
    end
    %plot(fitObject);
    p
end
legend(legendList);
xlabel('T(K)');
ylabel('Johnson Noise Power (W)');
title('Constant R fits to Johnson Noise')



figure(14);
clf;
yyaxis left;
plot(myRes,myGain)
ylabel('gain (W/K)')
yyaxis right;
plot(myRes,myNoiseTemp);
ylabel('T noise(K)');
grid on;
xlabel('R(Ohms)')
title('Gain and Noise T')


% figure(1003);
% yyaxis left;
% plot(myRes,smooth(myGain,51))
% ylabel('gain (W/K)')
% yyaxis right;
% plot(myRes,smooth(myNoiseTemp,51));
% ylabel('T noise(K)');
% grid on;

gainData=struct('gain',[],'noiseTemperature',[],'resistance',[]);
myRes=myRes(~isnan(myRes));
myGain=myGain(~isnan(myGain));
myNoiseTemp=myNoiseTemp(~isnan(myNoiseTemp));
gainData.resistance=myRes;
gainData.gain=myGain;
gainData.noiseTemperature=myNoiseTemp;

return;

dlgTitle    = 'User Question';
dlgQuestion = 'Do you wish to save this gain data?';
choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
if(strcmp(choice,'Yes'))
    UniqueName = input('Enter uniquie file identifier: ','s');
    start_dir = 'C:\GitHub\Matlab\data\';
    start_dir = uigetdir(start_dir);
    StartTime=clock;
    FileName = strcat('CalculatedGain_', datestr(StartTime, 'yyyymmdd_HHMMSS'),'_',UniqueName,'.mat');
    save(fullfile(start_dir, FileName),'gainData')
end


