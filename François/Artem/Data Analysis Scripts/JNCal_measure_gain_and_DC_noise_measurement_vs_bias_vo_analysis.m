%load the calibration data as calData
%load the fano factor data as fanoData

%list of temperatures to use for calibration data
calTempList=[100 105 110];

%list of gate voltage to use for calibration data; skip over other gate voltages
calGateVoltageList=fanoData.gateVoltageList;

%the temp at which to calculate the fano factor
fanoTemp=105;

fanoBias='negative'; %'positive' or 'negative' for positive or negative bias
fitType='coth'; %'coth' or 'linear'
showFanoFit=1;
showTempFit=0;

fitTemp=false;

%use for linear fit
startBiasVoltage=0.017; %the lower cutoff bias voltage; fit the slope above this point to get the fano factor
endBiasVoltage=0.04;

%use for coth fit, in units of eV/(kT)
cothMaxVoltage=11;

gateVoltageErr=1e-5;

calGateVoltageIndices=[];
calTempIndices=[];

myfig1=figure(1); hold off;
myfig1.OuterPosition=[80 200 700 700];
legend off;

%go through the calData.gateVoltageList and find the indices for our wanted calGateVoltageList
%calGateVoltageIndices=(0*calGateVoltageList)/0;
count=1;
for(i=1:length(calGateVoltageList))
    for(ii=1:length(calData.gateVoltageList))
        %if(calData.gateVoltageList(ii)<calGateVoltageList(i)+gateVoltageErr && calData.gateVoltageList(ii)>calGateVoltageList(i)-gateVoltageErr)
        if(abs(calData.gateVoltageList(ii)-calGateVoltageList(i))<gateVoltageErr)
            calGateVoltageIndices(count)=i;
            count=count+1;
        end
    end
end

%go through the calData.tempList and find the indices for our wanted calTempList
%calTempIndices=(0*calTempList)/0;
count=1;
for(i=1:length(calTempList))
    for(ii=1:length(calData.tempList))
        if(calData.tempList(ii)==calTempList(i))
            calTempIndices(count)=i;
            count=count+1;
        end
    end
end

%find the fanoTempIndex in the fano factor data
fanoTempIndex=-1;
for(i=1:length(fanoData.tempList))
    if(fanoData.tempList(i)==fanoTemp)
        fanoTempIndex=i;
        break
    end
end
if(fanoTempIndex==-1)
    error('unable to find the desired temperature in the fano factor datafile');
end


k_B=1.38064852e-23;
e=1.60217662e-19;

if(length(calTempIndices)~=length(calTempList))
    error('unable to find all the temps in calTempList');
end

if(length(calGateVoltageIndices)~=length(calGateVoltageList))
    error('unable to find all the gate voltages in calGateVoltageList');
end

%if(calData.gateVoltageList~=fanoData.gateVoltageList)
%    error('inconsistent gate voltages between calibration data and fano factor data');
%end


%do linear fits to the temp data in calTempList for each gateVoltage j
gain=zeros(1,length(calGateVoltageIndices))/0;
for(j=1:length(calGateVoltageIndices))
    yData=calData.johnsonNoise(calTempIndices,calGateVoltageIndices(j));
    xData=calTempList';
    myFit=fit(xData,yData,'poly1');
    gain(j)=myFit.p1/(4*k_B);
    if(showTempFit)
        plot(myFit,xData,yData);
        legend off;
        dlgTitle    = 'User Question';
        dlgQuestion = 'Do you wish to continue?';
        choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
        if(strcmp(choice,'No'))
            return;
        end
    end
end
%close all;

%at the desired fanoTemp, go through the data and determine the slope d_P/d_V_bias for each gate voltage
%this is tricky because we want the asymptotic slope, so we must take the slope at the high currents only

%figure(1);
startIndex=-1;
endIndex=-1;
fanoFactor=[];
fanoFactorErr=[];

