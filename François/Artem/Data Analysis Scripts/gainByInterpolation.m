%X=; %X is the m x n temperature matrix as a vector
%Y=; %Y is the m x n resistance matrix as a vector
%Z=; %Z is the m x n johnson noise matrix as a vector
%this makes a 3D scatter plot

Tmin=10;
Tmax=70;
Tstep=1;
Rmin=1200;
Rstep=10;
Rmax=3200;

[xi, yi]=meshgrid(Tmin:Tstep:Tmax, Rmin:Rstep:Rmax);
zi=griddata(X,Y,Z,xi,yi);
figure(5);
surf(xi,yi,zi);

figure(1001);
clf;
hold on;
[n m]=size(xi);
legendList=cell(n,1);
for(p=n:-1:1)
    plot(xi(p,:),zi(p,:),'o-','MarkerSize',4);
    legendList(n-p+1)={sprintf('%g Ohms',yi(p,1))};
end
legend(legendList);
xlabel('T(K)');
ylabel('Johnson Noise Power (W)');
title('Interpolated Johnson Noise on a grid vs R and T, 8/8-9/16')
grid on;
drawnow;

clear myNoiseTemp myGain myRes

%fit linear lines to the data
for(p=n:-1:1)
    xfit=xi(p,:);
    yfit=zi(p,:);
    xfit(isnan(yfit))=[];
    yfit(isnan(yfit))=[];
    fitObject=fit(xfit',yfit','poly1');
    myNoiseTemp(p)=fitObject.p2./fitObject.p1;
    myGain(p)=fitObject.p1;
    myRes(p)=yi(p,1);
    %plot(fitObject);
    p
end
figure(1002);
yyaxis left;
plot(myRes,myGain)
ylabel('gain (W/K)')
yyaxis right;
plot(myRes,myNoiseTemp);
ylabel('T noise(K)');
grid on;

figure(1003);
yyaxis left;
plot(myRes,smooth(myGain,51))
ylabel('gain (W/K)')
yyaxis right;
plot(myRes,smooth(myNoiseTemp,51));
ylabel('T noise(K)');
grid on;

gainData=struct('gain',[],'noiseTemperature',[],'resistance',[]);
gainData.resistance=myRes;
gainData.gain=myGain;
gainData.noiseTemperature=myNoiseTemp;
gainData.smoothGain=smooth(myGain,51);
gainData.smoothNoiseTemperature=smooth(myNoiseTemp,51);


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


