%naming convention: Fridge_IndepVars___DepVars
function Francois_T___VNA(UniqueName, start_dir, tempWaitTime, tempWindow, tempRampRate, tempList)
    startTime = clock;
    FileName = strcat('Francois_T___VNA', datestr(startTime, 'yyyy-mm-dd_HH-MM-SS'),'_',UniqueName,'.mat');
    
    tempController=FrancoisLakeShore335();
    tempController.connect('12');
    tempController.rampRate1=tempRampRate;
    
    data=struct('time',[],'myClock',[],'temp',[],'vnaTrace',[],'tempList',[],'tempWaitTime',[],'tempRampRate',[],'tempWindow',[],'vnaPower_dBm',[],'vnaAvgFactor',[],'vnaFreqList',[]);
    
    VNA = deviceDrivers.AgilentE8363C();
    VNA.connect('140.247.189.204');
    VNA.trigger_source='immediate';
    
    vnaFreqList=VNA.getX;
    
    data.time=zeros(length(tempList))/0;
    data.myClock=zeros(length(tempList),6)/0;
    data.temp=zeros(length(tempList))/0;
    data.vnaTrace=zeros(length(tempList),length(vnaFreqList))/0;
    
    data.tempList=tempList;
    data.tempWaitTime=tempWaitTime;
    data.tempRampRate=tempRampRate;
    data.tempWindow=tempWindow;
    data.vnaPower_dBm=VNA.power;
    data.vnaAvgFactor=VNA.average_counts;
    data.freqList=vnaFreqList;
    
    figure(991);
    
    %iterate through temperature
    for i=1:length(tempList)
        setTemperature(tempList(i));
        
        myFitType=fittype('const*abs(2./((1+j*2*pi*f*L*j.*2*pi*f*C)+(j*2*pi*f*L)/50+50*j*2*pi*f*C+1))','dependent',{'y'},'independent',{'f'},'coefficients',{'L','C','const'});
        %myFitOptions=fitoptions('Method','NonlinearLeastSquare','StartPoint', [1e-6 0.5,e-12 1],'TolX',1e-18,'TolFun',1e-18);
        [myFit,gof,output]=fit(x,y',myFitType,'StartPoint', [.8e-6 0.5e-12 1],'Robust','LAR','TolX',1e-15,'DiffMinChange',1e-10,'MaxIter',3000);
        plot(myFit,x,y);
        
        data.time(i)=etime(clock,startTime);
        data.myClock(i,:)=clock;
        data.temp(i)=tempController.temperatureA;
        data.vnaTrace(i,:)=VNA.getSingleTrace;
        
        save(fullfile(start_dir, FileName),'data');
        
        change_to_figure(991);
        hold on;
        plot(vnaFreqList,abs(data.vnaTrace(i,:)),'.-');
        xlabel('f (Hz)');
        ylabel('|S21|');
        
        
        %take VNA measurements/averages
        
    end
    
    %set temperature and wait for thermal stabilitzation
    function setTemperature(finalTemp)
        keeplooping=true;%can pause program and set this to true if needed
        startingTemp=tempController.temperatureA;
        tempController.setPoint1=finalTemp; 
        count=0;
        if(finalTemp>startingTemp)%we are warming
            fprintf('warming to %f K\n', finalTemp)
            while(keeplooping && tempController.temperatureA<finalTemp-tempWindow)
                if(mod(count,10)==0)
                    fprintf('current temp is %f K\n', tempController.temperatureA);
                end
                count=count+1;
                pause(1);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        else%we are cooling
            fprintf('cooling to %f K\n', finalTemp)
            while(keeplooping && tempController.temperatureA>finalTemp+tempWindow)
                if(mod(count,10)==0)
                    fprintf('current temp is %f K\n', tempController.temperatureA);
                end
                count=count+1;
                pause(1);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        end
        %if(i>1)
            pause(tempWaitTime);
        %end
    end
end