if(strcmp(fitType,'linear'))
    if(strcmp(fanoBias,'positive'))
        for(k=1:length(fanoData.biasVoltageList))
            if(fanoData.biasVoltageList(k)>abs(startBiasVoltage))
                startIndex=k;
                break;
            end
        end
        if(startIndex==-1)
            error('unable to find bias voltages higher than the given startBiasVoltage');
        end
        for(k=1:length(fanoData.biasVoltageList))
            if(fanoData.biasVoltageList(k)>abs(endBiasVoltage))
                endIndex=k-1;
                break;
            end
        end
        if(endIndex==-1)
            error('unable to find bias voltages higher than the given startBiasVoltage');
        end


        %for every gate voltage do the linear fit in the higher bias voltage regime above %startIndex
        for (j=1:length(calGateVoltageIndices))
            xData=squeeze(fanoData.biasVoltage(fanoTempIndex,j,startIndex:endIndex));
            yData=squeeze(fanoData.power(fanoTempIndex,j,startIndex:endIndex));
            if(max(isnan(xData))==1)
                xData=1:length(xData);
                xData=xData';
            end
            if(max(isnan(yData))==1)
                yData=zeros(1,length(yData))';
            end
            myFit=fit(xData,yData,'poly1');
            fanoFactor(j)=myFit.p1/(2*e*gain(j));
            try
                conf=confint(myFit,0.6827);
                conf=conf(:,1)';
            catch
                conf=zeros(65,1);
            end
            fanoFactorErr(j)=(conf(2)-conf(1))/(2*2*e*gain(j));
            if(showFanoFit)
                plot(myFit,xData,yData);
                xlabel('bias voltage (V)');
                ylabel('power (W)');
                title(sprintf('linear fit for fano factor at gate voltage of %g',calData.gateVoltageList(calGateVoltageIndices(j))));
                dlgTitle    = 'User Question';
                dlgQuestion = 'Do you wish to continue?';
                choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
                if(strcmp(choice,'No'))
                    return;
                end
            end
        end
    elseif(strcmp(fanoBias,'negative'))
        for(k=1:length(fanoData.biasVoltageList))
            if(fanoData.biasVoltageList(k)>-1*abs(endBiasVoltage))
                startIndex=k;
                break;
            end
        end
        if(startIndex==-1)
            error('unable to find bias voltages higher than the given startBiasVoltage');
        end
        for(k=1:length(fanoData.biasVoltageList))
            if(fanoData.biasVoltageList(k)>-1*abs(startBiasVoltage) )
                endIndex=k-1;
                break;
            end
        end
        if(endIndex==-1)
            error('unable to find bias voltages higher than the given startBiasVoltage');
        end

        for (j=1:length(calGateVoltageIndices))
            xData=squeeze(fanoData.biasVoltage(fanoTempIndex,j,startIndex:endIndex));
            yData=squeeze(fanoData.power(fanoTempIndex,j,startIndex:endIndex));
            if(max(isnan(xData))==1)
                xData=1:length(xData);
                xData=xData';
            end
            if(max(isnan(yData))==1)
                yData=zeros(1,length(yData))';
            end
            myFit=fit(xData,yData,'poly1');
            fanoFactor(j)=-myFit.p1/(2*e*gain(j));
            try
                conf=confint(myFit,0.6827);
                conf=conf(:,1)';
            catch
                conf=zeros(65,1);
            end
            fanoFactorErr(j)=(conf(2)-conf(1))/(2*2*e*gain(j));
            if(showFanoFit)
                plot(myFit,xData,yData);
                xlabel('bias voltage (V)');
                ylabel('power (W)');
                title(sprintf('linear fit for fano factor at gate voltage of %g',calData.gateVoltageList(calGateVoltageIndices(j))));
                dlgTitle    = 'User Question';
                dlgQuestion = 'Do you wish to continue?';
                choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
                if(strcmp(choice,'No'))
                    return;
                end
            end
        end
    else
        error('incorrect fanoBias');
    end
    figure(1);
    clf;
    hold on;
    size(fanoData.gateVoltageList)
    size(fanoFactor)
    size(fanoFactorErr)
    errorbar(fanoData.gateVoltageList,fanoFactor,fanoFactorErr);
    plot(fanoData.gateVoltageList,fanoFactor,'linewidth',2);
    xlabel('gate voltage (V)');
    ylabel('Fano Factor (unitless)');
    title(['Fano Factor using zeroth order gain ' sprintf('at %g K, ',fanoTemp) fanoBias ' bias voltage, fitted to bias voltages between ' sprintf('%g V',startBiasVoltage) ' and ' sprintf('%g V',endBiasVoltage)]);
    grid on;
elseif(strcmp(fitType,'coth'))
    myVoltage=abs(cothMaxVoltage)*k_B*fanoTemp/e;
    for(k=1:length(fanoData.biasVoltageList))
        if(fanoData.biasVoltageList(k)>-abs(myVoltage))
            startIndex=k;
            break;
        end
    end
    if(startIndex==-1)
        error('unable to find bias voltages lower than the given cothMaxVoltage');
    end
    for(k=1:length(fanoData.biasVoltageList))
        if(fanoData.biasVoltageList(k)>abs(myVoltage))
            endIndex=k-1;
            break;
        end
    end
    if(endIndex==-1)
        error('unable to find bias voltages higher than the given cothMaxVoltage');
    end
    %for every gate voltage do the linear fit in the higher bias voltage regime above %startIndex
    for (j=1:length(calGateVoltageIndices))
        xData=squeeze(fanoData.biasVoltage(fanoTempIndex,j,startIndex:endIndex));
        yData=squeeze(fanoData.power(fanoTempIndex,j,startIndex:endIndex));
        if(max(isnan(xData))==1)
            xData=1:length(xData);
            xData=xData';
        end
        if(max(isnan(yData))==1)
            yData=zeros(1,length(yData))';
        end
        %yData=yData/gain(j);
        k_B=1.38064852e-23;
        e=1.60217662e-19;
        yData=yData*10000000000;
        if(fitTemp)
            
            myFitType=fittype(sprintf('10000000000*%e*(2*%.9e*V*F*(coth(%.9e*V/(2*%.9e*T)))+4*%.9e*T*(1-F))+C',gain(j),e,e,k_B,k_B),'dependent',{'y'},'independent',{'V'},'coefficients',{'F','C','T'});
            %myFitType=fittype('C+T*V+F*V*V','dependent',{'y'},'independent',{'V'},'coefficients',{'F','C','T'});
            myFitOptions=fitoptions('Method','NonlinearLeastSquares','MaxFunEvals',1200,'StartPoint', [1 0 fanoTemp],'TolX',1e-20,'TolFun',1e-20,'Robust','LAR');
            [myFit,gof,output]=fit(xData,yData,myFitType,myFitOptions);
            dlgQuestion = sprintf('Results of fit:\nT= %g\nF=%g\nC=%g\nDo you wish to continue?',myFit.T,myFit.F,myFit.C);
            output.iterations
        else
            myFitType=fittype(sprintf('10000000000*%e*(2*%.9e*V*F*(coth(%.9e*V/(2*%.9e*%e)))+4*%.9e*%e*(1-F))+C',gain(j),e,e,k_B,fanoTemp,k_B,fanoTemp),'dependent',{'y'},'independent',{'V'},'coefficients',{'F','C'});
            myFitOptions=fitoptions('Method','NonlinearLeastSquares','MaxFunEvals',1200,'StartPoint', [1 0],'TolX',1e-20,'TolFun',1e-20,'Robust','LAR');
            [myFit,gof,output]=fit(xData,yData,myFitType,myFitOptions);
            dlgQuestion = sprintf('Results of fit:F=%g\nC=%g\nDo you wish to continue?',myFit.F,myFit.C);
            output.iterations
        end
        
        fanoFactor(j)=myFit.F;
        try
            conf=confint(myFit,0.6827);
            conf=conf(:,1)';
        catch
            conf=zeros(65,1);
        end
        fanoFactorErr(j)=(conf(2)-conf(1))/2;
        if(showFanoFit)
            plot(myFit,xData,yData);
            xlabel('bias voltage (V)');
            ylabel('power (W)');
            title(sprintf('coth fit for fano factor at gate voltage of %g V and temp of %G K',calGateVoltageList(j),fanoTemp));
            dlgTitle    = 'User Question';
            choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
            if(strcmp(choice,'No'))
                return;
            end
        end
    end
    
    figure(1);
    clf;
    hold on;
    errorbar(fanoData.gateVoltageList,fanoFactor,fanoFactorErr);
    plot(fanoData.gateVoltageList,fanoFactor,'linewidth',2);
    xlabel('gate voltage (V)');
    ylabel('Fano Factor (unitless)');
    title(['Fano Factor using zeroth order gain ' sprintf('at %g K, ',fanoTemp) fanoBias ' bias voltage, fitted to bias voltages between ' sprintf('%g V',-myVoltage) ' and ' sprintf('%g V',myVoltage)]);
    grid on;
    
end



    

